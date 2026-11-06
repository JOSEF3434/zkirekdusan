// src/modules/follows/follows.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class FollowsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async follow(followerId: string, followingId: string) {
    return this.prisma.follow.upsert({
      where: {
        followerId_followingId: { followerId, followingId },
      },
      create: { followerId, followingId },
      update: {},
    });
  }

  async unfollow(followerId: string, followingId: string) {
    return this.prisma.follow.deleteMany({
      where: { followerId, followingId },
    });
  }

  async isFollowing(followerId: string, followingId: string): Promise<boolean> {
    const count = await this.prisma.follow.count({
      where: { followerId, followingId },
    });
    return count > 0;
  }

  async getFollowers(userId: string, skip = 0, take = 20) {
    const where = { followingId: userId };
    const [items, total] = await Promise.all([
      this.prisma.follow.findMany({
        where,
        skip,
        take,
        include: {
          follower: {
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
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.follow.count({ where }),
    ]);

    return { items, total };
  }

  async getFollowing(userId: string, skip = 0, take = 20) {
    const where = { followerId: userId };
    const [items, total] = await Promise.all([
      this.prisma.follow.findMany({
        where,
        skip,
        take,
        include: {
          following: {
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
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.follow.count({ where }),
    ]);

    return { items, total };
  }

  async getCounts(userId: string) {
    const [followersCount, followingCount] = await Promise.all([
      this.prisma.follow.count({ where: { followingId: userId } }),
      this.prisma.follow.count({ where: { followerId: userId } }),
    ]);
    return { followersCount, followingCount };
  }

  async getSuggested(userId?: string, skip = 0, take = 20) {
    const followingIds = userId
      ? await this.prisma.follow
          .findMany({
            where: { followerId: userId },
            select: { followingId: true },
          })
          .then((res) => res.map((r) => r.followingId))
      : [];

    const excludeIds = userId ? [userId, ...followingIds] : [];

    const where: any = {
      status: 'ACTIVE',
      ...(excludeIds.length > 0 ? { id: { notIn: excludeIds } } : {}),
    };

    const [items, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take,
        select: {
          id: true,
          username: true,
          profile: {
            select: {
              displayName: true,
              avatar: { select: { url: true } },
            },
          },
          _count: {
            select: {
              followers: true,
              videos: true,
            },
          },
        },
        orderBy: [
          { followers: { _count: 'desc' } },
          { createdAt: 'desc' },
        ],
      }),
      this.prisma.user.count({ where }),
    ]);

    return { items, total };
  }
}
