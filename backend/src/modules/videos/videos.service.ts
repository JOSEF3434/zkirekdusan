// src/modules/videos/videos.service.ts
import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { PrismaService } from '../../prisma/prisma.service.js';
import { VideosRepository } from './videos.repository.js';
import { UploadVideoDto } from './dto/upload-video.dto.js';
import { UpdateVideoDto } from './dto/update-video.dto.js';
import { VideoStatus, VideoVisibility, GroupRole } from '@prisma/client';
import { AppRole } from '../../common/constants/roles.js';
import { v4 as uuidv4 } from 'uuid';
import { VIDEO_PROCESSING_QUEUE } from '../video-processing/video-processing.processor.js';
import type { IStorageProvider } from '../uploads/providers/storage.interface.js';
import { STORAGE_PROVIDER_TOKEN } from '../uploads/providers/storage.factory.js';
import { CloudinaryStorageProvider } from '../uploads/providers/cloudinary.provider.js';

@Injectable()
export class VideosService {
  private readonly logger = new Logger(VideosService.name);

  constructor(
    private readonly repo: VideosRepository,
    private readonly prisma: PrismaService,
    @InjectQueue(VIDEO_PROCESSING_QUEUE) private readonly videoQueue: Queue,
    @Inject(STORAGE_PROVIDER_TOKEN)
    private readonly storageProvider: IStorageProvider & Record<string, any>,
  ) {}

  private generateSlug(title: string): string {
    const base = title
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .substring(0, 80);
    return `${base}-${uuidv4().substring(0, 8)}`;
  }

  private async verifyChannelUploadPermission(
    videoChannelId: string,
    userId: string,
  ): Promise<{ groupId: string; channelId: string }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { role: true },
    });
    if (!user) throw new NotFoundException('User not found');

    // SUPER_ADMIN bypasses all checks
    if (
      (user.role.name as AppRole) === AppRole.SUPER_ADMIN ||
      (user.role.name as AppRole) === AppRole.ADMIN
    ) {
      const channel = await this.prisma.videoChannel.findUnique({
        where: { id: videoChannelId, deletedAt: null },
        select: { id: true, groupId: true },
      });
      if (!channel) throw new NotFoundException('Video channel not found');
      return { groupId: channel.groupId, channelId: channel.id };
    }

    const channel = await this.prisma.videoChannel.findFirst({
      where: {
        OR: [
          { id: videoChannelId },
          { groupId: videoChannelId },
        ],
        deletedAt: null,
      },
      select: {
        id: true,
        groupId: true,
        uploadPermission: true,
        group: { select: { id: true, status: true, createdById: true } },
      },
    });

    if (!channel) throw new NotFoundException('Video channel not found');
    if (channel.group.status === 'PENDING_APPROVAL') {
      throw new ForbiddenException(
        'Group is not privileged to upload videos. Please communicate with system admin to approve your groups.',
      );
    }
    if (channel.group.status !== 'ACTIVE') {
      throw new ForbiddenException('Group is not active');
    }

    const isCreator = channel.group.createdById === userId;

    const membership = await this.prisma.groupMember.findFirst({
      where: {
        groupId: channel.groupId,
        userId,
        removedAt: null,
      },
      select: { role: true },
    });

    if (!membership && !isCreator) {
      throw new ForbiddenException('You are not a member of this group');
    }

    const roleHierarchy: Record<string, number> = {
      GROUP_ADMIN: 4,
      MODERATOR: 3,
      MEMBER: 2,
      GUEST: 1,
    };

    const userLevel = isCreator
      ? 4
      : (roleHierarchy[membership?.role ?? ''] ?? 0);
    const requiredLevel = roleHierarchy[channel.uploadPermission] ?? 2;

    if (userLevel < requiredLevel) {
      throw new ForbiddenException(
        `Upload requires at least ${channel.uploadPermission} role in this channel`,
      );
    }

    return { groupId: channel.groupId, channelId: channel.id };
  }

  /**
   * Phase 1 of video upload: Create the video record and return ID.
   * The actual file is uploaded separately via the uploads endpoint.
   */
  async initiateUpload(
    videoChannelId: string,
    userId: string,
    dto: UploadVideoDto,
  ) {
    const permission = await this.verifyChannelUploadPermission(videoChannelId, userId);
    const resolvedChannelId = permission.channelId;

    const slug = this.generateSlug(dto.title);

    const video = await this.repo.create({
      videoChannelId: resolvedChannelId,
      uploadedById: userId,
      title: dto.title,
      slug,
      description: dto.description,
      visibility: dto.visibility,
      categories: dto.categories,
      tags: dto.tags,
      hashtags: dto.hashtags,
      seoTitle: dto.seoTitle,
      seoDescription: dto.seoDescription,
      downloadPermission: dto.downloadPermission,
      isDownloadable: dto.isDownloadable,
    });

    return this.mapVideoToDto(video);
  }

  /**
   * Called after the source file has been uploaded.
   * Associates the file with the video and queues processing.
   */
  async attachSourceFile(videoId: string, fileId: string, userId: string) {
    const video = await this.repo.findById(videoId);
    if (!video) throw new NotFoundException('Video not found');

    if (video.uploadedById !== userId) {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        include: { role: true },
      });
      if (
        !user ||
        ((user.role.name as AppRole) !== AppRole.SUPER_ADMIN &&
          (user.role.name as AppRole) !== AppRole.ADMIN)
      ) {
        throw new ForbiddenException(
          'Only the video uploader can attach files',
        );
      }
    }

    if (video.status !== VideoStatus.UPLOADING) {
      throw new BadRequestException('Video is not in UPLOADING state');
    }

    // 1. Update DB — sets status → QUEUED and links source file
    const updated = await this.repo.setSourceFile(videoId, fileId);

    // 2. Resolve source file from DB
    const fileRecord = await this.prisma.file.findUnique({
      where: { id: fileId },
      select: { storageKey: true, url: true },
    });
    const sourceFilePath = fileRecord?.storageKey ?? `videos/${videoId}/raw.mp4`;

    // 3. Build the best playback URL immediately so Flutter can play the video
    //    without waiting for background processing to complete.
    if (fileRecord?.url) {
      let immediateHlsUrl = fileRecord.url;

      // ── Cloudinary: build native streaming URL right away ─────────────
      if (this.storageProvider.providerType === 'CLOUDINARY') {
        const cloudinaryProvider = this.storageProvider as CloudinaryStorageProvider;
        const publicId = fileRecord.storageKey;

        if (publicId) {
          // Use direct optimized MP4 URL for guaranteed instant playback on all devices
          immediateHlsUrl =
            cloudinaryProvider.getVideoDirectUrl(publicId) || fileRecord.url;
          this.logger.log(
            `[Cloudinary] Video [${videoId}] immediate streaming URL: ${immediateHlsUrl}`,
          );
        }
      }

      await this.prisma.video.update({
        where: { id: videoId },
        data: {
          status: VideoStatus.READY,
          hlsUrl: immediateHlsUrl,
          publishedAt: new Date(),
        },
      });
      this.logger.log(
        `Video [${videoId}] marked READY immediately. hlsUrl: ${immediateHlsUrl}`,
      );
    }

    // 4. Enqueue background processing job:
    //    - For Cloudinary: builds rendition records from Cloudinary on-demand URLs
    //    - For Local: runs FFmpeg HLS transcoding
    try {
      await this.videoQueue.add(
        'transcode',
        { videoId, sourceFilePath, storageKey: sourceFilePath },
        {
          attempts: 3,
          backoff: { type: 'exponential', delay: 5000 },
          removeOnComplete: 100,
          removeOnFail: 50,
        },
      );

      this.logger.log(
        `Video [${videoId}] queued for background processing (Cloudinary: rendition records; Local: HLS transcode)`,
      );
    } catch (queueErr) {
      this.logger.warn(
        `Failed to enqueue processing job for video [${videoId}] (Redis may be offline): ${queueErr}`,
      );
    }

    return this.mapVideoToDto(updated);
  }

  async findById(id: string, userId?: string) {
    const video = await this.repo.findById(id);
    if (!video) throw new NotFoundException('Video not found');

    // Increment view count for READY public videos
    if (video.status === VideoStatus.READY && userId) {
      void this.repo.incrementViews(id);
    }

    return this.mapVideoToDto(video);
  }

  /** Returns the raw Prisma record without DTO mapping — used internally by controller */
  async findByIdRaw(id: string) {
    return this.repo.findById(id);
  }

  async setThumbnail(videoId: string, thumbnailUrl: string, userId: string) {
    const video = await this.repo.findById(videoId);
    if (!video) throw new NotFoundException('Video not found');

    const canEdit = await this.canModifyVideo(video, userId);
    if (!canEdit)
      throw new ForbiddenException('Insufficient permissions to set thumbnail');

    return this.mapVideoToDto(
      await this.repo.update(videoId, { thumbnailUrl }),
    );
  }

  async findBySlug(slug: string, userId?: string) {
    const video = await this.repo.findBySlug(slug);
    if (!video) throw new NotFoundException('Video not found');

    if (video.status === VideoStatus.READY && userId) {
      void this.repo.incrementViews(video.id);
    }

    return this.mapVideoToDto(video);
  }

  async findByChannel(
    videoChannelId: string,
    userId: string | undefined,
    opts: {
      page?: number;
      limit?: number;
      cursor?: string;
      status?: VideoStatus;
      search?: string;
    },
  ) {
    // For non-admins, restrict to READY + PUBLIC/GROUP_ONLY
    let isAdmin = false;
    if (userId) {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        include: { role: true },
      });
      isAdmin =
        user?.role.name === AppRole.SUPER_ADMIN ||
        user?.role.name === AppRole.ADMIN;
    }

    const result = await this.repo.findByChannel(videoChannelId, {
      ...opts,
      ...(isAdmin
        ? {}
        : {
            status: VideoStatus.READY,
            visibility: VideoVisibility.PUBLIC,
          }),
    });

    return {
      ...result,
      data: result.data.map((v) => this.mapVideoToDto(v)),
    };
  }

  async update(id: string, userId: string, dto: UpdateVideoDto) {
    const video = await this.repo.findById(id);
    if (!video) throw new NotFoundException('Video not found');

    const canEdit = await this.canModifyVideo(video, userId);
    if (!canEdit)
      throw new ForbiddenException(
        'Insufficient permissions to edit this video',
      );

    const data: Record<string, any> = { ...dto };
    if (dto.scheduledAt) {
      data.scheduledAt = new Date(dto.scheduledAt);
      data.visibility = VideoVisibility.SCHEDULED;
    }

    return this.mapVideoToDto(await this.repo.update(id, data));
  }

  async publish(id: string, userId: string) {
    const video = await this.repo.findById(id);
    if (!video) throw new NotFoundException('Video not found');
    if (video.status !== VideoStatus.READY) {
      throw new BadRequestException('Video must be READY before publishing');
    }
    const canEdit = await this.canModifyVideo(video, userId);
    if (!canEdit) throw new ForbiddenException('Insufficient permissions');

    return this.mapVideoToDto(
      await this.repo.update(id, {
        visibility: VideoVisibility.PUBLIC,
        publishedAt: new Date(),
      }),
    );
  }

  async delete(id: string, userId: string) {
    const video = await this.repo.findById(id);
    if (!video) throw new NotFoundException('Video not found');

    const canEdit = await this.canModifyVideo(video, userId);
    if (!canEdit)
      throw new ForbiddenException(
        'Insufficient permissions to delete this video',
      );

    await this.repo.softDelete(id);
    return { message: 'Video deleted successfully' };
  }

  async likeVideo(videoId: string, userId: string, isLike: boolean) {
    const video = await this.repo.findById(videoId);
    if (!video) throw new NotFoundException('Video not found');

    await this.repo.upsertLike(userId, videoId, isLike);
    await this.repo.updateLikeCounts(videoId);
    return {
      message: isLike ? 'Video liked' : 'Video disliked',
      videoId,
    };
  }

  async removeLike(videoId: string, userId: string) {
    const video = await this.repo.findById(videoId);
    if (!video) throw new NotFoundException('Video not found');

    await this.repo.removeLike(userId, videoId);
    await this.repo.updateLikeCounts(videoId);
    return { message: 'Reaction removed', videoId };
  }

  async getUserLikeStatus(videoId: string, userId: string) {
    const like = await this.repo.getUserLike(userId, videoId);
    return { liked: !!like && like.isLike, disliked: !!like && !like.isLike };
  }

  async updateWatchProgress(
    videoId: string,
    userId: string,
    watchedSeconds: number,
  ) {
    const video = await this.repo.findById(videoId);
    if (!video) throw new NotFoundException('Video not found');

    const duration = video.duration ?? 0;
    const watchedPercent =
      duration > 0 ? Math.min((watchedSeconds / duration) * 100, 100) : 0;
    const isCompleted = watchedPercent >= 90;

    return this.repo.upsertWatchProgress({
      userId,
      videoId,
      watchedSeconds,
      watchedPercent,
      isCompleted,
    });
  }

  async getWatchHistory(userId: string, page = 1, limit = 20) {
    const result = await this.repo.getWatchHistory(userId, page, limit);
    return {
      data: result.data.map((item) => ({
        ...item.video,
        watchedAt: (item as any).watchedAt,
        watchedSeconds: (item as any).watchedSeconds,
        watchedPercent: (item as any).watchedPercent,
      })),
      total: result.total,
      page,
      limit,
    };
  }

  async removeFromWatchHistory(videoId: string, userId: string) {
    await this.repo.removeFromWatchHistory(userId, videoId);
    return { message: 'Video removed from watch history', videoId };
  }

  async clearWatchHistory(userId: string) {
    await this.repo.clearWatchHistory(userId);
    return { message: 'Watch history cleared' };
  }

  async getLikedVideos(userId: string, page = 1, limit = 20) {
    return this.repo.getLikedVideos(userId, page, limit);
  }

  async getWatchProgress(videoId: string, userId: string) {
    return this.repo.getWatchProgress(userId, videoId);
  }

  async bookmarkVideo(videoId: string, userId: string, note?: string) {
    const video = await this.repo.findById(videoId);
    if (!video) throw new NotFoundException('Video not found');

    await this.repo.upsertBookmark(userId, videoId, note);
    await this.repo.update(videoId, { bookmarksCount: { increment: 1 } });
    return { message: 'Video bookmarked', videoId };
  }

  async removeBookmark(videoId: string, userId: string) {
    await this.repo.removeBookmark(userId, videoId);
    return { message: 'Bookmark removed', videoId };
  }

  async getBookmarks(userId: string, page = 1, limit = 20) {
    return this.repo.getBookmarks(userId, page, limit);
  }

  async findByUser(
    userId: string,
    opts: {
      page?: number;
      limit?: number;
      cursor?: string;
      isStream?: boolean;
    },
  ) {
    const result = await this.repo.findByUser(userId, opts);
    return {
      ...result,
      data: result.data.map((v) => this.mapVideoToDto(v)),
    };
  }

  async deleteVideo(videoId: string, userId: string) {
    const video = await this.repo.findById(videoId);
    if (!video) throw new NotFoundException('Video not found');
    const canEdit = await this.canModifyVideo(video, userId);
    if (!canEdit)
      throw new ForbiddenException(
        'Insufficient permissions to delete this video',
      );
    await this.repo.softDelete(videoId);
    return { success: true, message: 'Video deleted successfully', videoId };
  }

  async updateVideo(videoId: string, userId: string, dto: UpdateVideoDto) {
    const video = await this.repo.findById(videoId);
    if (!video) throw new NotFoundException('Video not found');
    const canEdit = await this.canModifyVideo(video, userId);
    if (!canEdit)
      throw new ForbiddenException(
        'Insufficient permissions to edit this video',
      );
    const updated = await this.repo.update(videoId, dto as any);
    return this.mapVideoToDto(updated);
  }

  async getTrending(limit = 20) {
    const videos = await this.repo.getTrending(limit);
    return videos.map((v) => this.mapVideoToDto(v));
  }

  async getLatest(page = 1, limit = 20) {
    const result = await this.repo.getLatest(page, limit);
    return { ...result, data: result.data.map((v) => this.mapVideoToDto(v)) };
  }

  async getRecommended(videoId: string, userId: string, limit = 10) {
    const videos = await this.repo.getRecommended(userId, videoId, limit);
    return videos.map((v) => this.mapVideoToDto(v));
  }

  async searchVideos(opts: {
    search?: string;
    category?: string;
    page?: number;
    limit?: number;
    cursor?: string;
  }) {
    const result = await this.repo.findPublicVideos(opts);
    return { ...result, data: result.data.map((v) => this.mapVideoToDto(v)) };
  }

  async reportVideo(
    videoId: string,
    userId: string,
    reason: any,
    details?: string,
  ) {
    const video = await this.repo.findById(videoId);
    if (!video) throw new NotFoundException('Video not found');

    return this.repo.reportVideo({ videoId, userId, reason, details });
  }

  private async canModifyVideo(video: any, userId: string): Promise<boolean> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { role: true },
    });
    if (!user) return false;
    if (
      (user.role.name as AppRole) === AppRole.SUPER_ADMIN ||
      (user.role.name as AppRole) === AppRole.ADMIN
    )
      return true;
    if (video.uploadedById === userId) return true;

    let groupId = video.videoChannel?.groupId;
    if (!groupId && video.channelId) {
      const ch = await this.prisma.videoChannel.findUnique({
        where: { id: video.channelId },
        select: { groupId: true },
      });
      groupId = ch?.groupId;
    }

    if (!groupId) return false;

    // Check if user is group creator
    const group = await this.prisma.group.findUnique({
      where: { id: groupId },
      select: { createdById: true },
    });
    if (group?.createdById === userId) return true;

    // Check group MODERATOR or higher
    const membership = await this.prisma.groupMember.findFirst({
      where: {
        groupId,
        userId,
        removedAt: null,
      },
      select: { role: true },
    });
    return (
      membership?.role === GroupRole.GROUP_ADMIN ||
      membership?.role === GroupRole.MODERATOR
    );
  }

  /**
   * Rewrites localhost/loopback URLs to the production Render host so the
   * Flutter client always receives a reachable URL, even for old DB records
   * that were inserted before APP_URL was configured correctly.
   */
  private sanitizeUrl(url: string | null | undefined): string | null {
    if (!url) return null;
    const RENDER_HOST = 'https://zikrekidusan.onrender.com';
    const LOCALHOST_PATTERNS = [
      /^http:\/\/localhost:\d+/,
      /^http:\/\/127\.0\.0\.1:\d+/,
      /^http:\/\/0\.0\.0\.0:\d+/,
      /^http:\/\/10\.0\.2\.2:\d+/, // Android emulator loopback
    ];
    for (const pattern of LOCALHOST_PATTERNS) {
      if (pattern.test(url)) {
        return url.replace(pattern, RENDER_HOST);
      }
    }
    return url;
  }

  private mapVideoToDto(video: any) {
    // viewsCount is stored as BigInt in Prisma — must convert to plain number for JSON
    const rawViews = video.viewsCount;
    const viewsCount =
      typeof rawViews === 'bigint'
        ? Number(rawViews)
        : typeof rawViews === 'string'
          ? parseInt(rawViews, 10) || 0
          : (rawViews ?? 0);

    // Build author from uploadedBy relation if available
    const author = video.uploadedBy
      ? {
          id: video.uploadedBy.id ?? '',
          username: video.uploadedBy.username ?? '',
          displayName: video.uploadedBy.profile?.displayName ?? null,
          avatarUrl: null as string | null, // avatarFileId would need separate lookup
        }
      : { id: '', username: '', displayName: null, avatarUrl: null };

    // Fallback to sourceFile.url if hlsUrl is not set, then sanitize all URLs
    const rawHlsUrl = video.hlsUrl || video.sourceFile?.url || null;
    const sourceFileUrl = video.sourceFile?.url || null;

    return {
      ...video,
      hlsUrl: this.sanitizeUrl(rawHlsUrl),
      sourceFileUrl: this.sanitizeUrl(sourceFileUrl),
      thumbnailUrl: this.sanitizeUrl(video.thumbnailUrl),
      previewUrl: this.sanitizeUrl(video.previewUrl),
      dashUrl: this.sanitizeUrl(video.dashUrl),
      // Defaults for nullable numeric fields so Flutter doesn't choke on null
      duration: video.duration ?? 0,
      width: video.width ?? 0,
      height: video.height ?? 0,
      bitrate: video.bitrate ?? 0,
      likesCount: video.likesCount ?? 0,
      dislikesCount: video.dislikesCount ?? 0,
      commentsCount: video.commentsCount ?? 0,
      sharesCount: video.sharesCount ?? 0,
      bookmarksCount: video.bookmarksCount ?? 0,
      downloadsCount: video.downloadsCount ?? 0,
      viewsCount,
      author,
      // Ensure channelId field is surfaced for Flutter
      channelId: video.videoChannelId ?? video.videoChannel?.id ?? null,
      channelName: video.videoChannel?.name ?? null,
    };
  }
}
