import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class SearchRepository {
  constructor(private readonly prisma: PrismaService) {}

  async searchUsers(query: string, limit: number, skip: number) {
    // Simple basic search for users
    return this.prisma.user.findMany({
      where: {
        OR: [
          { username: { contains: query, mode: 'insensitive' } },
          {
            profile: { displayName: { contains: query, mode: 'insensitive' } },
          },
        ],
        status: 'ACTIVE',
      },
      select: {
        id: true,
        username: true,
        profile: {
          select: { displayName: true, avatar: { select: { url: true } } },
        },
      },
      take: limit,
      skip,
    });
  }

  async searchGroups(query: string, limit: number, skip: number) {
    return this.prisma.group.findMany({
      where: {
        OR: [
          { name: { contains: query, mode: 'insensitive' } },
          { description: { contains: query, mode: 'insensitive' } },
        ],
        status: 'ACTIVE',
        visibility: 'PUBLIC',
      },
      select: {
        id: true,
        name: true,
        slug: true,
        avatarUrl: true,
      },
      take: limit,
      skip,
    });
  }

  async searchPosts(query: string, limit: number, skip: number) {
    return this.prisma.post.findMany({
      where: {
        content: { contains: query, mode: 'insensitive' },
        status: 'PUBLISHED',
        visibility: 'PUBLIC',
      },
      select: {
        id: true,
        content: true,
        author: {
          select: {
            username: true,
            profile: {
              select: { displayName: true, avatar: { select: { url: true } } },
            },
          },
        },
      },
      take: limit,
      skip,
    });
  }

  async searchVideos(query: string, limit: number, skip: number) {
    // Implementing PostgreSQL FTS query for videos as requested
    const searchTerms = query.trim().split(/\s+/).join(' | ');
    if (!searchTerms) return [];

    // Using raw query for FTS on title and description
    // to_tsvector('english', title || ' ' || coalesce(description, '')) @@ to_tsquery('english', $1)
    const videos = await this.prisma.$queryRaw`
      SELECT id, title, description, slug, "thumbnailUrl", "viewsCount"
      FROM videos
      WHERE 
        status = 'READY' AND 
        visibility = 'PUBLIC' AND
        (to_tsvector('english', title || ' ' || coalesce(description, '')) @@ to_tsquery('english', ${searchTerms})
         OR title ILIKE ${'%' + query + '%'})
      ORDER BY "viewsCount" DESC, "createdAt" DESC
      LIMIT ${limit} OFFSET ${skip}
    `;

    return videos;
  }

  async searchReels(query: string, limit: number, skip: number) {
    return this.prisma.reel.findMany({
      where: {
        description: { contains: query, mode: 'insensitive' },
        visibility: 'PUBLIC',
      },
      select: {
        id: true,
        description: true,
        thumbnailUrl: true,
        viewsCount: true,
        author: {
          select: { username: true }
        }
      },
      take: limit,
      skip,
      orderBy: { viewsCount: 'desc' },
    });
  }

  async searchLiveStreams(query: string, limit: number, skip: number) {
    return this.prisma.liveStream.findMany({
      where: {
        title: { contains: query, mode: 'insensitive' },
        visibility: 'PUBLIC',
        status: { in: ['LIVE', 'SCHEDULED'] }
      },
      select: {
        id: true,
        title: true,
        status: true,
        currentViewerCount: true,
        scheduledAt: true,
        createdBy: { select: { username: true } }
      },
      take: limit,
      skip,
      orderBy: [
        { status: 'asc' }, // LIVE before SCHEDULED
        { currentViewerCount: 'desc' }
      ]
    });
  }

  async recordSearchHistory(
    userId: string,
    query: string,
    entityType?: string,
  ) {
    return this.prisma.searchHistory.create({
      data: {
        userId,
        query,
        entityType,
      },
    });
  }
}
