// src/modules/posts/posts.service.ts
import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PostsRepository } from './posts.repository.js';
import { CreatePostDto } from './dto/create-post.dto.js';
import { UpdatePostDto } from './dto/update-post.dto.js';
import { PostResponseDto } from './dto/post-response.dto.js';

@Injectable()
export class PostsService {
  constructor(private readonly postsRepository: PostsRepository) {}

  async createPost(
    authorId: string,
    dto: CreatePostDto,
  ): Promise<PostResponseDto> {
    const post = await this.postsRepository.createPost(authorId, dto);
    if (!post) {
      throw new NotFoundException('Failed to create post');
    }
    return this.mapToDto(post);
  }

  async getPostById(postId: string): Promise<PostResponseDto> {
    const post = await this.postsRepository.findById(postId);
    if (!post) {
      throw new NotFoundException('Post not found');
    }
    await this.postsRepository.incrementViews(postId);
    return this.mapToDto(post);
  }

  async updatePost(
    postId: string,
    userId: string,
    dto: UpdatePostDto,
  ): Promise<PostResponseDto> {
    const post = await this.postsRepository.findById(postId);
    if (!post) {
      throw new NotFoundException('Post not found');
    }

    if (post.authorId !== userId) {
      throw new ForbiddenException('You can only update your own posts');
    }

    await this.postsRepository.updatePost(postId, dto);
    const updated = await this.postsRepository.findById(postId);
    return this.mapToDto(updated!);
  }

  async deletePost(
    postId: string,
    userId: string,
  ): Promise<{ message: string }> {
    const post = await this.postsRepository.findById(postId);
    if (!post) {
      throw new NotFoundException('Post not found');
    }

    if (post.authorId !== userId) {
      throw new ForbiddenException('You can only delete your own posts');
    }

    await this.postsRepository.softDeletePost(postId);
    return { message: 'Post deleted successfully' };
  }

  async getFeed(
    page = 1,
    limit = 20,
    authorId?: string,
    groupId?: string,
    hashtag?: string,
  ) {
    const skip = (page - 1) * limit;
    const { items, total } = await this.postsRepository.findFeed({
      skip,
      take: limit,
      authorId,
      groupId,
      hashtag,
    });

    const data = items.map((post) => this.mapToDto(post));

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

  private mapToDto(post: any): PostResponseDto {
    return {
      id: post.id,
      type: post.type,
      visibility: post.visibility,
      content: post.content,
      hashtags: post.hashtags ?? [],
      likesCount: post.likesCount ?? 0,
      commentsCount: post.commentsCount ?? 0,
      viewsCount: post.viewsCount ?? 0,
      groupId: post.groupId,
      author: {
        id: post.author.id,
        username: post.author.username,
        displayName: post.author.profile?.displayName ?? post.author.username,
        avatarUrl: post.author.profile?.avatar?.url ?? null,
      },
      media: (post.media ?? []).map((m: any) => ({
        id: m.file.id,
        url: m.file.url,
        fileType: m.file.fileType,
        order: m.order,
      })),
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
    };
  }
}
