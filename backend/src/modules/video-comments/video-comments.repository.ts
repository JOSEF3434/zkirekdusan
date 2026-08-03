// src/modules/video-comments/video-comments.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';

const COMMENT_INCLUDE = {
  user: {
    select: {
      id: true,
      username: true,
      profile: { select: { displayName: true, avatarFileId: true } },
    },
  },
  replies: {
    include: {
      user: {
        select: {
          id: true,
          username: true,
          profile: { select: { displayName: true, avatarFileId: true } },
        },
      },
    },
    orderBy: { createdAt: 'asc' as const },
    take: 5,
  },
} as const;

@Injectable()
export class VideoCommentsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    videoId: string,
    userId: string,
    content: string,
    parentId?: string,
  ) {
    const comment = await this.prisma.videoComment.create({
      data: { videoId, userId, content, parentId },
      include: COMMENT_INCLUDE,
    });

    await this.prisma.video.update({
      where: { id: videoId },
      data: { commentsCount: { increment: 1 } },
    });

    if (parentId) {
      await this.prisma.videoComment.update({
        where: { id: parentId },
        data: { repliesCount: { increment: 1 } },
      });
    }

    return comment;
  }

  async findByVideo(videoId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [data, total] = await this.prisma.$transaction([
      this.prisma.videoComment.findMany({
        where: { videoId, parentId: null, deletedAt: null },
        include: COMMENT_INCLUDE,
        skip,
        take: limit,
        orderBy: [{ isPinned: 'desc' }, { createdAt: 'desc' }],
      }),
      this.prisma.videoComment.count({
        where: { videoId, parentId: null, deletedAt: null },
      }),
    ]);
    return { data, total, page, limit };
  }

  async findById(id: string) {
    return this.prisma.videoComment.findUnique({
      where: { id, deletedAt: null },
      include: COMMENT_INCLUDE,
    });
  }

  async update(id: string, content: string) {
    return this.prisma.videoComment.update({
      where: { id },
      data: { content, isEdited: true },
      include: COMMENT_INCLUDE,
    });
  }

  async softDelete(id: string) {
    const comment = await this.prisma.videoComment.update({
      where: { id },
      data: { deletedAt: new Date() },
    });

    await this.prisma.video.update({
      where: { id: comment.videoId },
      data: { commentsCount: { decrement: 1 } },
    });

    return comment;
  }

  async toggleLike(commentId: string, userId: string) {
    const existing = await this.prisma.videoCommentLike.findUnique({
      where: { userId_commentId: { userId, commentId } },
    });

    if (existing) {
      await this.prisma.videoCommentLike.delete({
        where: { userId_commentId: { userId, commentId } },
      });
      await this.prisma.videoComment.update({
        where: { id: commentId },
        data: { likesCount: { decrement: 1 } },
      });
      return { liked: false };
    } else {
      await this.prisma.videoCommentLike.create({
        data: { userId, commentId },
      });
      await this.prisma.videoComment.update({
        where: { id: commentId },
        data: { likesCount: { increment: 1 } },
      });
      return { liked: true };
    }
  }

  async pinComment(commentId: string, isPinned: boolean) {
    return this.prisma.videoComment.update({
      where: { id: commentId },
      data: { isPinned },
    });
  }
}
