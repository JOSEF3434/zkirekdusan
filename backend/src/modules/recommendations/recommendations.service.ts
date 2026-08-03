import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class RecommendationsService {
  constructor(private readonly prisma: PrismaService) {}

  async getHomeRecommendations(
    userId: string | undefined,
    page: number,
    limit: number,
  ) {
    const skip = (page - 1) * limit;

    // Simple chronological fallback for recommendations
    const posts = await this.prisma.post.findMany({
      where: {
        status: 'PUBLISHED',
        visibility: 'PUBLIC',
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip,
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
        media: { include: { file: true } },
      },
    });

    return { data: posts, page, limit };
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
