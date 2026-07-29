// src/modules/videos/videos.service.ts
import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { VideosRepository } from './videos.repository.js';
import { UploadVideoDto } from './dto/upload-video.dto.js';
import { UpdateVideoDto } from './dto/update-video.dto.js';
import { VideoStatus, VideoVisibility, GroupRole } from '@prisma/client';
import { AppRole } from '../../common/constants/roles.js';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class VideosService {
  constructor(
    private readonly repo: VideosRepository,
    private readonly prisma: PrismaService,
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
    if (user.role.name === AppRole.SUPER_ADMIN || user.role.name === AppRole.ADMIN) {
      const channel = await this.prisma.videoChannel.findUnique({
        where: { id: videoChannelId, deletedAt: null },
        select: { id: true, groupId: true },
      });
      if (!channel) throw new NotFoundException('Video channel not found');
      return { groupId: channel.groupId, channelId: channel.id };
    }

    const channel = await this.prisma.videoChannel.findUnique({
      where: { id: videoChannelId, deletedAt: null },
      select: {
        id: true,
        groupId: true,
        uploadPermission: true,
        group: { select: { id: true, status: true } },
      },
    });

    if (!channel) throw new NotFoundException('Video channel not found');
    if (channel.group.status !== 'ACTIVE') {
      throw new ForbiddenException('Group is not active');
    }

    const membership = await this.prisma.groupMember.findUnique({
      where: {
        groupId_userId: { groupId: channel.groupId, userId },
        removedAt: null,
      },
      select: { role: true },
    });

    if (!membership) throw new ForbiddenException('You are not a member of this group');

    const roleHierarchy: Record<string, number> = {
      GROUP_ADMIN: 4,
      MODERATOR: 3,
      MEMBER: 2,
      GUEST: 1,
    };

    const userLevel = roleHierarchy[membership.role] ?? 0;
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
    await this.verifyChannelUploadPermission(videoChannelId, userId);

    const slug = this.generateSlug(dto.title);

    const video = await this.repo.create({
      videoChannelId,
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

    return video;
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
      if (!user || (user.role.name !== AppRole.SUPER_ADMIN && user.role.name !== AppRole.ADMIN)) {
        throw new ForbiddenException('Only the video uploader can attach files');
      }
    }

    if (video.status !== VideoStatus.UPLOADING) {
      throw new BadRequestException('Video is not in UPLOADING state');
    }

    return this.repo.setSourceFile(videoId, fileId);
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
    userId: string,
    opts: { page?: number; limit?: number; cursor?: string; status?: VideoStatus; search?: string },
  ) {
    // For non-admins, restrict to READY + PUBLIC/GROUP_ONLY
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { role: true },
    });
    const isAdmin = user?.role.name === AppRole.SUPER_ADMIN || user?.role.name === AppRole.ADMIN;

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
      data: result.data.map(this.mapVideoToDto),
    };
  }

  async update(id: string, userId: string, dto: UpdateVideoDto) {
    const video = await this.repo.findById(id);
    if (!video) throw new NotFoundException('Video not found');

    const canEdit = await this.canModifyVideo(video, userId);
    if (!canEdit) throw new ForbiddenException('Insufficient permissions to edit this video');

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
    if (!canEdit) throw new ForbiddenException('Insufficient permissions to delete this video');

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
    const watchedPercent = duration > 0 ? Math.min((watchedSeconds / duration) * 100, 100) : 0;
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
    return this.repo.getWatchHistory(userId, page, limit);
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

  async getTrending(limit = 20) {
    const videos = await this.repo.getTrending(limit);
    return videos.map(this.mapVideoToDto);
  }

  async getRecommended(videoId: string, userId: string, limit = 10) {
    const videos = await this.repo.getRecommended(userId, videoId, limit);
    return videos.map(this.mapVideoToDto);
  }

  async searchVideos(opts: {
    search?: string;
    category?: string;
    page?: number;
    limit?: number;
    cursor?: string;
  }) {
    const result = await this.repo.findPublicVideos(opts);
    return { ...result, data: result.data.map(this.mapVideoToDto) };
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
    if (user.role.name === AppRole.SUPER_ADMIN || user.role.name === AppRole.ADMIN) return true;
    if (video.uploadedById === userId) return true;

    // Check group MODERATOR or higher
    const membership = await this.prisma.groupMember.findUnique({
      where: {
        groupId_userId: { groupId: video.videoChannel.groupId, userId },
        removedAt: null,
      },
      select: { role: true },
    });
    return membership?.role === GroupRole.GROUP_ADMIN || membership?.role === GroupRole.MODERATOR;
  }

  private mapVideoToDto(video: any) {
    return {
      ...video,
      viewsCount: video.viewsCount?.toString() ?? '0',
    };
  }
}
