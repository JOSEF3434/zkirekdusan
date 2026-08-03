import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class TrendingService {
  constructor(private readonly prisma: PrismaService) {}

  async getTrending(entityType: string, page: number, limit: number) {
    const skip = (page - 1) * limit;

    const scores = await this.prisma.trendingScore.findMany({
      where: { entityType, window: 'DAILY' },
      orderBy: { score: 'desc' },
      take: limit,
      skip,
    });

    if (scores.length === 0 && entityType === 'POSTS') {
      // Fallback
      const posts = await this.prisma.post.findMany({
        where: { status: 'PUBLISHED', visibility: 'PUBLIC' },
        orderBy: { likesCount: 'desc' },
        take: limit,
        skip,
        include: {
          author: {
            select: {
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
      });
      return { data: posts, page, limit };
    }

    return { data: scores, page, limit };
  }
}
