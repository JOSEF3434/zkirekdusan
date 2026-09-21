// src/modules/downloads/downloads.service.ts
import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service.js';
import { DownloadsRepository } from './downloads.repository.js';
import {
  RequestVideoDownloadDto,
  RequestFileDownloadDto,
} from './dto/request-download.dto.js';
import {
  DownloadPermission,
  VideoResolution,
  DownloadStatus,
} from '@prisma/client';
import { AppRole } from '../../common/constants/roles.js';
import crypto from 'crypto';
import path from 'path';

@Injectable()
export class DownloadsService {
  constructor(
    private readonly repo: DownloadsRepository,
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Authorize and generate a secure download link for a Video at chosen quality.
   */
  async authorizeVideoDownload(
    userId: string,
    dto: RequestVideoDownloadDto,
    ipAddress?: string,
    userAgent?: string,
  ) {
    const video = await this.prisma.video.findUnique({
      where: { id: dto.videoId, deletedAt: null },
      include: {
        videoChannel: {
          select: { id: true, groupId: true, downloadPermission: true },
        },
        renditions: true,
      },
    });

    if (!video) throw new NotFoundException('Video not found');

    // Check RBAC & Permissions
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

    // Generate signed download URL token
    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour validity

    // Create Download Audit Record
    const record = await this.repo.createRecord({
      userId,
      videoId: video.id,
      resolution: targetRes,
      signedUrl: '',
      expiresAt,
      ipAddress,
      userAgent,
      fileSize: rendition ? rendition.fileSize : BigInt(0),
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
        details: { resolution: targetRes, recordId: record.id },
        ipAddress,
      },
    });

    // Increment video download count
    await this.prisma.video.update({
      where: { id: video.id },
      data: { downloadsCount: { increment: 1 } },
    });

    const safeTitle = video.title.replace(/[^a-zA-Z0-9_-]/g, '_');
    const filename = `${safeTitle}_${targetRes.toLowerCase()}.mp4`;

    return {
      downloadId: record.id,
      downloadUrl,
      expiresAt,
      resolution: targetRes,
      filename,
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
  ) {
    const file = await this.prisma.file.findUnique({
      where: { id: dto.fileId, deletedAt: null },
      include: { group: { select: { id: true, status: true } } },
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

    const record = await this.repo.createRecord({
      userId,
      fileId: file.id,
      signedUrl: '',
      expiresAt,
      ipAddress,
      userAgent,
      fileSize: file.size,
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
    };
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

    const permission =
      video.downloadPermission || video.videoChannel.downloadPermission;

    if (permission === DownloadPermission.NONE) {
      throw new ForbiddenException('Downloads are disabled for this video');
    }

    if (permission === DownloadPermission.PUBLIC) {
      return true;
    }

    const groupId = video.videoChannel.groupId;
    const member = await this.prisma.groupMember.findFirst({
      where: { groupId, userId, removedAt: null },
    });

    if (!member) {
      throw new ForbiddenException(
        'You must be a member of the group to download this video',
      );
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
