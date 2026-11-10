import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { BookStatus, DictionaryProcessingStatus } from '@prisma/client';

@Injectable()
export class SearchRepository {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Returns all user IDs that the requester has blocked OR who have blocked the requester.
   */
  async getBlockedUserIds(requesterId?: string): Promise<string[]> {
    if (!requesterId) return [];
    const blocks = await this.prisma.conversationBlock.findMany({
      where: {
        OR: [{ blockerId: requesterId }, { blockedUserId: requesterId }],
      },
      select: { blockerId: true, blockedUserId: true },
    });
    const set = new Set<string>();
    for (const b of blocks) {
      if (b.blockerId !== requesterId) set.add(b.blockerId);
      if (b.blockedUserId !== requesterId) set.add(b.blockedUserId);
    }
    return Array.from(set);
  }

  /**
   * Sanitizes legacy loopback URLs to public production URL if stored in old rows.
   */
  private sanitizeUrl(url: string | null | undefined): string | null {
    if (!url) return null;
    const renderHost =
      process.env.APP_URL?.replace(/\/+$/, '') ||
      'https://zikrekidusan.onrender.com';
    const localPatterns = [
      /^http:\/\/localhost:\d+/,
      /^http:\/\/127\.0\.0\.1:\d+/,
      /^http:\/\/0\.0\.0\.0:\d+/,
      /^http:\/\/10\.0\.2\.2:\d+/,
    ];
    for (const p of localPatterns) {
      if (p.test(url)) return url.replace(p, renderHost);
    }
    return url;
  }

  async searchUsers(
    query: string,
    limit: number,
    skip: number,
    opts?: {
      requesterId?: string;
      blockedIds?: string[];
      excludeSelf?: boolean;
    },
  ) {
    const cleanQ = query.trim();
    const blocked = opts?.blockedIds ?? (await this.getBlockedUserIds(opts?.requesterId));
    const excludeIds = new Set<string>(blocked);
    if (opts?.excludeSelf && opts?.requesterId) {
      excludeIds.add(opts.requesterId);
    }

    const where: any = {
      status: 'ACTIVE',
      ...(excludeIds.size > 0 ? { id: { notIn: Array.from(excludeIds) } } : {}),
      // Respect profile privacy: exclude PRIVATE accounts unless viewing own profile
      OR: [
        { profile: { is: { visibility: { not: 'PRIVATE' } } } },
        { profile: null },
        ...(opts?.requesterId ? [{ id: opts.requesterId }] : []),
      ],
    };

    if (cleanQ) {
      where.AND = [
        {
          OR: [
            { username: { contains: cleanQ, mode: 'insensitive' } },
            {
              profile: {
                is: { displayName: { contains: cleanQ, mode: 'insensitive' } },
              },
            },
            {
              profile: {
                is: { firstName: { contains: cleanQ, mode: 'insensitive' } },
              },
            },
            {
              profile: {
                is: { lastName: { contains: cleanQ, mode: 'insensitive' } },
              },
            },
          ],
        },
      ];
    }

    const users = await this.prisma.user.findMany({
      where,
      select: {
        id: true,
        username: true,
        profile: {
          select: {
            displayName: true,
            firstName: true,
            lastName: true,
            bio: true,
            isVerified: true,
            avatar: { select: { url: true } },
          },
        },
      },
      orderBy: [{ username: 'asc' }],
      take: limit,
      skip,
    });

    return users.map((u) => {
      const displayName =
        u.profile?.displayName ||
        [u.profile?.firstName, u.profile?.lastName].filter(Boolean).join(' ') ||
        u.username ||
        'User';
      return {
        id: u.id,
        username: u.username,
        displayName,
        isVerified: u.profile?.isVerified ?? false,
        avatarUrl: u.profile?.avatar?.url ?? null,
        profile: {
          displayName,
          isVerified: u.profile?.isVerified ?? false,
          avatar: u.profile?.avatar,
        },
      };
    });
  }

  async searchGroups(
    query: string,
    limit: number,
    skip: number,
    requesterId?: string,
  ) {
    const cleanQ = query.trim();

    const visibilityOr: any[] = [{ visibility: 'PUBLIC' }];
    if (requesterId) {
      visibilityOr.push({
        visibility: 'PRIVATE',
        members: { some: { userId: requesterId, removedAt: null } },
      });
    }

    const where: any = {
      deletedAt: null,
      status: 'ACTIVE',
      AND: [{ OR: visibilityOr }],
    };

    if (cleanQ) {
      where.AND.push({
        OR: [
          { name: { contains: cleanQ, mode: 'insensitive' } },
          { slug: { contains: cleanQ, mode: 'insensitive' } },
          { description: { contains: cleanQ, mode: 'insensitive' } },
        ],
      });
    }

    const groups = await this.prisma.group.findMany({
      where,
      select: {
        id: true,
        name: true,
        slug: true,
        avatarUrl: true,
        description: true,
        visibility: true,
        _count: {
          select: { members: { where: { removedAt: null } } },
        },
      },
      orderBy: [{ name: 'asc' }],
      take: limit,
      skip,
    });

    return groups.map((g) => ({
      id: g.id,
      name: g.name,
      slug: g.slug,
      avatarUrl: g.avatarUrl,
      description: g.description,
      visibility: g.visibility,
      membersCount: g._count?.members ?? 0,
    }));
  }

  async searchChannels(
    query: string,
    limit: number,
    skip: number,
    requesterId?: string,
  ) {
    const cleanQ = query.trim();

    const visibilityOr: any[] = [{ visibility: 'PUBLIC' }];
    if (requesterId) {
      visibilityOr.push({
        group: {
          members: { some: { userId: requesterId, removedAt: null } },
        },
      });
    }

    const where: any = {
      deletedAt: null,
      status: 'ACTIVE',
      AND: [{ OR: visibilityOr }],
    };

    if (cleanQ) {
      where.AND.push({
        OR: [
          { name: { contains: cleanQ, mode: 'insensitive' } },
          { handle: { contains: cleanQ, mode: 'insensitive' } },
          { slug: { contains: cleanQ, mode: 'insensitive' } },
          { description: { contains: cleanQ, mode: 'insensitive' } },
        ],
      });
    }

    return this.prisma.videoChannel.findMany({
      where,
      select: {
        id: true,
        name: true,
        handle: true,
        slug: true,
        description: true,
        isVerified: true,
        avatarFile: { select: { url: true } },
        subscribersCount: true,
        videosCount: true,
      },
      orderBy: [{ subscribersCount: 'desc' }, { name: 'asc' }],
      take: limit,
      skip,
    });
  }

  async searchPosts(
    query: string,
    limit: number,
    skip: number,
    opts?: { requesterId?: string; blockedIds?: string[] },
  ) {
    const cleanQ = query.trim();
    const blocked =
      opts?.blockedIds ?? (await this.getBlockedUserIds(opts?.requesterId));

    const visibilityOr: any[] = [{ visibility: 'PUBLIC' }];
    if (opts?.requesterId) {
      visibilityOr.push({
        visibility: 'GROUP_ONLY',
        group: {
          members: { some: { userId: opts.requesterId, removedAt: null } },
        },
      });
    }

    const posts = await this.prisma.post.findMany({
      where: {
        deletedAt: null,
        status: 'PUBLISHED',
        ...(blocked.length > 0 ? { authorId: { notIn: blocked } } : {}),
        AND: [
          { OR: visibilityOr },
          ...(cleanQ
            ? [
                {
                  OR: [
                    { content: { contains: cleanQ, mode: 'insensitive' } },
                    { hashtags: { has: cleanQ.toLowerCase() } },
                  ],
                },
              ]
            : []),
        ],
      },
      select: {
        id: true,
        type: true,
        visibility: true,
        content: true,
        hashtags: true,
        likesCount: true,
        commentsCount: true,
        viewsCount: true,
        groupId: true,
        createdAt: true,
        updatedAt: true,
        author: {
          select: {
            id: true,
            username: true,
            profile: {
              select: { displayName: true, avatar: { select: { url: true } } },
            },
          },
        },
        media: {
          select: {
            order: true,
            file: { select: { id: true, url: true, fileType: true } },
          },
          orderBy: { order: 'asc' },
          take: 1,
        },
      },
      orderBy: [{ likesCount: 'desc' }, { createdAt: 'desc' }],
      take: limit,
      skip,
    });

    return posts.map((p) => ({
      id: p.id,
      type: p.type,
      visibility: p.visibility,
      content: p.content,
      hashtags: p.hashtags ?? [],
      likesCount: p.likesCount ?? 0,
      commentsCount: p.commentsCount ?? 0,
      viewsCount: p.viewsCount ?? 0,
      groupId: p.groupId,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
      thumbnailUrl: p.media?.[0]?.file?.url ?? null,
      author: {
        id: p.author.id,
        username: p.author.username,
        displayName: p.author.profile?.displayName ?? p.author.username,
        avatarUrl: p.author.profile?.avatar?.url ?? null,
      },
    }));
  }

  async searchVideos(
    query: string,
    limit: number,
    skip: number,
    opts?: { requesterId?: string; blockedIds?: string[] },
  ) {
    const cleanQ = query.trim();
    const blocked =
      opts?.blockedIds ?? (await this.getBlockedUserIds(opts?.requesterId));

    // Visibility policy:
    // - Ready + PUBLIC videos are visible to all users
    // - Authenticated uploaders can also find their own READY/PROCESSING videos
    // - Authenticated group members can find GROUP_ONLY READY videos
    // - UNLISTED & unauthorized PRIVATE/SCHEDULED videos are NEVER exposed in search
    const accessOr: any[] = [{ status: 'READY', visibility: 'PUBLIC' }];
    if (opts?.requesterId) {
      accessOr.push({
        uploadedById: opts.requesterId,
        status: { in: ['READY', 'UPLOADING', 'QUEUED', 'PROCESSING'] },
        visibility: { in: ['PUBLIC', 'GROUP_ONLY'] },
      });
      accessOr.push({
        status: 'READY',
        visibility: 'GROUP_ONLY',
        videoChannel: {
          group: {
            members: { some: { userId: opts.requesterId, removedAt: null } },
          },
        },
      });
    }

    const rawVideos = await this.prisma.video.findMany({
      where: {
        deletedAt: null,
        ...(blocked.length > 0 ? { uploadedById: { notIn: blocked } } : {}),
        AND: [
          { OR: accessOr },
          ...(cleanQ
            ? [
                {
                  OR: [
                    { title: { contains: cleanQ, mode: 'insensitive' } },
                    { description: { contains: cleanQ, mode: 'insensitive' } },
                    { seoTitle: { contains: cleanQ, mode: 'insensitive' } },
                    { tags: { has: cleanQ } },
                    { hashtags: { has: cleanQ } },
                  ],
                },
              ]
            : []),
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
        sourceFile: {
          select: { id: true, url: true },
        },
        thumbnailFile: {
          select: { id: true, url: true },
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
            createdAt: true,
          },
          orderBy: { height: 'asc' },
        },
      },
      orderBy: [{ viewsCount: 'desc' }, { createdAt: 'desc' }],
      take: limit,
      skip,
    });

    return rawVideos.map((v) => {
      const thumb =
        this.sanitizeUrl(v.thumbnailUrl) ||
        this.sanitizeUrl(v.thumbnailFile?.url) ||
        null;
      const hls = this.sanitizeUrl(v.hlsUrl || v.sourceFile?.url || null);
      const srcUrl = this.sanitizeUrl(v.sourceFile?.url || null);

      return {
        id: v.id,
        title: v.title,
        description: v.description,
        slug: v.slug,
        status: v.status,
        visibility: v.visibility,
        duration: v.duration ?? 0,
        thumbnailUrl: thumb,
        previewUrl: this.sanitizeUrl(v.previewUrl),
        hlsUrl: hls,
        sourceFileUrl: srcUrl,
        dashUrl: this.sanitizeUrl(v.dashUrl),
        downloadPermission: v.downloadPermission,
        isDownloadable: v.isDownloadable,
        viewsCount: Number(v.viewsCount ?? 0),
        likesCount: Number(v.likesCount ?? 0),
        commentsCount: Number(v.commentsCount ?? 0),
        publishedAt: v.publishedAt,
        createdAt: v.createdAt,
        updatedAt: v.updatedAt,
        channelId: v.videoChannel?.id ?? v.videoChannelId,
        channelName: v.videoChannel?.name ?? null,
        videoChannel: v.videoChannel,
        renditions: (v.renditions ?? []).map((r) => ({
          id: r.id,
          quality: r.resolution?.replace('R_', '') ?? '',
          resolution: r.height ?? 0,
          resolutionLabel: r.resolution,
          bitrate: r.bitrate ?? 0,
          format: 'HLS',
          status: r.isReady ? 'READY' : 'PROCESSING',
          url: this.sanitizeUrl(r.url) ?? r.url,
          createdAt: r.createdAt,
        })),
        author: {
          id: v.uploadedBy?.id ?? '',
          username: v.uploadedBy?.username ?? null,
          displayName:
            v.uploadedBy?.profile?.displayName ??
            v.uploadedBy?.username ??
            null,
          avatarUrl: v.uploadedBy?.profile?.avatar?.url ?? null,
        },
      };
    });
  }

  async searchBooks(query: string, limit: number, skip: number) {
    const cleanQ = query.trim();

    const where: any = {
      deletedAt: null,
      status: BookStatus.PUBLISHED,
      AND: [
        {
          OR: [
            { isDictionary: false },
            {
              isDictionary: true,
              dictionaryConfig: {
                is: { processingStatus: DictionaryProcessingStatus.READY },
              },
            },
          ],
        },
      ],
    };

    if (cleanQ) {
      where.AND.push({
        OR: [
          { title: { contains: cleanQ, mode: 'insensitive' } },
          { titleAm: { contains: cleanQ, mode: 'insensitive' } },
          { titleGez: { contains: cleanQ, mode: 'insensitive' } },
          { subtitle: { contains: cleanQ, mode: 'insensitive' } },
          { author: { contains: cleanQ, mode: 'insensitive' } },
          { description: { contains: cleanQ, mode: 'insensitive' } },
          { tags: { has: cleanQ } },
          {
            dictionaryConfig: {
              is: { dictionaryName: { contains: cleanQ, mode: 'insensitive' } },
            },
          },
        ],
      });
    }

    const books = await this.prisma.book.findMany({
      where,
      select: {
        id: true,
        title: true,
        titleAm: true,
        titleGez: true,
        subtitle: true,
        author: true,
        language: true,
        format: true,
        pageCount: true,
        viewsCount: true,
        bookmarksCount: true,
        isDictionary: true,
        coverFile: { select: { url: true } },
        category: { select: { id: true, name: true, nameAm: true } },
        dictionaryConfig: {
          select: {
            dictionaryName: true,
            totalEntries: true,
          },
        },
      },
      orderBy: [{ viewsCount: 'desc' }, { sortOrder: 'asc' }, { title: 'asc' }],
      take: limit,
      skip,
    });

    return books.map((b) => ({
      id: b.id,
      title: b.title,
      titleAm: b.titleAm,
      titleGez: b.titleGez,
      subtitle: b.subtitle,
      author: b.author,
      language: b.language,
      format: b.format,
      pageCount: b.pageCount,
      viewsCount: b.viewsCount,
      bookmarksCount: b.bookmarksCount,
      isDictionary: b.isDictionary,
      dictionaryName: b.dictionaryConfig?.dictionaryName ?? null,
      totalEntries: b.dictionaryConfig?.totalEntries ?? null,
      categoryName: b.category?.name ?? null,
      coverUrl: this.sanitizeUrl(b.coverFile?.url),
    }));
  }

  async searchReels(
    query: string,
    limit: number,
    skip: number,
    opts?: { blockedIds?: string[] },
  ) {
    const cleanQ = query.trim();
    const blocked = opts?.blockedIds ?? [];

    const rawReels = await this.prisma.reel.findMany({
      where: {
        deletedAt: null,
        status: 'PUBLISHED',
        visibility: 'PUBLIC',
        ...(blocked.length > 0 ? { authorId: { notIn: blocked } } : {}),
        ...(cleanQ ? { caption: { contains: cleanQ, mode: 'insensitive' } } : {}),
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
      viewsCount: Number(r.viewsCount ?? 0),
      description: r.caption,
    }));
  }

  async searchLiveStreams(query: string, limit: number, skip: number) {
    const cleanQ = query.trim();

    return this.prisma.liveStream.findMany({
      where: {
        deletedAt: null,
        ...(cleanQ
          ? {
              OR: [
                { title: { contains: cleanQ, mode: 'insensitive' } },
                { description: { contains: cleanQ, mode: 'insensitive' } },
                { tags: { has: cleanQ } },
                { hashtags: { has: cleanQ } },
              ],
            }
          : {}),
        visibility: 'PUBLIC',
        status: { in: ['LIVE', 'SCHEDULED'] },
      },
      select: {
        id: true,
        title: true,
        status: true,
        currentViewerCount: true,
        scheduledAt: true,
        thumbnailUrl: true,
        createdById: true,
        videoChannelId: true,
        thumbnailFile: { select: { url: true } },
        videoChannel: {
          select: { id: true, name: true, avatarFile: { select: { url: true } } },
        },
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
