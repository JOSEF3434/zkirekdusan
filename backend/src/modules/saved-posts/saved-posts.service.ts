// src/modules/saved-posts/saved-posts.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { SavedPostsRepository } from './saved-posts.repository.js';
import { PostsRepository } from '../posts/posts.repository.js';

@Injectable()
export class SavedPostsService {
  constructor(
    private readonly savedPostsRepository: SavedPostsRepository,
    private readonly postsRepository: PostsRepository,
  ) {}

  async toggleSavePost(userId: string, postId: string) {
    const post = await this.postsRepository.findById(postId);
    if (!post) {
      throw new NotFoundException('Post not found');
    }

    return this.savedPostsRepository.toggleSave(userId, postId);
  }

  async getSavedPosts(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const { items, total } = await this.savedPostsRepository.getSavedPosts(userId, skip, limit);

    const data = items.map((sp) => ({
      savedAt: sp.savedAt,
      post: {
        id: sp.post.id,
        type: sp.post.type,
        visibility: sp.post.visibility,
        content: sp.post.content,
        likesCount: sp.post.likesCount,
        commentsCount: sp.post.commentsCount,
        author: {
          id: sp.post.author.id,
          username: sp.post.author.username,
          displayName: sp.post.author.profile?.displayName ?? sp.post.author.username,
          avatarUrl: sp.post.author.profile?.avatar?.url ?? null,
        },
        media: sp.post.media.map((m: any) => ({
          id: m.file.id,
          url: m.file.url,
          fileType: m.file.fileType,
          order: m.order,
        })),
        createdAt: sp.post.createdAt,
      },
    }));

    return {
      data,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1,
      },
    };
  }
}
