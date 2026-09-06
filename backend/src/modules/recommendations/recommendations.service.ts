import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class RecommendationsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Home feed: if user has interaction history, rank content by weighted
   * RecommendationEvent signals. Otherwise fall back to popularity-sorted content.
   */
  async getHomeRecommendations(
    userId: string | undefined,
    page: number,
    limit: number,
  ) {
    const skip = (page - 1) * limit;

    if (userId) {
      // Fetch entity IDs the user has interacted with in the last 30 days
      const since = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      const events = await this.prisma.recommendationEvent.findMany({
        where: { userId, entityType: 'POST', timestamp: { gte: since } },
        orderBy: { timestamp: 'desc' },
        take: 200,
      });

      const interactedPostIds = new Set(events.map((e) => e.entityId));

      if (interactedPostIds.size > 0) {
        // Personalised: get posts NOT yet seen by the user, ranked by popularity
        const posts = await this.prisma.post.findMany({
          where: {
            status: 'PUBLISHED',
            visibility: 'PUBLIC',
            id: { notIn: Array.from(interactedPostIds) },
          },
          orderBy: [{ likesCount: 'desc' }, { createdAt: 'desc' }],
          take: limit,
          skip,
          include: {
            author: {
              select: {
                id: true,
                username: true,
                profile: { select: { displayName: true, avatar: { select: { url: true } } } },
              },
            },
            media: { include: { file: true } },
          },
        });
        return { data: posts, page, limit, source: 'personalised' };
      }
    }

    // Query public READY videos for home feed discovery
    const videos = await this.prisma.video.findMany({
      where: { status: 'READY', visibility: 'PUBLIC', deletedAt: null },
      orderBy: [{ viewsCount: 'desc' }, { createdAt: 'desc' }],
      take: limit,
      skip,
      include: {
        videoChannel: {
          select: { id: true, name: true, handle: true, groupId: true },
        },
        uploadedBy: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true, avatarFileId: true } },
          },
        },
        renditions: {
          select: {
            id: true,
            resolution: true,
            height: true,
            width: true,
            bitrate: true,
            url: true,
            isReady: true,
          },
        },
        sourceFile: {
          select: { id: true, url: true, storageKey: true },
        },
      },
    });

    if (videos.length > 0) {
      const mappedVideos = videos.map((v) => ({
        ...v,
        viewsCount: Number(v.viewsCount ?? 0),
        duration: v.duration ?? 0,
        author: v.uploadedBy
          ? {
              id: v.uploadedBy.id ?? '',
              username: v.uploadedBy.username ?? '',
              displayName: v.uploadedBy.profile?.displayName ?? null,
              avatarUrl: null,
            }
          : { id: '', username: '', displayName: null, avatarUrl: null },
        channelId: v.videoChannelId ?? v.videoChannel?.id ?? null,
        channelName: v.videoChannel?.name ?? null,
        content: v.title,
        type: 'VIDEO',
        media: [
          {
            id: v.id,
            url: v.hlsUrl || v.sourceFile?.url || '',
            fileType: 'video/mp4',
            order: 0,
          },
        ],
      }));
      return { data: mappedVideos, page, limit, source: 'videos' };
    }

    // Fallback: pure popularity ranking of posts if no videos exist
    const posts = await this.prisma.post.findMany({
      where: { status: 'PUBLISHED', visibility: 'PUBLIC' },
      orderBy: [{ likesCount: 'desc' }, { createdAt: 'desc' }],
      take: limit,
      skip,
      include: {
        author: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true, avatar: { select: { url: true } } } },
          },
        },
        media: { include: { file: true } },
      },
    });

    return { data: posts, page, limit, source: 'popular' };
  }

  async recordInteraction(
    userId: string,
    entityType: string,
    entityId: string,
    eventType: string,
    value = 1.0,
  ) {
    return this.prisma.recommendationEvent.create({
      data: { userId, entityType, entityId, eventType, value },
    });
  }
}
