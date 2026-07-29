// src/modules/video-subscriptions/video-subscriptions.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class VideoSubscriptionsService {
  constructor(private readonly prisma: PrismaService) {}

  async getUserSubscriptions(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [data, total] = await this.prisma.$transaction([
      this.prisma.videoSubscription.findMany({
        where: { userId },
        include: {
          videoChannel: {
            select: {
              id: true,
              name: true,
              handle: true,
              slug: true,
              subscribersCount: true,
              videosCount: true,
              avatarFileId: true,
            },
          },
        },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.videoSubscription.count({ where: { userId } }),
    ]);
    return { data, total, page, limit };
  }

  async getSubscriptionFeed(userId: string, page = 1, limit = 20) {
    const subs = await this.prisma.videoSubscription.findMany({
      where: { userId },
      select: { videoChannelId: true },
    });

    const channelIds = subs.map((s) => s.videoChannelId);
    if (channelIds.length === 0) {
      return { data: [], total: 0, page, limit };
    }

    const skip = (page - 1) * limit;
    const [data, total] = await this.prisma.$transaction([
      this.prisma.video.findMany({
        where: {
          videoChannelId: { in: channelIds },
          status: 'READY',
          visibility: 'PUBLIC',
          deletedAt: null,
        },
        include: {
          videoChannel: { select: { id: true, name: true, handle: true } },
          uploadedBy: { select: { id: true, username: true } },
        },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.video.count({
        where: {
          videoChannelId: { in: channelIds },
          status: 'READY',
          visibility: 'PUBLIC',
          deletedAt: null,
        },
      }),
    ]);

    return {
      data: data.map((v) => ({ ...v, viewsCount: v.viewsCount.toString() })),
      total,
      page,
      limit,
    };
  }
}
