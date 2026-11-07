// src/modules/follows/follows.service.ts
import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { FollowsRepository } from './follows.repository.js';
import { UsersRepository } from '../users/users.repository.js';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class FollowsService {
  constructor(
    private readonly followsRepository: FollowsRepository,
    private readonly usersRepository: UsersRepository,
    private readonly prisma: PrismaService,
  ) {}

  async followUser(followerId: string, targetUserId: string) {
    if (followerId === targetUserId) {
      throw new BadRequestException('You cannot follow yourself');
    }

    const targetUser = await this.usersRepository.findById(targetUserId);
    if (!targetUser) {
      const channel = await this.prisma.videoChannel.findFirst({
        where: { OR: [{ id: targetUserId }, { groupId: targetUserId }] },
        include: { group: true },
      });
      if (channel) {
        const isOwner = channel.ownerId === followerId || (channel.group && channel.group.createdById === followerId);
        if (isOwner) {
          throw new BadRequestException('You cannot follow your own channel');
        }
        await this.prisma.videoSubscription.upsert({
          where: {
            userId_videoChannelId: {
              userId: followerId,
              videoChannelId: channel.id,
            },
          },
          create: {
            userId: followerId,
            videoChannelId: channel.id,
          },
          update: {},
        });
        await this.prisma.videoChannel.update({
          where: { id: channel.id },
          data: { subscribersCount: { increment: 1 } },
        });
        return { message: `Successfully followed ${channel.name}` };
      }
      throw new NotFoundException('User or channel to follow not found');
    }

    await this.followsRepository.follow(followerId, targetUserId);
    return { message: `Successfully followed ${targetUser.username}` };
  }

  async unfollowUser(followerId: string, targetUserId: string) {
    if (followerId === targetUserId) {
      throw new BadRequestException('You cannot unfollow yourself');
    }

    const targetUser = await this.usersRepository.findById(targetUserId);
    if (!targetUser) {
      const channel = await this.prisma.videoChannel.findFirst({
        where: { OR: [{ id: targetUserId }, { groupId: targetUserId }] },
      });
      if (channel) {
        await this.prisma.videoSubscription.deleteMany({
          where: {
            userId: followerId,
            videoChannelId: channel.id,
          },
        });
        await this.prisma.videoChannel.update({
          where: { id: channel.id },
          data: { subscribersCount: { decrement: 1 } },
        });
        return { message: 'Successfully unfollowed channel' };
      }
      throw new NotFoundException('User or channel to unfollow not found');
    }

    await this.followsRepository.unfollow(followerId, targetUserId);
    return { message: 'Successfully unfollowed user' };
  }

  async getFollowers(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const { items, total } = await this.followsRepository.getFollowers(
      userId,
      skip,
      limit,
    );

    const data = items.map((item) => ({
      user: {
        id: item.follower.id,
        username: item.follower.username,
        displayName:
          item.follower.profile?.displayName ?? item.follower.username,
        avatarUrl: item.follower.profile?.avatar?.url ?? null,
      },
      createdAt: item.createdAt,
    }));

    return {
      data,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1,
      },
    };
  }

  async getFollowing(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const { items, total } = await this.followsRepository.getFollowing(
      userId,
      skip,
      limit,
    );

    const data = items.map((item) => ({
      user: {
        id: item.following.id,
        username: item.following.username,
        displayName:
          item.following.profile?.displayName ?? item.following.username,
        avatarUrl: item.following.profile?.avatar?.url ?? null,
      },
      createdAt: item.createdAt,
    }));

    return {
      data,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1,
      },
    };
  }

  async getFollowStatus(currentUserId: string, targetUserId: string) {
    const [isFollowingUser, isFollowedBy, channelSub] = await Promise.all([
      this.followsRepository.isFollowing(currentUserId, targetUserId),
      this.followsRepository.isFollowing(targetUserId, currentUserId),
      this.prisma.videoSubscription.findFirst({
        where: {
          userId: currentUserId,
          videoChannel: {
            OR: [{ id: targetUserId }, { groupId: targetUserId }],
          },
        },
      }),
    ]);

    return {
      isFollowing: isFollowingUser || !!channelSub,
      isFollowedBy,
    };
  }

  async getSuggested(userId?: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const { channels, totalChannels, users, totalUsers } =
      await this.followsRepository.getSuggested(userId, skip, limit);

    const channelItems = channels.map((c) => ({
      id: c.id,
      username: (c.handle || c.slug).replace(/^@/, ''),
      displayName: c.name,
      avatarUrl: c.avatarFile?.url ?? c.group?.avatarUrl ?? null,
      followersCount: c.subscribersCount,
      videosCount: c.videosCount,
      groupId: c.groupId,
      isFollowing: Array.isArray(c.subscriptions) && c.subscriptions.length > 0,
      isChannel: true,
      ownerId: c.group?.createdById,
    }));

    const userItems = users
      .filter((u) => u.username || u.profile?.displayName)
      .map((u) => ({
        id: u.id,
        username: u.username,
        displayName: u.profile?.displayName ?? u.username,
        avatarUrl: u.profile?.avatar?.url ?? null,
        followersCount: u._count.followers,
        videosCount: u._count.videos,
        groupId: null,
        isFollowing: false,
        isChannel: false,
        ownerId: u.id,
      }));

    const data = [...channelItems, ...userItems].slice(0, limit);
    const total = totalChannels + totalUsers;

    return {
      data,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1,
      },
    };
  }
}
