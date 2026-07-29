// src/modules/stories/stories.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CreateStoryDto } from './dto/create-story.dto.js';

@Injectable()
export class StoriesRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createStory(authorId: string, dto: CreateStoryDto) {
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours from now

    return this.prisma.story.create({
      data: {
        authorId,
        type: dto.type,
        fileId: dto.fileId,
        content: dto.content,
        backgroundColor: dto.backgroundColor,
        textColor: dto.textColor,
        expiresAt,
      },
      include: {
        author: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true, avatar: { select: { url: true } } } },
          },
        },
        file: { select: { url: true } },
      },
    });
  }

  async findActiveStories() {
    const now = new Date();
    return this.prisma.story.findMany({
      where: {
        expiresAt: { gt: now },
        deletedAt: null,
      },
      include: {
        author: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true, avatar: { select: { url: true } } } },
          },
        },
        file: { select: { url: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findById(id: string) {
    return this.prisma.story.findFirst({
      where: { id, deletedAt: null },
      include: {
        author: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true, avatar: { select: { url: true } } } },
          },
        },
        file: { select: { url: true } },
      },
    });
  }

  async recordView(storyId: string, viewerId: string) {
    return this.prisma.$transaction(async (tx) => {
      const existing = await tx.storyView.findUnique({
        where: { storyId_viewerId: { storyId, viewerId } },
      });

      if (!existing) {
        await tx.storyView.create({
          data: { storyId, viewerId },
        });
        await tx.story.update({
          where: { id: storyId },
          data: { viewsCount: { increment: 1 } },
        });
      }
    });
  }

  async softDelete(id: string) {
    return this.prisma.story.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }
}
