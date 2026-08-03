import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { StreamAnalytics, Prisma } from '@prisma/client';

@Injectable()
export class StreamAnalyticsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async getAnalytics(liveStreamId: string): Promise<StreamAnalytics | null> {
    return this.prisma.streamAnalytics.findUnique({
      where: { liveStreamId },
    });
  }

  async ensureAnalyticsExists(liveStreamId: string): Promise<StreamAnalytics> {
    const analytics = await this.getAnalytics(liveStreamId);
    if (analytics) return analytics;

    return this.prisma.streamAnalytics.create({
      data: { liveStreamId },
    });
  }

  async updateViewerCount(
    liveStreamId: string,
    currentViewers: number,
    peakViewers: number,
  ) {
    // Update live stream stats
    await this.prisma.liveStream.update({
      where: { id: liveStreamId },
      data: {
        currentViewerCount: currentViewers,
        peakViewerCount: { set: Math.max(peakViewers, currentViewers) }, // Only increase peak
      },
    });

    // Update analytics peak
    await this.ensureAnalyticsExists(liveStreamId);
    await this.prisma.streamAnalytics.update({
      where: { liveStreamId },
      data: {
        peakConcurrentViewers: { set: Math.max(peakViewers, currentViewers) },
      },
    });
  }

  async recordViewerJoin(liveStreamId: string, userId: string) {
    return this.prisma.streamViewer.create({
      data: {
        liveStreamId,
        userId,
      },
    });
  }

  async recordViewerLeave(viewerId: string, watchDuration: number) {
    return this.prisma.streamViewer.update({
      where: { id: viewerId },
      data: {
        leftAt: new Date(),
        watchDuration,
      },
    });
  }

  async incrementEngagement(
    liveStreamId: string,
    field: 'totalChatMessages' | 'totalReactions' | 'totalLikes',
    amount = 1,
  ) {
    await this.ensureAnalyticsExists(liveStreamId);

    const liveStreamData =
      field === 'totalChatMessages'
        ? { totalChatMessages: { increment: amount } }
        : field === 'totalReactions'
          ? { totalReactions: { increment: amount } }
          : { likesCount: { increment: amount } };

    const analyticsData =
      field === 'totalChatMessages'
        ? { totalChatMessages: { increment: amount } }
        : field === 'totalReactions'
          ? { totalReactions: { increment: amount } }
          : { totalLikes: { increment: amount } };

    await this.prisma.$transaction([
      this.prisma.liveStream.update({
        where: { id: liveStreamId },
        data: liveStreamData,
      }),
      this.prisma.streamAnalytics.update({
        where: { liveStreamId },
        data: analyticsData,
      }),
    ]);
  }
}
