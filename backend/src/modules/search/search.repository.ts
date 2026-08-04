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
