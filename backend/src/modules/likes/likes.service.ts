// src/modules/likes/likes.service.ts
import { Injectable } from '@nestjs/common';
import { LikesRepository } from './likes.repository.js';
import { ReactionType } from '@prisma/client';

@Injectable()
export class LikesService {
  constructor(private readonly likesRepository: LikesRepository) {}

  async togglePostLike(userId: string, postId: string, reaction?: ReactionType) {
    return this.likesRepository.togglePostLike(userId, postId, reaction);
  }

  async toggleReelLike(userId: string, reelId: string, reaction?: ReactionType) {
    return this.likesRepository.toggleReelLike(userId, reelId, reaction);
  }

  async toggleCommentLike(userId: string, commentId: string) {
    return this.likesRepository.toggleCommentLike(userId, commentId);
  }
}
