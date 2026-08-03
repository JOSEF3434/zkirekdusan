// src/modules/profiles/profiles.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { UpdateProfileDto } from './dto/update-profile.dto.js';

@Injectable()
export class ProfilesRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findByUserId(userId: string) {
    return this.prisma.profile.findUnique({
      where: { userId },
      include: {
        user: { select: { id: true, username: true, email: true } },
        avatar: { select: { url: true } },
        cover: { select: { url: true } },
      },
    });
  }

  async findByUsername(username: string) {
    const user = await this.prisma.user.findUnique({
      where: { username },
      select: { id: true },
    });

    if (!user) return null;
    return this.findByUserId(user.id);
  }

  async update(userId: string, data: UpdateProfileDto) {
    return this.prisma.profile.update({
      where: { userId },
      data,
      include: {
        user: { select: { id: true, username: true, email: true } },
        avatar: { select: { url: true } },
        cover: { select: { url: true } },
      },
    });
  }

  async updateAvatar(userId: string, fileId: string) {
    return this.prisma.profile.update({
      where: { userId },
      data: { avatarFileId: fileId },
    });
  }

  async updateCover(userId: string, fileId: string) {
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
