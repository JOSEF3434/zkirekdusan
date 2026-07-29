// src/modules/follows/follows.service.ts
import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { FollowsRepository } from './follows.repository.js';
import { UsersRepository } from '../users/users.repository.js';

@Injectable()
export class FollowsService {
  constructor(
    private readonly followsRepository: FollowsRepository,
    private readonly usersRepository: UsersRepository,
  ) {}

  async followUser(followerId: string, targetUserId: string) {
    if (followerId === targetUserId) {
      throw new BadRequestException('You cannot follow yourself');
    }

    const targetUser = await this.usersRepository.findById(targetUserId);
    if (!targetUser) {
      throw new NotFoundException('User to follow not found');
    }

    await this.followsRepository.follow(followerId, targetUserId);
    return { message: `Successfully followed ${targetUser.username}` };
  }

  async unfollowUser(followerId: string, targetUserId: string) {
    if (followerId === targetUserId) {
      throw new BadRequestException('You cannot unfollow yourself');
    }

    await this.followsRepository.unfollow(followerId, targetUserId);
    return { message: 'Successfully unfollowed user' };
  }

  async getFollowers(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const { items, total } = await this.followsRepository.getFollowers(userId, skip, limit);

    const data = items.map((item) => ({
      user: {
        id: item.follower.id,
        username: item.follower.username,
        displayName: item.follower.profile?.displayName ?? item.follower.username,
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
    const { items, total } = await this.followsRepository.getFollowing(userId, skip, limit);

    const data = items.map((item) => ({
      user: {
        id: item.following.id,
        username: item.following.username,
        displayName: item.following.profile?.displayName ?? item.following.username,
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
    const [isFollowing, isFollowedBy] = await Promise.all([
      this.followsRepository.isFollowing(currentUserId, targetUserId),
      this.followsRepository.isFollowing(targetUserId, currentUserId),
    ]);

    return { isFollowing, isFollowedBy };
  }
}
