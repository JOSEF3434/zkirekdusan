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

    // Fallback: pure popularity ranking
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
