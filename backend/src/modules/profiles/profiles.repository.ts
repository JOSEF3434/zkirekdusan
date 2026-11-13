// src/modules/profiles/profiles.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { UpdateProfileDto } from './dto/update-profile.dto.js';

@Injectable()
export class ProfilesRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findByUserId(userId: string) {
    let profile = await this.prisma.profile.findUnique({
      where: { userId },
      include: {
        user: { select: { id: true, username: true, email: true, phoneNumber: true } },
        avatar: { select: { url: true } },
        cover: { select: { url: true } },
      },
    });

    if (!profile) {
      // Check if user exists; if so, create default profile record
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { id: true, username: true },
      });
      if (user) {
        await this.prisma.profile.create({
          data: {
            userId: user.id,
            displayName: user.username ?? 'User',
          },
        });
        profile = await this.prisma.profile.findUnique({
          where: { userId },
          include: {
            user: { select: { id: true, username: true, email: true, phoneNumber: true } },
            avatar: { select: { url: true } },
            cover: { select: { url: true } },
          },
        });
      }
    }

    return profile;
  }

  async findByUsername(usernameOrId: string) {
    // 1. Check if directly a valid user by username (case-insensitive) or by id
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { username: { equals: usernameOrId, mode: 'insensitive' } },
          { id: usernameOrId },
        ],
      },
      select: { id: true },
    });

    if (user) {
      return this.findByUserId(user.id);
    }

    // 2. Also check if usernameOrId matches profile displayName as a fallback
    const profile = await this.prisma.profile.findFirst({
      where: {
        displayName: { equals: usernameOrId, mode: 'insensitive' },
      },
      select: { userId: true },
    });

    if (profile) {
      return this.findByUserId(profile.userId);
    }

    // 3. Check if usernameOrId matches a VideoChannel handle or slug
    const channel = await this.prisma.videoChannel.findFirst({
      where: {
        OR: [
          { handle: { equals: usernameOrId, mode: 'insensitive' } },
          { handle: { equals: `@${usernameOrId}`, mode: 'insensitive' } },
          { slug: { equals: usernameOrId, mode: 'insensitive' } },
        ],
        deletedAt: null,
      },
      select: {
        group: { select: { createdById: true } },
      },
    });

    if (channel?.group?.createdById) {
      return this.findByUserId(channel.group.createdById);
    }

    return null;
  }

  async update(userId: string, data: UpdateProfileDto) {
    return this.prisma.profile.update({
      where: { userId },
      data,
      include: {
        user: { select: { id: true, username: true, email: true, phoneNumber: true } },
        avatar: { select: { url: true } },
        cover: { select: { url: true } },
      },
    });
  }

  async updateAvatar(userId: string, fileId: string | null) {
    return this.prisma.profile.update({
      where: { userId },
      data: { avatarFileId: fileId },
    });
  }

  async updateCover(userId: string, fileId: string | null) {
    return this.prisma.profile.update({
      where: { userId },
      data: { coverFileId: fileId },
    });
  }

  /** Calculate profile stats dynamically from real database tables */
  async getProfileStats(userId: string) {
    const [
      followersCount,
      followingCount,
      groupsCount,
      postsCount,
      reelsCount,
    ] = await Promise.all([
      this.prisma.follow.count({ where: { followingId: userId } }),
      this.prisma.follow.count({ where: { followerId: userId } }),
      this.prisma.groupMember.count({ where: { userId, removedAt: null } }),
      this.prisma.post.count({ where: { authorId: userId, deletedAt: null } }),
      this.prisma.reel.count({ where: { authorId: userId, deletedAt: null } }),
    ]);

    return {
      followersCount,
      followingCount,
      groupsCount,
      postsCount,
      reelsCount,
      videosCount: reelsCount,
    };
  }
}
