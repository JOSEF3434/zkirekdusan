import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class SearchRepository {
  constructor(private readonly prisma: PrismaService) {}

  async searchUsers(query: string, limit: number, skip: number) {
    const users = await this.prisma.user.findMany({
      where: {
        status: 'ACTIVE',
        OR: [
          { username: { contains: query, mode: 'insensitive' } },
          { profile: { displayName: { contains: query, mode: 'insensitive' } } },
          { profile: { firstName: { contains: query, mode: 'insensitive' } } },
          { profile: { lastName: { contains: query, mode: 'insensitive' } } },
        ],
      },
      select: {
        id: true,
        username: true,
        profile: {
          select: {
            displayName: true,
            firstName: true,
            lastName: true,
            avatar: { select: { url: true } },
          },
        },
      },
      take: limit,
      skip,
    });

    return users.map((u) => ({
      id: u.id,
      username: u.username,
      profile: {
        displayName:
          u.profile?.displayName ||
          [u.profile?.firstName, u.profile?.lastName].filter(Boolean).join(' ') ||
          u.username,
        avatar: u.profile?.avatar,
      },
    }));
  }

  async searchGroups(query: string, limit: number, skip: number) {
    return this.prisma.group.findMany({
      where: {
        deletedAt: null,
        status: 'ACTIVE',
        visibility: 'PUBLIC',
        OR: [
          { name: { contains: query, mode: 'insensitive' } },
          { description: { contains: query, mode: 'insensitive' } },
          { slug: { contains: query, mode: 'insensitive' } },
        ],
      },
      select: {
        id: true,
        name: true,
        slug: true,
        avatarUrl: true,
        description: true,
      },
      take: limit,
      skip,
    });
  }

  async searchPosts(query: string, limit: number, skip: number) {
    return this.prisma.post.findMany({
      where: {
        deletedAt: null,
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
    const rawVideos = await this.prisma.video.findMany({
      where: {
        deletedAt: null,
        status: 'READY',
        visibility: 'PUBLIC',
        OR: [
          { title: { contains: query, mode: 'insensitive' } },
          { description: { contains: query, mode: 'insensitive' } },
          { tags: { has: query } },
          { hashtags: { has: query } },
        ],
      },
      include: {
        videoChannel: {
          select: {
            id: true,
            name: true,
            handle: true,
            avatarFile: { select: { url: true } },
          },
        },
        uploadedBy: {
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
        renditions: {
          select: {
            id: true,
            quality: true,
            resolution: true,
            bitrate: true,
            format: true,
            status: true,
            url: true,
            createdAt: true,
          },
        },
      },
      orderBy: [
        { viewsCount: 'desc' },
        { createdAt: 'desc' },
      ],
      take: limit,
      skip,
    });

    return rawVideos.map((v) => ({
      ...v,
      viewsCount: Number(v.viewsCount),
      likesCount: Number(v.likesCount ?? 0),
      commentsCount: Number(v.commentsCount ?? 0),
      channelId: v.videoChannel?.id,
      channelName: v.videoChannel?.name,
      author: {
        id: v.uploadedBy?.id,
        username: v.uploadedBy?.username,
        displayName: v.uploadedBy?.profile?.displayName,
        avatarUrl: v.uploadedBy?.profile?.avatar?.url,
      },
    }));
  }

  async searchChannels(query: string, limit: number, skip: number) {
    return this.prisma.videoChannel.findMany({
      where: {
        deletedAt: null,
        status: 'ACTIVE',
        visibility: 'PUBLIC',
        OR: [
          { name: { contains: query, mode: 'insensitive' } },
          { handle: { contains: query, mode: 'insensitive' } },
          { description: { contains: query, mode: 'insensitive' } },
        ],
      },
      select: {
        id: true,
        name: true,
        handle: true,
        description: true,
        avatarFile: { select: { url: true } },
        subscribersCount: true,
      },
      take: limit,
      skip,
    });
  }

  async searchReels(query: string, limit: number, skip: number) {
    const rawReels = await this.prisma.reel.findMany({
      where: {
        deletedAt: null,
        status: 'PUBLISHED',
        visibility: 'PUBLIC',
        caption: { contains: query, mode: 'insensitive' },
      },
      select: {
        id: true,
        caption: true,
        thumbnailUrl: true,
        viewsCount: true,
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
      take: limit,
      skip,
      orderBy: { viewsCount: 'desc' },
    });

    return rawReels.map((r) => ({
      ...r,
      description: r.caption,
    }));
  }

  async searchLiveStreams(query: string, limit: number, skip: number) {
    return this.prisma.liveStream.findMany({
      where: {
        deletedAt: null,
        title: { contains: query, mode: 'insensitive' },
        visibility: 'PUBLIC',
        status: { in: ['LIVE', 'SCHEDULED'] },
      },
      select: {
        id: true,
        title: true,
        status: true,
        currentViewerCount: true,
        scheduledAt: true,
        createdBy: {
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
      take: limit,
      skip,
      orderBy: [
        { status: 'asc' }, // LIVE before SCHEDULED
        { currentViewerCount: 'desc' },
      ],
    });
  }

  async recordSearchHistory(
    userId: string,
    query: string,
    entityType?: string,
  ) {
    try {
      return await this.prisma.searchHistory.create({
        data: {
          userId,
          query,
          entityType,
        },
      });
    } catch {
      return null;
    }
  }
}
