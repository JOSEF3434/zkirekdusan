// src/modules/stories/stories.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CreateStoryDto } from './dto/create-story.dto.js';
import { ReactionType } from '@prisma/client';

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
            profile: {
              select: { displayName: true, avatar: { select: { url: true } } },
            },
          },
        },
        file: { select: { url: true } },
      },
    });
  }

  async findFollowingUserIds(userId?: string): Promise<string[]> {
    if (!userId) return [];
    const follows = await this.prisma.follow.findMany({
      where: { followerId: userId },
      select: { followingId: true },
    });
    return follows.map((f) => f.followingId);
  }

  async findActiveStoriesForViewer(viewerId?: string) {
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
            profile: {
              select: { displayName: true, avatar: { select: { url: true } } },
            },
          },
        },
        file: { select: { url: true } },
        views: {
          where: viewerId ? { viewerId } : { viewerId: 'guest-no-id' },
          select: { viewedAt: true },
        },
        reactions: {
          where: viewerId ? { userId: viewerId } : { userId: 'guest-no-id' },
          select: { reaction: true },
        },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async findMyActiveStories(userId: string) {
    const now = new Date();
    return this.prisma.story.findMany({
      where: {
        authorId: userId,
        expiresAt: { gt: now },
        deletedAt: null,
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
        views: {
          where: { viewerId: userId },
          select: { viewedAt: true },
        },
        reactions: {
          where: { userId },
          select: { reaction: true },
        },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async findById(id: string, viewerId?: string) {
    return this.prisma.story.findFirst({
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
        views: viewerId
          ? {
              where: { viewerId },
              select: { viewedAt: true },
            }
          : false,
        reactions: viewerId
          ? {
              where: { userId: viewerId },
              select: { reaction: true },
            }
          : false,
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

  async addReaction(storyId: string, userId: string, reaction: ReactionType) {
    return this.prisma.$transaction(async (tx) => {
      const existing = await tx.storyReaction.findUnique({
        where: { storyId_userId: { storyId, userId } },
      });

      if (existing) {
        return tx.storyReaction.update({
          where: { storyId_userId: { storyId, userId } },
          data: { reaction },
          include: {
            user: {
              select: {
                id: true,
                username: true,
                profile: {
                  select: { displayName: true, avatar: { select: { url: true } } },
                },
              },
            },
          },
        });
      } else {
        const created = await tx.storyReaction.create({
          data: { storyId, userId, reaction },
          include: {
            user: {
              select: {
                id: true,
                username: true,
                profile: {
                  select: { displayName: true, avatar: { select: { url: true } } },
                },
              },
            },
          },
        });
        await tx.story.update({
          where: { id: storyId },
          data: { reactionsCount: { increment: 1 } },
        });
        return created;
      }
    });
  }

  async removeReaction(storyId: string, userId: string) {
    return this.prisma.$transaction(async (tx) => {
      const existing = await tx.storyReaction.findUnique({
        where: { storyId_userId: { storyId, userId } },
      });

      if (existing) {
        await tx.storyReaction.delete({
          where: { storyId_userId: { storyId, userId } },
        });
        await tx.story.update({
          where: { id: storyId },
          data: { reactionsCount: { decrement: 1 } },
        });
      }
    });
  }

  async findViewers(storyId: string) {
    return this.prisma.storyView.findMany({
      where: { storyId },
      orderBy: { viewedAt: 'desc' },
      include: {
        viewer: {
          select: {
            id: true,
            username: true,
            profile: {
              select: { displayName: true, avatar: { select: { url: true } } },
            },
          },
        },
      },
    });
  }

  async findReactions(storyId: string) {
    return this.prisma.storyReaction.findMany({
      where: { storyId },
      orderBy: { createdAt: 'desc' },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            profile: {
              select: { displayName: true, avatar: { select: { url: true } } },
            },
          },
        },
      },
    });
  }

  async addComment(storyId: string, authorId: string, content: string) {
    return this.prisma.$transaction(async (tx) => {
      const comment = await tx.storyComment.create({
        data: {
          storyId,
          authorId,
          content,
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
        },
      });

      await tx.story.update({
        where: { id: storyId },
        data: { commentsCount: { increment: 1 } },
      });

      return comment;
    });
  }

  async findComments(storyId: string) {
    return this.prisma.storyComment.findMany({
      where: { storyId, deletedAt: null },
      orderBy: { createdAt: 'desc' },
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
      },
    });
  }

  async softDelete(id: string) {
    return this.prisma.story.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  async findAuthorProfile(userId: string) {
    return this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        username: true,
        profile: {
          select: { displayName: true, avatar: { select: { url: true } } },
        },
      },
    });
  }
}
