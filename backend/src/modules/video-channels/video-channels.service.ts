// src/modules/video-channels/video-channels.service.ts
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { VideoChannelsRepository } from './video-channels.repository.js';
import { CreateVideoChannelDto } from './dto/create-video-channel.dto.js';
import { UpdateVideoChannelDto } from './dto/update-video-channel.dto.js';
import { AppRole } from '../../common/constants/roles.js';
import { GroupRole } from '../../common/constants/group-roles.js';
import { UploadsService } from '../uploads/uploads.service.js';

@Injectable()
export class VideoChannelsService {
  constructor(
    private readonly repo: VideoChannelsRepository,
    private readonly prisma: PrismaService,
    private readonly uploadsService: UploadsService,
  ) {}

  private async verifyGroupAccess(
    groupId: string,
    userId: string,
    requiredRole: GroupRole,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { role: true },
    });
    if (!user) throw new NotFoundException('User not found');

    // SUPER_ADMIN bypasses all checks
    if (
      (user.role.name as AppRole) === AppRole.SUPER_ADMIN ||
      (user.role.name as AppRole) === AppRole.ADMIN
    ) {
      return true;
    }

    const group = await this.prisma.group.findUnique({
      where: { id: groupId, deletedAt: null },
      select: { id: true, status: true },
    });
    if (!group) throw new NotFoundException('Group not found');
    if (group.status !== 'ACTIVE')
      throw new ForbiddenException('Group is not active');

    const membership = await this.prisma.groupMember.findFirst({
      where: { groupId, userId, removedAt: null },
      select: { role: true },
    });
    if (!membership)
      throw new ForbiddenException('You are not a member of this group');

    const roleHierarchy: Record<GroupRole, number> = {
      [GroupRole.GROUP_ADMIN]: 4,
      [GroupRole.MODERATOR]: 3,
      [GroupRole.MEMBER]: 2,
      [GroupRole.GUEST]: 1,
    };

    if (
      roleHierarchy[membership.role as GroupRole] < roleHierarchy[requiredRole]
    ) {
      throw new ForbiddenException(
        `This action requires at least ${requiredRole} role`,
      );
    }
    return true;
  }

  private async verifyChannelManagement(
    channel: any,
    userId: string,
    requiredRole: GroupRole = GroupRole.GROUP_ADMIN,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { role: true },
    });
    if (!user) throw new NotFoundException('User not found');

    if (
      (user.role.name as AppRole) === AppRole.SUPER_ADMIN ||
      (user.role.name as AppRole) === AppRole.ADMIN
    ) {
      return true;
    }

    if (channel.ownerId === userId) return true;

    const mod = await this.prisma.channelModerator.findUnique({
      where: { channelId_userId: { channelId: channel.id, userId } },
    });
    if (mod) return true;

    if (channel.groupId) {
      return this.verifyGroupAccess(channel.groupId, userId, requiredRole);
    }

    throw new ForbiddenException('You do not have permission to manage this channel');
  }

  private mapChannelToDto(channel: any) {
    if (!channel) return channel;
    return {
      ...channel,
      totalViewsCount: Number(channel.totalViewsCount ?? 0),
    };
  }

  async create(groupId: string, userId: string, dto: CreateVideoChannelDto) {
    await this.verifyGroupAccess(groupId, userId, GroupRole.GROUP_ADMIN);

    // Check slug uniqueness within group
    const existing = await this.repo.findBySlugAndGroup(groupId, dto.slug);
    if (existing) {
      throw new ConflictException(
        `A channel with slug '${dto.slug}' already exists in this group`,
      );
    }

    // Check handle uniqueness globally
    const handleExists = await this.repo.findByHandle(dto.handle);
    if (handleExists) {
      throw new ConflictException(`Handle '${dto.handle}' is already taken`);
    }

    const created = await this.repo.create(groupId, dto);
    return this.mapChannelToDto(created);
  }

  async findByGroup(groupId: string, page = 1, limit = 20) {
    let { data, total } = await this.repo.findByGroup(groupId, page, limit);

    // Auto-provision primary channel for active groups if none exists
    if (data.length === 0) {
      try {
        const group = await this.prisma.group.findUnique({
          where: { id: groupId, deletedAt: null },
        });
        if (group && group.status === 'ACTIVE') {
          const baseHandle = group.slug
            .replace(/[^a-zA-Z0-9_]/g, '_')
            .toLowerCase();
          const channelHandle =
            baseHandle.length > 0
              ? baseHandle.substring(0, 24)
              : `channel_${groupId.substring(0, 8)}`;
          const autoChan = await this.repo.create(groupId, {
            name: `${group.name} Channel`,
            slug: `${group.slug}-${Date.now().toString().slice(-4)}`,
            handle: `@${channelHandle}_${Date.now().toString().slice(-4)}`,
            description: `Official video channel for ${group.name}`,
            uploadPermission: 'MEMBER' as any,
            downloadPermission: 'PUBLIC',
          });
          data = [autoChan];
          total = 1;
        }
      } catch {
        // Non-fatal if conflict occurs
      }
    }

    return {
      data: data.map((c) => this.mapChannelToDto(c)),
      total,
      page,
      limit,
    };
  }

  async findById(id: string, userId?: string) {
    const channel = await this.repo.findById(id);
    if (!channel) throw new NotFoundException('Video channel not found');
    let isSubscribed = false;
    let isOwner = false;
    if (userId) {
      isSubscribed = await this.repo.isSubscribed(userId, id);
      isOwner = channel.ownerId === userId;
    }
    return {
      ...this.mapChannelToDto(channel),
      isSubscribed,
      isOwner,
    };
  }

  async update(id: string, userId: string, dto: UpdateVideoChannelDto) {
    const channel = await this.repo.findById(id);
    if (!channel) throw new NotFoundException('Video channel not found');

    await this.verifyChannelManagement(channel, userId, GroupRole.GROUP_ADMIN);

    if (dto.handle && dto.handle !== channel.handle) {
      const handleExists = await this.repo.findByHandle(dto.handle);
      if (handleExists)
        throw new ConflictException(`Handle '${dto.handle}' is already taken`);
    }

    if (dto.slug && dto.slug !== channel.slug) {
      if (channel.groupId) {
        const slugExists = await this.repo.findBySlugAndGroup(
          channel.groupId,
          dto.slug,
        );
        if (slugExists)
          throw new ConflictException(
            `Slug '${dto.slug}' already exists in this group`,
          );
      }
    }

    const updated = await this.repo.update(id, dto);
    return this.mapChannelToDto(updated);
  }

  async delete(id: string, userId: string) {
    const channel = await this.repo.findById(id);
    if (!channel) throw new NotFoundException('Video channel not found');

    await this.verifyChannelManagement(channel, userId, GroupRole.GROUP_ADMIN);
    await this.repo.softDelete(id);
    return { message: 'Video channel deleted successfully' };
  }

  async subscribe(userId: string, channelId: string) {
    const channel = await this.repo.findById(channelId);
    if (!channel) throw new NotFoundException('Video channel not found');

    const isSubbed = await this.repo.isSubscribed(userId, channelId);
    if (isSubbed) {
      throw new BadRequestException('Already subscribed to this channel');
    }

    await this.repo.subscribe(userId, channelId);
    await this.repo.incrementSubscribers(channelId, 1);
    return { message: 'Subscribed successfully', isSubscribed: true };
  }

  async unsubscribe(userId: string, channelId: string) {
    const channel = await this.repo.findById(channelId);
    if (!channel) throw new NotFoundException('Video channel not found');

    const isSubbed = await this.repo.isSubscribed(userId, channelId);
    if (!isSubbed) {
      throw new BadRequestException('Not subscribed to this channel');
    }

    await this.repo.unsubscribe(userId, channelId);
    await this.repo.incrementSubscribers(channelId, -1);
    return { message: 'Unsubscribed successfully', isSubscribed: false };
  }

  async isSubscribed(userId: string, channelId: string): Promise<boolean> {
    if (!userId) return false;
    return this.repo.isSubscribed(userId, channelId);
  }

  async getSubscribers(channelId: string, page = 1, limit = 20) {
    const channel = await this.repo.findById(channelId);
    if (!channel) throw new NotFoundException('Video channel not found');
    return this.repo.getSubscribers(channelId, page, limit);
  }

  async getChannelAnalytics(channelId: string, userId: string) {
    const channel = await this.repo.findById(channelId);
    if (!channel) throw new NotFoundException('Video channel not found');

    await this.verifyChannelManagement(channel, userId, GroupRole.MODERATOR);

    const [totalVideos, totalViews, totalLikes, totalComments] =
      await this.prisma.$transaction([
        this.prisma.video.count({
          where: { videoChannelId: channelId, deletedAt: null },
        }),
        this.prisma.video.aggregate({
          where: { videoChannelId: channelId, deletedAt: null },
          _sum: { viewsCount: true },
        }),
        this.prisma.video.aggregate({
          where: { videoChannelId: channelId, deletedAt: null },
          _sum: { likesCount: true },
        }),
        this.prisma.video.aggregate({
          where: { videoChannelId: channelId, deletedAt: null },
          _sum: { commentsCount: true },
        }),
      ]);

    return {
      channelId,
      totalVideos,
      totalViews: totalViews._sum.viewsCount?.toString() ?? '0',
      totalLikes: totalLikes._sum.likesCount ?? 0,
      totalComments: totalComments._sum.commentsCount ?? 0,
      subscribersCount: channel.subscribersCount,
    };
  }

  async uploadAvatar(
    channelId: string,
    userId: string,
    file: Express.Multer.File,
  ) {
    const channel = await this.repo.findById(channelId);
    if (!channel) throw new NotFoundException('Video channel not found');

    await this.verifyChannelManagement(channel, userId, GroupRole.GROUP_ADMIN);
    return this.uploadsService.uploadChannelAvatar(channelId, userId, file);
  }

  async uploadBanner(
    channelId: string,
    userId: string,
    file: Express.Multer.File,
  ) {
    const channel = await this.repo.findById(channelId);
    if (!channel) throw new NotFoundException('Video channel not found');

    await this.verifyChannelManagement(channel, userId, GroupRole.GROUP_ADMIN);
    return this.uploadsService.uploadChannelBanner(channelId, userId, file);
  }

  async findUserOwnedChannels(userId: string) {
    const channels = await this.prisma.videoChannel.findMany({
      where: {
        deletedAt: null,
        OR: [
          { ownerId: userId },
          { moderators: { some: { userId } } },
          {
            group: {
              OR: [
                { createdById: userId },
                {
                  members: {
                    some: {
                      userId,
                      role: { in: [GroupRole.GROUP_ADMIN, GroupRole.MODERATOR] },
                      removedAt: null,
                    },
                  },
                },
              ],
            },
          },
        ],
      },
      include: {
        avatarFile: { select: { url: true } },
        bannerFile: { select: { url: true } },
        group: {
          select: {
            id: true,
            name: true,
            avatarUrl: true,
            createdById: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return channels.map((c) => ({
      id: c.id,
      groupId: c.groupId,
      name: c.name,
      slug: c.slug,
      handle: c.handle,
      description: c.description,
      status: c.status,
      rejectionReason: c.rejectionReason,
      avatarUrl: c.avatarFile?.url ?? c.group?.avatarUrl ?? null,
      bannerUrl: c.bannerFile?.url ?? null,
      subscribersCount: c.subscribersCount,
      videosCount: c.videosCount,
      isVerified: c.isVerified,
      isOwner: c.ownerId === userId || c.group?.createdById === userId,
      groupName: c.group?.name,
      createdAt: c.createdAt,
    }));
  }

  // ─── Standalone Channel Creation Request Workflow ─────────────────────────

  async requestChannelCreation(
    userId: string,
    dto: {
      name: string;
      handle: string;
      description?: string;
      category?: string;
      website?: string;
    },
  ) {
    let cleanHandle = dto.handle.trim();
    if (!cleanHandle.startsWith('@')) {
      cleanHandle = `@${cleanHandle}`;
    }

    const existingHandle = await this.repo.findByHandle(cleanHandle);
    if (existingHandle) {
      throw new ConflictException(`Handle '${cleanHandle}' is already taken`);
    }

    const baseSlug = dto.name
      .toLowerCase()
      .replace(/[^a-z0-9]/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '') || 'channel';
    const slug = `${baseSlug}-${Date.now().toString().slice(-6)}`;

    const channel = await this.prisma.videoChannel.create({
      data: {
        name: dto.name,
        handle: cleanHandle,
        slug,
        description: dto.description,
        ownerId: userId,
        status: 'PENDING',
        visibility: 'PUBLIC',
        categories: dto.category ? [dto.category] : [],
        website: dto.website,
      },
      include: {
        avatarFile: { select: { url: true } },
        bannerFile: { select: { url: true } },
      },
    });

    return {
      ...this.mapChannelToDto(channel),
      avatarUrl: null,
      bannerUrl: null,
      isOwner: true,
    };
  }

  // ─── Public Channel Discovery & Listing ─────────────────────────────────

  async discoverChannels(
    page = 1,
    limit = 20,
    search?: string,
    category?: string,
    userId?: string,
  ) {
    const pageNum = Math.max(1, Number(page) || 1);
    const limitNum = Math.min(50, Math.max(1, Number(limit) || 20));
    const skip = (pageNum - 1) * limitNum;

    const where: any = {
      status: { in: ['ACTIVE', 'APPROVED'] },
      deletedAt: null,
    };

    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { handle: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (category && category !== 'ALL') {
      where.categories = { has: category };
    }

    const [items, total] = await Promise.all([
      this.prisma.videoChannel.findMany({
        where,
        skip,
        take: limitNum,
        orderBy: [
          { isVerified: 'desc' },
          { subscribersCount: 'desc' },
          { createdAt: 'desc' },
        ],
        include: {
          avatarFile: { select: { url: true } },
          bannerFile: { select: { url: true } },
          owner: {
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
          ...(userId
            ? {
                subscriptions: {
                  where: { userId },
                  select: { userId: true },
                },
              }
            : {}),
        },
      }),
      this.prisma.videoChannel.count({ where }),
    ]);

    return {
      items: items.map((c: any) => ({
        id: c.id,
        groupId: c.groupId,
        name: c.name,
        slug: c.slug,
        handle: c.handle,
        description: c.description,
        status: c.status,
        avatarUrl: c.avatarFile?.url ?? null,
        bannerUrl: c.bannerFile?.url ?? null,
        subscribersCount: c.subscribersCount,
        videosCount: c.videosCount,
        isVerified: c.isVerified,
        categories: c.categories,
        isSubscribed: Boolean(c.subscriptions && c.subscriptions.length > 0),
        isOwner: c.ownerId === userId,
        createdAt: c.createdAt,
      })),
      total,
      page: pageNum,
      limit: limitNum,
      totalPages: Math.ceil(total / limitNum),
    };
  }

  // ─── Channel Community Posts ───────────────────────────────────────────

  async createCommunityPost(
    channelId: string,
    userId: string,
    dto: { title?: string; content: string; mediaUrls?: string[] },
  ) {
    const channel = await this.repo.findById(channelId);
    if (!channel) throw new NotFoundException('Channel not found');

    if (channel.status === 'PENDING') {
      throw new ForbiddenException('Channel is pending approval and cannot post yet.');
    }
    if (channel.status === 'REJECTED' || channel.status === 'SUSPENDED' || channel.status === 'DISABLED') {
      throw new ForbiddenException(`Channel is ${channel.status.toLowerCase()} and cannot publish posts.`);
    }

    await this.verifyChannelManagement(channel, userId, GroupRole.MODERATOR);

    return this.prisma.channelCommunityPost.create({
      data: {
        channelId,
        authorId: userId,
        title: dto.title,
        content: dto.content,
        mediaUrls: dto.mediaUrls ?? [],
      },
      include: {
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
    });
  }

  async getCommunityPosts(channelId: string, page = 1, limit = 20, userId?: string) {
    const skip = (page - 1) * limit;
    const [posts, total] = await Promise.all([
      this.prisma.channelCommunityPost.findMany({
        where: { channelId },
        skip,
        take: limit,
        orderBy: [{ isPinned: 'desc' }, { createdAt: 'desc' }],
        include: {
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
          ...(userId
            ? {
                likes: {
                  where: { userId },
                  select: { id: true },
                },
              }
            : {}),
        },
      }),
      this.prisma.channelCommunityPost.count({ where: { channelId } }),
    ]);

    return {
      items: posts.map((p: any) => ({
        id: p.id,
        channelId: p.channelId,
        title: p.title,
        content: p.content,
        mediaUrls: p.mediaUrls,
        likesCount: p.likesCount,
        commentsCount: p.commentsCount,
        isPinned: p.isPinned,
        isLiked: Boolean(p.likes && p.likes.length > 0),
        author: {
          id: p.author.id,
          username: p.author.username,
          displayName: p.author.profile?.displayName ?? p.author.username,
          avatarUrl: p.author.profile?.avatar?.url ?? null,
        },
        createdAt: p.createdAt,
      })),
      total,
      page,
      limit,
    };
  }

  async toggleLikeCommunityPost(postId: string, userId: string) {
    const post = await this.prisma.channelCommunityPost.findUnique({
      where: { id: postId },
    });
    if (!post) throw new NotFoundException('Post not found');

    const existing = await this.prisma.channelPostLike.findUnique({
      where: { postId_userId: { postId, userId } },
    });

    if (existing) {
      await this.prisma.channelPostLike.delete({
        where: { id: existing.id },
      });
      await this.prisma.channelCommunityPost.update({
        where: { id: postId },
        data: { likesCount: { decrement: 1 } },
      });
      return { isLiked: false };
    } else {
      await this.prisma.channelPostLike.create({
        data: { postId, userId },
      });
      await this.prisma.channelCommunityPost.update({
        where: { id: postId },
        data: { likesCount: { increment: 1 } },
      });
      return { isLiked: true };
    }
  }

  async addCommunityComment(
    postId: string,
    userId: string,
    content: string,
    parentId?: string,
  ) {
    const post = await this.prisma.channelCommunityPost.findUnique({
      where: { id: postId },
    });
    if (!post) throw new NotFoundException('Post not found');

    const comment = await this.prisma.channelPostComment.create({
      data: {
        postId,
        authorId: userId,
        content,
        parentId,
      },
      include: {
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
    });

    await this.prisma.channelCommunityPost.update({
      where: { id: postId },
      data: { commentsCount: { increment: 1 } },
    });

    return {
      id: comment.id,
      postId: comment.postId,
      content: comment.content,
      parentId: comment.parentId,
      createdAt: comment.createdAt,
      author: {
        id: comment.author.id,
        username: comment.author.username,
        displayName: comment.author.profile?.displayName ?? comment.author.username,
        avatarUrl: comment.author.profile?.avatar?.url ?? null,
      },
    };
  }

  async getCommunityComments(postId: string, page = 1, limit = 50) {
    const skip = (page - 1) * limit;
    const [comments, total] = await Promise.all([
      this.prisma.channelPostComment.findMany({
        where: { postId },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
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
      }),
      this.prisma.channelPostComment.count({ where: { postId } }),
    ]);

    return {
      items: comments.map((c: any) => ({
        id: c.id,
        postId: c.postId,
        content: c.content,
        parentId: c.parentId,
        createdAt: c.createdAt,
        author: {
          id: c.author.id,
          username: c.author.username,
          displayName: c.author.profile?.displayName ?? c.author.username,
          avatarUrl: c.author.profile?.avatar?.url ?? null,
        },
      })),
      total,
      page,
      limit,
    };
  }
}
