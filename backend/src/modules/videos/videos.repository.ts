// src/modules/videos/videos.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { VideoStatus, VideoVisibility } from '@prisma/client';

const VIDEO_INCLUDE = {
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
    orderBy: { height: 'asc' as const },
  },
  chapters: {
    select: { id: true, title: true, startTimeMs: true, order: true },
    orderBy: { order: 'asc' as const },
  },
  sourceFile: {
    select: { id: true, url: true, storageKey: true },
  },
} as const;

@Injectable()
export class VideosRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(data: {
    videoChannelId: string;
    uploadedById: string;
    title: string;
    slug: string;
    description?: string;
    visibility?: VideoVisibility;
    categories?: string[];
    tags?: string[];
    hashtags?: string[];
    seoTitle?: string;
    seoDescription?: string;
    downloadPermission?: any;
    isDownloadable?: boolean;
  }) {
    return this.prisma.video.create({
      data: {
        videoChannelId: data.videoChannelId,
        uploadedById: data.uploadedById,
        title: data.title,
        slug: data.slug,
        description: data.description,
        visibility: data.visibility ?? VideoVisibility.PRIVATE,
        categories: data.categories ?? [],
        tags: data.tags ?? [],
        hashtags: data.hashtags ?? [],
        seoTitle: data.seoTitle,
        seoDescription: data.seoDescription,
        downloadPermission: data.downloadPermission,
        isDownloadable: data.isDownloadable ?? false,
        status: VideoStatus.UPLOADING,
      },
      include: VIDEO_INCLUDE,
    });
  }

  async findById(id: string) {
    return this.prisma.video.findUnique({
      where: { id, deletedAt: null },
      include: VIDEO_INCLUDE,
    });
  }

  async findBySlug(slug: string) {
    return this.prisma.video.findUnique({
      where: { slug },
      include: VIDEO_INCLUDE,
    });
  }

  async findByChannel(
    videoChannelId: string,
    opts: {
      page?: number;
      limit?: number;
      cursor?: string;
      status?: VideoStatus;
      visibility?: VideoVisibility;
      search?: string;
    },
  ) {
    const limit = opts.limit ?? 20;
    const skip = opts.cursor ? 1 : opts.page ? (opts.page - 1) * limit : 0;

    const where = {
      videoChannelId,
      deletedAt: null,
      ...(opts.status ? { status: opts.status } : {}),
      ...(opts.visibility ? { visibility: opts.visibility } : {}),
      ...(opts.search
        ? {
            OR: [
              {
                title: { contains: opts.search, mode: 'insensitive' as const },
              },
              {
                description: {
                  contains: opts.search,
                  mode: 'insensitive' as const,
                },
              },
            ],
          }
        : {}),
    };

    const videos = await this.prisma.video.findMany({
      where,
      ...(opts.cursor ? { cursor: { id: opts.cursor }, skip: 1 } : { skip }),
      take: limit + 1,
      orderBy: { createdAt: 'desc' },
      include: VIDEO_INCLUDE,
    });

    const total = await this.prisma.video.count({ where });
    const hasMore = videos.length > limit;
    const data = hasMore ? videos.slice(0, limit) : videos;
    const nextCursor = hasMore ? data[data.length - 1].id : undefined;

    return { data, total, nextCursor, hasMore };
  }

  async findByUser(
    userId: string,
    opts: {
      page?: number;
      limit?: number;
      cursor?: string;
      isStream?: boolean;
    },
  ) {
    const limit = opts.limit ?? 20;
    const skip = opts.cursor ? 1 : opts.page ? (opts.page - 1) * limit : 0;

    const streamCondition = {
      OR: [
        { slug: { startsWith: 'vod-' } },
        {
          description: {
            contains: 'Recorded live stream',
            mode: 'insensitive' as const,
          },
        },
        { hlsUrl: { contains: '/streams/', mode: 'insensitive' as const } },
      ],
    };

    const where: any = {
      uploadedById: userId,
      deletedAt: null,
    };

    if (opts.isStream === true) {
      where.OR = streamCondition.OR;
    } else if (opts.isStream === false) {
      where.NOT = streamCondition;
    }

    const videos = await this.prisma.video.findMany({
      where,
      ...(opts.cursor ? { cursor: { id: opts.cursor }, skip: 1 } : { skip }),
      take: limit + 1,
      orderBy: { createdAt: 'desc' },
      include: VIDEO_INCLUDE,
    });

    const total = await this.prisma.video.count({ where });
    const hasMore = videos.length > limit;
    const data = hasMore ? videos.slice(0, limit) : videos;
    const nextCursor = hasMore ? data[data.length - 1].id : undefined;

    return { data, total, nextCursor, hasMore };
  }

  async findPublicVideos(opts: {
    page?: number;
    limit?: number;
    cursor?: string;
    search?: string;
    category?: string;
  }) {
    const limit = opts.limit ?? 20;
    const skip = opts.cursor ? 1 : opts.page ? (opts.page - 1) * limit : 0;

    const where = {
      status: VideoStatus.READY,
      visibility: VideoVisibility.PUBLIC,
      deletedAt: null,
      ...(opts.search
        ? {
            OR: [
              {
                title: { contains: opts.search, mode: 'insensitive' as const },
              },
              { hashtags: { has: opts.search } },
            ],
          }
        : {}),
      ...(opts.category ? { categories: { has: opts.category } } : {}),
    };

    const videos = await this.prisma.video.findMany({
      where,
      ...(opts.cursor ? { cursor: { id: opts.cursor }, skip: 1 } : { skip }),
      take: limit + 1,
      orderBy: { viewsCount: 'desc' },
      include: VIDEO_INCLUDE,
    });

    const total = await this.prisma.video.count({ where });
    const hasMore = videos.length > limit;
    const data = hasMore ? videos.slice(0, limit) : videos;
    const nextCursor = hasMore ? data[data.length - 1].id : undefined;

    return { data, total, nextCursor, hasMore };
  }

  async update(id: string, data: Record<string, any>) {
    return this.prisma.video.update({
      where: { id },
      data,
      include: VIDEO_INCLUDE,
    });
  }

  async softDelete(id: string) {
    return this.prisma.video.update({
      where: { id },
      data: { deletedAt: new Date(), status: VideoStatus.DELETED },
    });
  }

  async updateStatus(id: string, status: VideoStatus) {
    return this.prisma.video.update({ where: { id }, data: { status } });
  }

  async setSourceFile(id: string, fileId: string) {
    return this.prisma.video.update({
      where: { id },
      data: { sourceFileId: fileId, status: VideoStatus.QUEUED },
    });
  }

  async setProcessingResult(
    id: string,
    data: {
      duration?: number;
      width?: number;
      height?: number;
      bitrate?: number;
      videoCodec?: string;
      audioCodec?: string;
      thumbnailUrl?: string;
      hlsUrl?: string;
      status: VideoStatus;
    },
  ) {
    return this.prisma.video.update({ where: { id }, data });
  }

  async createRendition(data: {
    videoId: string;
    resolution: any;
    height: number;
    width: number;
    bitrate: number;
    fileSize: bigint;
    storageKey: string;
    url: string;
    provider: any;
  }) {
    return this.prisma.videoRendition.create({ data });
  }

  async incrementViews(id: string) {
    return this.prisma.video.update({
      where: { id },
      data: { viewsCount: { increment: 1 } },
    });
  }

  async updateLikeCounts(id: string) {
    const [likes, dislikes] = await this.prisma.$transaction([
      this.prisma.videoLike.count({ where: { videoId: id, isLike: true } }),
      this.prisma.videoLike.count({ where: { videoId: id, isLike: false } }),
    ]);
    return this.prisma.video.update({
      where: { id },
      data: { likesCount: likes, dislikesCount: dislikes },
    });
  }

  async upsertLike(userId: string, videoId: string, isLike: boolean) {
    return this.prisma.videoLike.upsert({
      where: { userId_videoId: { userId, videoId } },
      create: { userId, videoId, isLike },
      update: { isLike },
    });
  }

  async removeLike(userId: string, videoId: string) {
    return this.prisma.videoLike.deleteMany({ where: { userId, videoId } });
  }

  async getUserLike(userId: string, videoId: string) {
    return this.prisma.videoLike.findUnique({
      where: { userId_videoId: { userId, videoId } },
    });
  }

  async upsertWatchProgress(data: {
    userId: string;
    videoId: string;
    watchedSeconds: number;
    watchedPercent: number;
    isCompleted: boolean;
  }) {
    return this.prisma.videoWatchHistory.upsert({
      where: { userId_videoId: { userId: data.userId, videoId: data.videoId } },
      create: {
        userId: data.userId,
        videoId: data.videoId,
        watchedSeconds: data.watchedSeconds,
        watchedPercent: data.watchedPercent,
        isCompleted: data.isCompleted,
      },
      update: {
        watchedSeconds: data.watchedSeconds,
        watchedPercent: data.watchedPercent,
        isCompleted: data.isCompleted,
        watchedAt: new Date(),
      },
    });
  }

  async getWatchHistory(userId: string, page: number, limit: number) {
    const skip = (page - 1) * limit;
    const [data, total] = await this.prisma.$transaction([
      this.prisma.videoWatchHistory.findMany({
        where: { userId },
        include: {
          video: {
            select: {
              id: true,
              title: true,
              slug: true,
              thumbnailUrl: true,
              duration: true,
              status: true,
              visibility: true,
              videoChannel: { select: { id: true, name: true, handle: true } },
            },
          },
        },
        skip,
        take: limit,
        orderBy: { watchedAt: 'desc' },
      }),
      this.prisma.videoWatchHistory.count({ where: { userId } }),
    ]);
    return { data, total };
  }

  async getWatchProgress(userId: string, videoId: string) {
    return this.prisma.videoWatchHistory.findUnique({
      where: { userId_videoId: { userId, videoId } },
    });
  }

  async upsertBookmark(userId: string, videoId: string, note?: string) {
    return this.prisma.videoBookmark.upsert({
      where: { userId_videoId: { userId, videoId } },
      create: { userId, videoId, note },
      update: { note },
    });
  }

  async removeBookmark(userId: string, videoId: string) {
    return this.prisma.videoBookmark.delete({
      where: { userId_videoId: { userId, videoId } },
    });
  }

  async removeFromWatchHistory(userId: string, videoId: string) {
    return this.prisma.videoWatchHistory.deleteMany({
      where: { userId, videoId },
    });
  }

  async clearWatchHistory(userId: string) {
    return this.prisma.videoWatchHistory.deleteMany({
      where: { userId },
    });
  }

  async getLikedVideos(userId: string, page: number, limit: number) {
    const skip = (page - 1) * limit;
    const [likes, total] = await this.prisma.$transaction([
      this.prisma.videoLike.findMany({
        where: { userId, isLike: true },
        include: {
          video: {
            select: {
              id: true,
              title: true,
              slug: true,
              thumbnailUrl: true,
              duration: true,
              status: true,
              viewsCount: true,
              createdAt: true,
              videoChannel: { select: { id: true, name: true, handle: true } },
            },
          },
        },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.videoLike.count({ where: { userId, isLike: true } }),
    ]);
    const data = likes.map((l) => l.video).filter(Boolean);
    return { data, total, page, limit };
  }

  async getBookmarks(userId: string, page: number, limit: number) {
    const skip = (page - 1) * limit;
    const [data, total] = await this.prisma.$transaction([
      this.prisma.videoBookmark.findMany({
        where: { userId },
        include: {
          video: {
            select: {
              id: true,
              title: true,
              slug: true,
              thumbnailUrl: true,
              duration: true,
              status: true,
              viewsCount: true,
              createdAt: true,
              videoChannel: { select: { id: true, name: true, handle: true } },
            },
          },
        },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.videoBookmark.count({ where: { userId } }),
    ]);
    return { data: data.map((b) => b.video).filter(Boolean), total, page, limit };
  }

  async getTrending(limit = 20) {
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    return this.prisma.video.findMany({
      where: {
        status: VideoStatus.READY,
        visibility: VideoVisibility.PUBLIC,
        deletedAt: null,
        OR: [
          { publishedAt: { gte: sevenDaysAgo } },
          { publishedAt: null, createdAt: { gte: sevenDaysAgo } },
        ],
      },
      orderBy: [{ viewsCount: 'desc' }, { likesCount: 'desc' }],
      take: limit,
      include: VIDEO_INCLUDE,
    });
  }

  async getLatest(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const where = {
      status: VideoStatus.READY,
      visibility: VideoVisibility.PUBLIC,
      deletedAt: null,
    };

    const videos = await this.prisma.video.findMany({
      where,
      skip,
      take: limit + 1,
      orderBy: { createdAt: 'desc' },
      include: VIDEO_INCLUDE,
    });

    const total = await this.prisma.video.count({ where });
    const hasMore = videos.length > limit;
    const data = hasMore ? videos.slice(0, limit) : videos;
    const nextCursor = hasMore ? data[data.length - 1].id : undefined;

    return { data, total, nextCursor, hasMore, page, limit };
  }


  async getRecommended(userId: string, videoId: string, limit = 10) {
    // Get the video's categories and tags for recommendation
    const video = await this.prisma.video.findUnique({
      where: { id: videoId },
      select: { categories: true, tags: true, videoChannelId: true },
    });

    if (!video) return [];

    return this.prisma.video.findMany({
      where: {
        status: VideoStatus.READY,
        visibility: VideoVisibility.PUBLIC,
        deletedAt: null,
        id: { not: videoId },
        OR: [
          { categories: { hasSome: video.categories } },
          { tags: { hasSome: video.tags } },
          { videoChannelId: video.videoChannelId },
        ],
      },
      orderBy: { viewsCount: 'desc' },
      take: limit,
      include: VIDEO_INCLUDE,
    });
  }

  async reportVideo(data: {
    videoId: string;
    userId: string;
    reason: any;
    details?: string;
  }) {
    return this.prisma.videoReport.upsert({
      where: { videoId_userId: { videoId: data.videoId, userId: data.userId } },
      create: data,
      update: { reason: data.reason, details: data.details },
    });
  }
}
