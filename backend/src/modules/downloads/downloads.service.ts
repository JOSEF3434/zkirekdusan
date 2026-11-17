// src/modules/downloads/downloads.service.ts
import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service.js';
import { DownloadsRepository } from './downloads.repository.js';
import {
  RequestVideoDownloadDto,
  RequestFileDownloadDto,
  RequestPostDownloadDto,
  DownloadTokenResponseDto,
  MediaAttributionDto,
} from './dto/request-download.dto.js';
import {
  DownloadPermission,
  VideoResolution,
  DownloadStatus,
} from '@prisma/client';
import { AppRole } from '../../common/constants/roles.js';
import { STORAGE_PROVIDER_TOKEN } from '../uploads/providers/storage.factory.js';
import type { IStorageProvider } from '../uploads/providers/storage.interface.js';
import { CloudinaryStorageProvider } from '../uploads/providers/cloudinary.provider.js';
import crypto from 'crypto';
import path from 'path';

@Injectable()
export class DownloadsService {
  constructor(
    private readonly repo: DownloadsRepository,
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    @Optional()
    @Inject(STORAGE_PROVIDER_TOKEN)
    private readonly storageProvider?: IStorageProvider & Record<string, any>,
    @Optional()
    private readonly cloudinaryProvider?: CloudinaryStorageProvider,
  ) {}

  /**
   * Authorize and generate a secure, TikTok-style watermarked download link for a Video.
   */
  async authorizeVideoDownload(
    userId: string,
    dto: RequestVideoDownloadDto,
    ipAddress?: string,
    userAgent?: string,
  ): Promise<DownloadTokenResponseDto> {
    const video = await this.prisma.video.findUnique({
      where: { id: dto.videoId, deletedAt: null },
      include: {
        uploadedBy: {
          select: {
            id: true,
            username: true,
            profile: {
              select: { displayName: true, avatar: { select: { url: true } } },
            },
          },
        },
        videoChannel: {
          select: {
            id: true,
            name: true,
            groupId: true,
            downloadPermission: true,
          },
        },
        renditions: true,
        sourceFile: true,
      },
    });

    if (!video) throw new NotFoundException('Video not found');

    // Security validation against RBAC & Publisher settings
    await this.verifyDownloadPermission(userId, video);

    // Resolution selection (default to 720p or fallback to closest available)
    const targetRes = dto.resolution ?? VideoResolution.R_720P;
    const rendition =
      video.renditions.find((r) => r.resolution === targetRes) ||
      video.renditions.sort((a, b) => b.height - a.height)[0];

    const appUrl =
      this.configService.get<string>('APP_URL') ??
      this.configService.get<string>('RENDER_EXTERNAL_URL') ??
      'https://zikrekidusan.onrender.com';

    // Build trusted publisher identity from backend database
    const publisherUsername = video.uploadedBy?.username ?? 'zikre_kdusan';
    const publisherDisplayName =
      video.uploadedBy?.profile?.displayName ?? publisherUsername;
    const publisherAvatarUrl =
      video.uploadedBy?.profile?.avatar?.url ?? null;
    const channelName = video.videoChannel?.name ?? null;

    const watermarkText = `@${publisherUsername}`;
    const brandName = 'Zikire Kdusan';
    const canonicalUrl = `${appUrl}/videos/${video.id}`;

    const safeTitle = video.title.replace(/[^a-zA-Z0-9_-]/g, '_');
    const filename = `${safeTitle}_${targetRes.toLowerCase()}.mp4`;

    // Generate signed download URL token
    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour validity

    // Generate server-side watermarked URL if Cloudinary is active
    let watermarkedMediaUrl: string | null = null;
    const activeCloudinary =
      this.cloudinaryProvider ??
      (this.storageProvider instanceof CloudinaryStorageProvider
        ? (this.storageProvider as CloudinaryStorageProvider)
        : null);

    const storageKey =
      rendition?.storageKey ?? video.sourceFile?.storageKey;
    if (storageKey && activeCloudinary && activeCloudinary.isConfigured) {
      watermarkedMediaUrl = activeCloudinary.getVideoWatermarkedDownloadUrl(
        storageKey,
        watermarkText,
        brandName,
        filename,
      );
    }

    const attribution: MediaAttributionDto = {
      publisherId: video.uploadedById,
      publisherUsername,
      publisherDisplayName,
      publisherAvatarUrl,
      sourceType: 'VIDEO',
      sourceId: video.id,
      sourceTitle: video.title,
      canonicalUrl,
      watermarkText,
      brandName,
      channelName,
      groupName: null,
    };

    // Create Download Audit Record with publisher identity and watermark metadata
    const record = await this.repo.createRecord({
      userId,
      videoId: video.id,
      publisherId: video.uploadedById,
      resolution: targetRes,
      signedUrl: '',
      expiresAt,
      ipAddress,
      userAgent,
      fileSize: rendition ? rendition.fileSize : BigInt(0),
      isWatermarked: true,
      watermarkText,
      attributionJson: attribution as any,
    });

    const downloadUrl = `${appUrl}/api/downloads/file/${record.id}?token=${token}`;

    await this.prisma.downloadRecord.update({
      where: { id: record.id },
      data: { signedUrl: downloadUrl },
    });

    // Audit log entry
    await this.prisma.auditLog.create({
      data: {
        userId,
        action: 'VIDEO_DOWNLOAD_REQUESTED',
        resource: `Video:${video.id}`,
        details: {
          resolution: targetRes,
          recordId: record.id,
          publisherUsername,
          watermarked: true,
        },
        ipAddress,
      },
    });

    // Increment video download count
    await this.prisma.video.update({
      where: { id: video.id },
      data: { downloadsCount: { increment: 1 } },
    });

    return {
      downloadId: record.id,
      downloadUrl,
      expiresAt,
      resolution: targetRes,
      filename,
      fileType: 'VIDEO',
      mimeType: 'video/mp4',
      isWatermarked: true,
      watermarkedMediaUrl,
      attribution,
    };
  }

  /**
   * Authorize and generate a secure download link for Social Post Media with publisher watermark.
   */
  async authorizePostDownload(
    userId: string,
    dto: RequestPostDownloadDto,
    ipAddress?: string,
    userAgent?: string,
  ): Promise<DownloadTokenResponseDto> {
    const post = await this.prisma.post.findUnique({
      where: { id: dto.postId, deletedAt: null },
      include: {
        author: {
          select: {
            id: true,
            username: true,
            profile: {
              select: { displayName: true, avatar: { select: { url: true } } },
            },
          },
        },
        group: { select: { id: true, name: true, status: true } },
        media: {
          include: { file: true },
          orderBy: { order: 'asc' },
        },
      },
    });

    if (!post) throw new NotFoundException('Post not found');

    // Security validation against RBAC & Publisher settings
    await this.verifyPostDownloadPermission(userId, post);

    if (!post.media || post.media.length === 0) {
      throw new NotFoundException('This post contains no downloadable media');
    }

    const postMedia = dto.mediaFileId
      ? post.media.find((m) => m.fileId === dto.mediaFileId) ?? post.media[0]
      : post.media[0];

    const file = postMedia.file;
    if (!file) throw new NotFoundException('Media file not found');

    const appUrl =
      this.configService.get<string>('APP_URL') ??
      this.configService.get<string>('RENDER_EXTERNAL_URL') ??
      'https://zikrekidusan.onrender.com';

    // Build trusted publisher identity from backend database
    const publisherUsername = post.author?.username ?? 'zikre_kdusan';
    const publisherDisplayName =
      post.author?.profile?.displayName ?? publisherUsername;
    const publisherAvatarUrl = post.author?.profile?.avatar?.url ?? null;
    const groupName = post.group?.name ?? null;

    // TikTok-style watermark text: @username (or @group if published in a group)
    const watermarkText = `@${publisherUsername}`;
    const brandName = 'Zikire Kdusan';
    const canonicalUrl = `${appUrl}/post/${post.id}`;

    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000);

    const safeFilename = file.originalName.replace(/[^a-zA-Z0-9_.-]/g, '_');

    // Generate server-side watermarked URL if Cloudinary is active
    let watermarkedMediaUrl: string | null = null;
    const activeCloudinary =
      this.cloudinaryProvider ??
      (this.storageProvider instanceof CloudinaryStorageProvider
        ? (this.storageProvider as CloudinaryStorageProvider)
        : null);

    if (file.storageKey && activeCloudinary && activeCloudinary.isConfigured) {
      if (file.fileType === 'IMAGE') {
        watermarkedMediaUrl = activeCloudinary.getImageWatermarkedDownloadUrl(
          file.storageKey,
          watermarkText,
          brandName,
        );
      } else if (file.fileType === 'VIDEO') {
        watermarkedMediaUrl = activeCloudinary.getVideoWatermarkedDownloadUrl(
          file.storageKey,
          watermarkText,
          brandName,
          safeFilename,
        );
      }
    }

    const attribution: MediaAttributionDto = {
      publisherId: post.authorId,
      publisherUsername,
      publisherDisplayName,
      publisherAvatarUrl,
      sourceType: 'POST',
      sourceId: post.id,
      sourceTitle: post.content ? post.content.slice(0, 60) : 'Post Media',
      canonicalUrl,
      watermarkText,
      brandName,
      channelName: null,
      groupName,
    };

    const record = await this.repo.createRecord({
      userId,
      postId: post.id,
      fileId: file.id,
      publisherId: post.authorId,
      signedUrl: '',
      expiresAt,
      ipAddress,
      userAgent,
      fileSize: file.size,
      isWatermarked: file.fileType === 'IMAGE' || file.fileType === 'VIDEO',
      watermarkText,
      attributionJson: attribution as any,
    });

    const downloadUrl = `${appUrl}/api/downloads/file/${record.id}?token=${token}`;

    await this.prisma.downloadRecord.update({
      where: { id: record.id },
      data: { signedUrl: downloadUrl },
    });

    // Audit log entry
    await this.prisma.auditLog.create({
      data: {
        userId,
        action: 'POST_DOWNLOAD_REQUESTED',
        resource: `Post:${post.id}`,
        details: {
          fileId: file.id,
          recordId: record.id,
          publisherUsername,
          watermarked: true,
        },
        ipAddress,
      },
    });

    // Increment post download count
    await this.prisma.post.update({
      where: { id: post.id },
      data: { downloadsCount: { increment: 1 } },
    });

    return {
      downloadId: record.id,
      downloadUrl,
      expiresAt,
      filename: safeFilename,
      fileType: file.fileType,
      mimeType: file.mimeType,
      isWatermarked: file.fileType === 'IMAGE' || file.fileType === 'VIDEO',
      watermarkedMediaUrl,
      attribution,
    };
  }

  /**
   * Authorize generic file download (Image, Audio, Document)
   */
  async authorizeFileDownload(
    userId: string,
    dto: RequestFileDownloadDto,
    ipAddress?: string,
    userAgent?: string,
  ): Promise<DownloadTokenResponseDto> {
    const file = await this.prisma.file.findUnique({
      where: { id: dto.fileId, deletedAt: null },
      include: {
        group: { select: { id: true, name: true, status: true } },
        uploadedBy: {
          select: {
            id: true,
            username: true,
            profile: {
              select: { displayName: true, avatar: { select: { url: true } } },
            },
          },
        },
      },
    });

    if (!file) throw new NotFoundException('File not found');

    // Group membership check for group files
    if (file.groupId) {
      await this.verifyGroupFileAccess(userId, file.groupId);
    }

    const appUrl =
      this.configService.get<string>('APP_URL') ??
      this.configService.get<string>('RENDER_EXTERNAL_URL') ??
      'https://zikrekidusan.onrender.com';
    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000);

    const publisherUsername = file.uploadedBy?.username ?? 'zikre_kdusan';
    const publisherDisplayName =
      file.uploadedBy?.profile?.displayName ?? publisherUsername;
    const publisherAvatarUrl = file.uploadedBy?.profile?.avatar?.url ?? null;
    const watermarkText = `@${publisherUsername}`;
    const brandName = 'Zikire Kdusan';
    const canonicalUrl = `${appUrl}/files/${file.id}`;

    const isMedia = file.fileType === 'IMAGE' || file.fileType === 'VIDEO';

    const attribution: MediaAttributionDto = {
      publisherId: file.uploadedById,
      publisherUsername,
      publisherDisplayName,
      publisherAvatarUrl,
      sourceType: 'FILE',
      sourceId: file.id,
      sourceTitle: file.originalName,
      canonicalUrl,
      watermarkText,
      brandName,
      channelName: null,
      groupName: file.group?.name ?? null,
    };

    const record = await this.repo.createRecord({
      userId,
      fileId: file.id,
      publisherId: file.uploadedById,
      signedUrl: '',
      expiresAt,
      ipAddress,
      userAgent,
      fileSize: file.size,
      isWatermarked: isMedia,
      watermarkText: isMedia ? watermarkText : undefined,
      attributionJson: attribution as any,
    });

    const downloadUrl = `${appUrl}/api/downloads/file/${record.id}?token=${token}`;

    await this.prisma.downloadRecord.update({
      where: { id: record.id },
      data: { signedUrl: downloadUrl },
    });

    return {
      downloadId: record.id,
      downloadUrl,
      expiresAt,
      filename: file.originalName,
      fileType: file.fileType,
      mimeType: file.mimeType,
      isWatermarked: isMedia,
      attribution,
    };
  }

  /**
   * Fast permission validation endpoint for UI queries.
   */
  async checkDownloadPermission(
    userId: string,
    type: 'video' | 'post' | 'file',
    id: string,
  ): Promise<{ isAllowed: boolean; reason?: string; attribution?: MediaAttributionDto }> {
    try {
      if (type === 'video') {
        const video = await this.prisma.video.findUnique({
          where: { id, deletedAt: null },
          include: {
            uploadedBy: {
              select: {
                id: true,
                username: true,
                profile: {
                  select: {
                    displayName: true,
                    avatar: { select: { url: true } },
                  },
                },
              },
            },
            videoChannel: {
              select: { id: true, name: true, groupId: true, downloadPermission: true },
            },
          },
        });
        if (!video) return { isAllowed: false, reason: 'Video not found' };
        await this.verifyDownloadPermission(userId, video);
        return {
          isAllowed: true,
          attribution: {
            publisherId: video.uploadedById,
            publisherUsername: video.uploadedBy?.username ?? 'user',
            publisherDisplayName:
              video.uploadedBy?.profile?.displayName ??
              video.uploadedBy?.username ??
              'user',
            publisherAvatarUrl: video.uploadedBy?.profile?.avatar?.url ?? null,
            sourceType: 'VIDEO',
            sourceId: video.id,
            sourceTitle: video.title,
            canonicalUrl: `https://zikrekidusan.org/video/${video.id}`,
            watermarkText: `@${video.uploadedBy?.username ?? 'user'}`,
            brandName: 'Zikire Kdusan',
            channelName: video.videoChannel?.name ?? null,
            groupName: null,
          },
        };
      } else if (type === 'post') {
        const post = await this.prisma.post.findUnique({
          where: { id, deletedAt: null },
          include: {
            author: {
              select: {
                id: true,
                username: true,
                profile: {
                  select: {
                    displayName: true,
                    avatar: { select: { url: true } },
                  },
                },
              },
            },
            group: { select: { id: true, name: true, status: true } },
          },
        });
        if (!post) return { isAllowed: false, reason: 'Post not found' };
        await this.verifyPostDownloadPermission(userId, post);
        return {
          isAllowed: true,
          attribution: {
            publisherId: post.authorId,
            publisherUsername: post.author?.username ?? 'user',
            publisherDisplayName:
              post.author?.profile?.displayName ??
              post.author?.username ??
              'user',
            publisherAvatarUrl: post.author?.profile?.avatar?.url ?? null,
            sourceType: 'POST',
            sourceId: post.id,
            sourceTitle: post.content ? post.content.slice(0, 60) : 'Post Media',
            canonicalUrl: `https://zikrekidusan.org/post/${post.id}`,
            watermarkText: `@${post.author?.username ?? 'user'}`,
            brandName: 'Zikire Kdusan',
            channelName: null,
            groupName: post.group?.name ?? null,
          },
        };
      }
      return { isAllowed: true };
    } catch (e: any) {
      return {
        isAllowed: false,
        reason: e.message ?? 'The publisher has disabled downloads.',
      };
    }
  }

  /**
   * Serve file download stream with Content-Disposition header
   */
  async getDownloadStreamInfo(downloadRecordId: string, userId: string) {
    const record = await this.prisma.downloadRecord.findUnique({
      where: { id: downloadRecordId },
      include: {
        video: {
          include: { renditions: true, sourceFile: true },
        },
        file: true,
        post: {
          include: {
            media: {
              include: { file: true },
              orderBy: { order: 'asc' },
            },
          },
        },
      },
    });

    if (!record) throw new NotFoundException('Download record not found');
    if (record.userId !== userId) {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        include: { role: true },
      });
      if (
        user?.role.name !== AppRole.SUPER_ADMIN &&
        user?.role.name !== AppRole.ADMIN
      ) {
        throw new ForbiddenException('Download record does not belong to user');
      }
    }

    let filePath: string | null = null;
    let remoteUrl: string | null = null;
    let filename = 'download.mp4';
    let mimeType = 'video/mp4';

    if (record.videoId && record.video) {
      const targetRes = record.resolution ?? VideoResolution.R_720P;
      const rendition = record.video.renditions.find(
        (r) => r.resolution === targetRes,
      );

      filename = `${record.video.title.replace(/[^a-zA-Z0-9_-]/g, '_')}_${targetRes.toLowerCase()}.mp4`;

      if (rendition?.url) {
        if (
          rendition.url.startsWith('http://') ||
          rendition.url.startsWith('https://')
        ) {
          remoteUrl = rendition.url;
        } else {
          filePath = path.resolve(
            process.cwd(),
            'uploads',
            rendition.storageKey,
          );
        }
      } else if (record.video.sourceFile?.url) {
        if (
          record.video.sourceFile.url.startsWith('http://') ||
          record.video.sourceFile.url.startsWith('https://')
        ) {
          remoteUrl = record.video.sourceFile.url;
        } else {
          filePath = path.resolve(
            process.cwd(),
            'uploads',
            record.video.sourceFile.storageKey,
          );
        }
      } else if (record.video.hlsUrl) {
        remoteUrl = record.video.hlsUrl;
      }
    } else if (record.fileId && record.file) {
      filename = record.file.originalName;
      mimeType = record.file.mimeType;

      if (
        record.file.url &&
        (record.file.url.startsWith('http://') ||
          record.file.url.startsWith('https://'))
      ) {
        remoteUrl = record.file.url;
      } else {
        filePath = path.resolve(
          process.cwd(),
          'uploads',
          record.file.storageKey,
        );
      }
    } else if (record.postId && record.post) {
      const targetFile = record.file ?? record.post.media?.[0]?.file;
      if (targetFile) {
        filename = targetFile.originalName;
        mimeType = targetFile.mimeType;
        if (
          targetFile.url &&
          (targetFile.url.startsWith('http://') ||
            targetFile.url.startsWith('https://'))
        ) {
          remoteUrl = targetFile.url;
        } else {
          filePath = path.resolve(
            process.cwd(),
            'uploads',
            targetFile.storageKey,
          );
        }
      }
    }

    // Update status to COMPLETED
    await this.repo.updateRecordStatus(
      downloadRecordId,
      DownloadStatus.COMPLETED,
      record.fileSize || BigInt(0),
    );

    return { filePath, remoteUrl, filename, mimeType };
  }

  async getUserHistory(userId: string, page = 1, limit = 20) {
    return this.repo.getUserHistory(userId, page, limit);
  }

  async getDownloadStats(userId?: string) {
    return this.repo.getDownloadStats(userId);
  }

  private async verifyDownloadPermission(userId: string, video: any) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { role: true },
    });

    if (
      user?.role.name === AppRole.SUPER_ADMIN ||
      user?.role.name === AppRole.ADMIN
    ) {
      return true;
    }

    // Publisher permission validation
    if (video.isDownloadable === false) {
      throw new ForbiddenException('The publisher has disabled downloads.');
    }

    const permission =
      video.downloadPermission || video.videoChannel?.downloadPermission;

    if (permission === DownloadPermission.NONE) {
      throw new ForbiddenException('The publisher has disabled downloads.');
    }

    // Content privacy validation
    if (video.visibility === 'PRIVATE' && video.uploadedById !== userId) {
      throw new ForbiddenException('This video is private');
    }

    if (permission === DownloadPermission.PUBLIC) {
      return true;
    }

    const groupId = video.videoChannel?.groupId;
    if (groupId) {
      const member = await this.prisma.groupMember.findFirst({
        where: { groupId, userId, removedAt: null },
      });

      if (!member) {
        throw new ForbiddenException(
          'You must be a member of the group to download this video',
        );
      }
    }

    if (permission === DownloadPermission.SUBSCRIBERS_ONLY) {
      const isSubbed = await this.prisma.videoSubscription.findUnique({
        where: {
          userId_videoChannelId: {
            userId,
            videoChannelId: video.videoChannelId,
          },
        },
      });
      if (!isSubbed) {
        throw new ForbiddenException(
          'You must be subscribed to this channel to download',
        );
      }
    }

    return true;
  }

  private async verifyPostDownloadPermission(userId: string, post: any) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { role: true },
    });

    if (
      user?.role.name === AppRole.SUPER_ADMIN ||
      user?.role.name === AppRole.ADMIN
    ) {
      return true;
    }

    // Publisher download permission check
    if (post.allowDownloads === false) {
      throw new ForbiddenException('The publisher has disabled downloads.');
    }

    if (post.downloadPermission === DownloadPermission.NONE) {
      throw new ForbiddenException('The publisher has disabled downloads.');
    }

    // Content privacy validation
    if (post.visibility === 'PRIVATE' && post.authorId !== userId) {
      throw new ForbiddenException('This post is private');
    }

    // Group membership check for group posts
    if (post.groupId) {
      await this.verifyGroupFileAccess(userId, post.groupId);
    }

    return true;
  }

  private async verifyGroupFileAccess(userId: string, groupId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { role: true },
    });

    if (
      user?.role.name === AppRole.SUPER_ADMIN ||
      user?.role.name === AppRole.ADMIN
    ) {
      return true;
    }

    const member = await this.prisma.groupMember.findFirst({
      where: { groupId, userId, removedAt: null },
    });

    if (!member) {
      throw new ForbiddenException(
        'Access denied. You are not a member of this group.',
      );
    }
  }
}
