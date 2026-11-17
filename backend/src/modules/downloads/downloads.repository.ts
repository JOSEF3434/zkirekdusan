// src/modules/downloads/downloads.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { DownloadStatus, VideoResolution } from '@prisma/client';

@Injectable()
export class DownloadsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createRecord(data: {
    userId: string;
    videoId?: string;
    fileId?: string;
    postId?: string;
    publisherId?: string;
    resolution?: VideoResolution;
    signedUrl: string;
    expiresAt: Date;
    ipAddress?: string;
    userAgent?: string;
    fileSize?: bigint;
    isWatermarked?: boolean;
    watermarkText?: string;
    attributionJson?: any;
  }) {
    return this.prisma.downloadRecord.create({
      data: {
        userId: data.userId,
        videoId: data.videoId,
        fileId: data.fileId,
        postId: data.postId,
        publisherId: data.publisherId,
        resolution: data.resolution,
        signedUrl: data.signedUrl,
        expiresAt: data.expiresAt,
        ipAddress: data.ipAddress,
        userAgent: data.userAgent,
        fileSize: data.fileSize,
        isWatermarked: data.isWatermarked ?? false,
        watermarkText: data.watermarkText,
        attributionJson: data.attributionJson,
        status: DownloadStatus.PENDING,
      },
    });
  }

  async updateRecordStatus(
    id: string,
    status: DownloadStatus,
    bytesServed?: bigint,
  ) {
    return this.prisma.downloadRecord.update({
      where: { id },
      data: {
        status,
        bytesServed,
        completedAt:
          status === DownloadStatus.COMPLETED ? new Date() : undefined,
      },
    });
  }

  async getUserHistory(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [data, total] = await this.prisma.$transaction([
      this.prisma.downloadRecord.findMany({
        where: { userId },
        include: {
          video: {
            select: { id: true, title: true, slug: true, thumbnailUrl: true },
          },
          post: {
            select: {
              id: true,
              content: true,
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
            },
          },
          publisher: {
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
          file: {
            select: {
              id: true,
              originalName: true,
              fileType: true,
              mimeType: true,
            },
          },
        },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.downloadRecord.count({ where: { userId } }),
    ]);

    return {
      data: data.map((d) => ({
        ...d,
        fileSize: d.fileSize?.toString(),
        bytesServed: d.bytesServed?.toString(),
      })),
      total,
      page,
      limit,
    };
  }

  async getDownloadStats(userId?: string) {
    const where = userId ? { userId } : {};
    const [totalDownloads, completed, bytes] = await this.prisma.$transaction([
      this.prisma.downloadRecord.count({ where }),
      this.prisma.downloadRecord.count({
        where: { ...where, status: DownloadStatus.COMPLETED },
      }),
      this.prisma.downloadRecord.aggregate({
        where: { ...where, status: DownloadStatus.COMPLETED },
        _sum: { bytesServed: true },
      }),
    ]);

    return {
      totalDownloads,
      completedDownloads: completed,
      totalBytesServed: bytes._sum.bytesServed?.toString() ?? '0',
    };
  }
}
