// src/modules/reels/reels.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CreateReelDto } from './dto/create-reel.dto.js';

@Injectable()
export class ReelsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createReel(authorId: string, dto: CreateReelDto) {
    return this.prisma.reel.create({
      data: {
        authorId,
        fileId: dto.fileId,
        thumbnailUrl: dto.thumbnailUrl,
        caption: dto.caption,
        hashtags: dto.hashtags ?? [],
        duration: dto.duration,
      },
      include: {
        author: {
          select: {
            id: true,
            username: true,
            profile: {
              select: { displayName: true, avatar: { select: { url: true } } },
            },
          },
        },
        file: { select: { url: true } },
      },
    });
  }

  async findById(id: string) {
    return this.prisma.reel.findFirst({
      where: { id, deletedAt: null },
      include: {
        author: {
          select: {
            id: true,
            username: true,
            profile: {
              select: { displayName: true, avatar: { select: { url: true } } },
            },
          },
        },
        file: { select: { url: true } },
      },
    });
  }

  async incrementViews(id: string) {
    return this.prisma.reel.update({
      where: { id },
      data: { viewsCount: { increment: 1 } },
    });
  }

  async softDelete(id: string) {
    return this.prisma.reel.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  async findFeed(skip = 0, take = 20, authorId?: string) {
    const where = {
      deletedAt: null,
      status: 'PUBLISHED' as const,
      ...(authorId ? { authorId } : {}),
    };

    const [items, total] = await Promise.all([
      this.prisma.reel.findMany({
        where,
        skip,
        take,
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
          file: { select: { url: true } },
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.reel.count({ where }),
    ]);

    return { items, total };
  }
}
