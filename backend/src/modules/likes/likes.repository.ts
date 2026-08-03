// src/modules/likes/likes.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { ReactionType } from '@prisma/client';

@Injectable()
export class LikesRepository {
  constructor(private readonly prisma: PrismaService) {}

  async togglePostLike(
    userId: string,
    postId: string,
    reaction: ReactionType = 'LIKE',
  ) {
    return this.prisma.$transaction(async (tx) => {
      const existing = await tx.postLike.findUnique({
        where: { userId_postId: { userId, postId } },
      });

      if (existing) {
        await tx.postLike.delete({
          where: { userId_postId: { userId, postId } },
        });
        await tx.post.update({
          where: { id: postId },
          data: { likesCount: { decrement: 1 } },
        });
        return { liked: false };
      }

      await tx.postLike.create({
        data: { userId, postId, reaction },
      });
      await tx.post.update({
        where: { id: postId },
        data: { likesCount: { increment: 1 } },
      });
      return { liked: true, reaction };
    });
  }

  async toggleReelLike(
    userId: string,
    reelId: string,
    reaction: ReactionType = 'LIKE',
  ) {
    return this.prisma.$transaction(async (tx) => {
      const existing = await tx.reelLike.findUnique({
        where: { userId_reelId: { userId, reelId } },
      });

      if (existing) {
        await tx.reelLike.delete({
          where: { userId_reelId: { userId, reelId } },
        });
        await tx.reel.update({
          where: { id: reelId },
          data: { likesCount: { decrement: 1 } },
        });
        return { liked: false };
      }

      await tx.reelLike.create({
        data: { userId, reelId, reaction },
      });
      await tx.reel.update({
        where: { id: reelId },
        data: { likesCount: { increment: 1 } },
      });
      return { liked: true, reaction };
    });
  }

  async toggleCommentLike(userId: string, commentId: string) {
    return this.prisma.$transaction(async (tx) => {
      const existing = await tx.commentLike.findUnique({
        where: { userId_commentId: { userId, commentId } },
      });

      if (existing) {
        await tx.commentLike.delete({
          where: { userId_commentId: { userId, commentId } },
        });
        await tx.comment.update({
          where: { id: commentId },
          data: { likesCount: { decrement: 1 } },
        });
        return { liked: false };
      }

      await tx.commentLike.create({
        data: { userId, commentId },
      });
      await tx.comment.update({
        where: { id: commentId },
        data: { likesCount: { increment: 1 } },
      });
      return { liked: true };
    });
  }
}
