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

    if (scores.length === 0) {
      // Fallback depending on entityType
      switch (entityType) {
        case 'POSTS': {
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
        case 'VIDEOS': {
          const videos = await this.prisma.video.findMany({
            where: { status: 'READY', visibility: 'PUBLIC' },
            orderBy: { viewsCount: 'desc' },
            take: limit,
            skip,
          });
          return { data: videos, page, limit };
        }
        case 'REELS': {
          const reels = await this.prisma.reel.findMany({
            where: { visibility: 'PUBLIC' },
            orderBy: { viewsCount: 'desc' },
            take: limit,
            skip,
          });
          return { data: reels, page, limit };
        }
        case 'STREAMS': {
          const streams = await this.prisma.liveStream.findMany({
            where: {
              visibility: 'PUBLIC',
              status: { in: ['LIVE', 'SCHEDULED'] },
            },
            orderBy: [{ status: 'asc' }, { currentViewerCount: 'desc' }],
            take: limit,
            skip,
          });
          return { data: streams, page, limit };
        }
        case 'CHANNELS': {
          const channels = await this.prisma.videoChannel.findMany({
            where: { status: 'ACTIVE' },
            orderBy: { subscribersCount: 'desc' },
            take: limit,
            skip,
          });
          return { data: channels, page, limit };
        }
      }
    }

    return { data: scores, page, limit };
  }
}
