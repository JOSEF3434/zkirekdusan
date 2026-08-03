// src/modules/comments/comments.service.ts
import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CommentsRepository } from './comments.repository.js';
import { CreateCommentDto } from './dto/create-comment.dto.js';
import { CommentResponseDto } from './dto/comment-response.dto.js';
import { PostsRepository } from '../posts/posts.repository.js';

@Injectable()
export class CommentsService {
  constructor(
    private readonly commentsRepository: CommentsRepository,
    private readonly postsRepository: PostsRepository,
  ) {}

  async createComment(
    postId: string,
    authorId: string,
    dto: CreateCommentDto,
  ): Promise<CommentResponseDto> {
    const post = await this.postsRepository.findById(postId);
    if (!post) {
      throw new NotFoundException('Post not found');
    }

    if (dto.parentId) {
      const parent = await this.commentsRepository.findById(dto.parentId);
      if (!parent || parent.postId !== postId) {
        throw new NotFoundException('Parent comment not found for this post');
      }
    }

    const comment = await this.commentsRepository.createComment(
      postId,
      authorId,
      dto,
    );
    return this.mapToDto(comment);
  }

  async getCommentsByPost(postId: string, page = 1, limit = 20) {
    const post = await this.postsRepository.findById(postId);
    if (!post) {
      throw new NotFoundException('Post not found');
    }

    const skip = (page - 1) * limit;
    const { items, total } = await this.commentsRepository.findByPost(
      postId,
      skip,
      limit,
    );

    const data = items.map((c) => ({
      ...this.mapToDto(c),
      replies: (c.replies ?? []).map((r: any) => this.mapToDto(r)),
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

  async deleteComment(commentId: string, userId: string) {
    const comment = await this.commentsRepository.findById(commentId);
    if (!comment) {
      throw new NotFoundException('Comment not found');
    }

    if (comment.authorId !== userId) {
      throw new ForbiddenException('You can only delete your own comments');
    }

    await this.commentsRepository.softDelete(commentId, comment.postId);
    return { message: 'Comment deleted successfully' };
  }

  private mapToDto(c: any): CommentResponseDto {
    return {
      id: c.id,
      postId: c.postId,
      parentId: c.parentId,
      content: c.content,
      likesCount: c.likesCount ?? 0,
      author: {
        id: c.author.id,
        username: c.author.username,
        displayName: c.author.profile?.displayName ?? c.author.username,
        avatarUrl: c.author.profile?.avatar?.url ?? null,
      },
      createdAt: c.createdAt,
    };
  }
}
