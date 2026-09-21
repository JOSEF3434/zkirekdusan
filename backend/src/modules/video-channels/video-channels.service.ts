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

  async findById(id: string) {
    const channel = await this.repo.findById(id);
    if (!channel) throw new NotFoundException('Video channel not found');
    return this.mapChannelToDto(channel);
  }

  async update(id: string, userId: string, dto: UpdateVideoChannelDto) {
    const channel = await this.repo.findById(id);
    if (!channel) throw new NotFoundException('Video channel not found');

    await this.verifyGroupAccess(
      channel.groupId,
      userId,
      GroupRole.GROUP_ADMIN,
    );

    if (dto.handle && dto.handle !== channel.handle) {
      const handleExists = await this.repo.findByHandle(dto.handle);
      if (handleExists)
        throw new ConflictException(`Handle '${dto.handle}' is already taken`);
    }

    if (dto.slug && dto.slug !== channel.slug) {
      const slugExists = await this.repo.findBySlugAndGroup(
        channel.groupId,
        dto.slug,
      );
      if (slugExists)
        throw new ConflictException(
          `Slug '${dto.slug}' already exists in this group`,
        );
    }

    const updated = await this.repo.update(id, dto);
    return this.mapChannelToDto(updated);
  }

  async delete(id: string, userId: string) {
    const channel = await this.repo.findById(id);
    if (!channel) throw new NotFoundException('Video channel not found');

    await this.verifyGroupAccess(
      channel.groupId,
      userId,
      GroupRole.GROUP_ADMIN,
    );
    await this.repo.softDelete(id);
    return { message: 'Video channel deleted successfully' };
  }

  async subscribe(userId: string, channelId: string) {
    const channel = await this.repo.findById(channelId);
    if (!channel) throw new NotFoundException('Video channel not found');

    const isSubbed = await this.repo.isSubscribed(userId, channelId);
    if (isSubbed)
      throw new BadRequestException('Already subscribed to this channel');

    await this.repo.subscribe(userId, channelId);
    await this.repo.incrementSubscribers(channelId, 1);
    return { message: 'Subscribed successfully' };
  }

  async unsubscribe(userId: string, channelId: string) {
    const channel = await this.repo.findById(channelId);
    if (!channel) throw new NotFoundException('Video channel not found');

    const isSubbed = await this.repo.isSubscribed(userId, channelId);
    if (!isSubbed)
      throw new BadRequestException('Not subscribed to this channel');

    await this.repo.unsubscribe(userId, channelId);
    await this.repo.incrementSubscribers(channelId, -1);
    return { message: 'Unsubscribed successfully' };
  }

  async getSubscribers(channelId: string, page = 1, limit = 20) {
    const channel = await this.repo.findById(channelId);
    if (!channel) throw new NotFoundException('Video channel not found');
    return this.repo.getSubscribers(channelId, page, limit);
  }

  async getChannelAnalytics(channelId: string, userId: string) {
    const channel = await this.repo.findById(channelId);
    if (!channel) throw new NotFoundException('Video channel not found');

    await this.verifyGroupAccess(channel.groupId, userId, GroupRole.MODERATOR);

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

    await this.verifyGroupAccess(
      channel.groupId,
      userId,
      GroupRole.GROUP_ADMIN,
    );
    return this.uploadsService.uploadChannelAvatar(channelId, userId, file);
  }

  async uploadBanner(
    channelId: string,
    userId: string,
    file: Express.Multer.File,
  ) {
    const channel = await this.repo.findById(channelId);
    if (!channel) throw new NotFoundException('Video channel not found');

    await this.verifyGroupAccess(
      channel.groupId,
      userId,
      GroupRole.GROUP_ADMIN,
    );
    return this.uploadsService.uploadChannelBanner(channelId, userId, file);
  }
}
