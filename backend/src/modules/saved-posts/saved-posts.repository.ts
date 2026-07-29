// src/modules/saved-posts/saved-posts.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class SavedPostsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async toggleSave(userId: string, postId: string) {
    const existing = await this.prisma.savedPost.findUnique({
      where: { userId_postId: { userId, postId } },
    });

    if (existing) {
      await this.prisma.savedPost.delete({
        where: { userId_postId: { userId, postId } },
      });
      return { saved: false };
    }

    await this.prisma.savedPost.create({
      data: { userId, postId },
    });
    return { saved: true };
  }

  async getSavedPosts(userId: string, skip = 0, take = 20) {
    const where = { userId, post: { deletedAt: null } };
    const [items, total] = await Promise.all([
      this.prisma.savedPost.findMany({
        where,
        skip,
        take,
        include: {
          post: {
            include: {
              author: {
                select: {
                  id: true,
                  username: true,
                  profile: { select: { displayName: true, avatar: { select: { url: true } } } },
                },
              },
              media: {
                include: {
                  file: { select: { id: true, url: true, fileType: true } },
                },
              },
            },
          },
        },
        orderBy: { savedAt: 'desc' },
      }),
      this.prisma.savedPost.count({ where }),
    ]);

    return { items, total };
  }
}
