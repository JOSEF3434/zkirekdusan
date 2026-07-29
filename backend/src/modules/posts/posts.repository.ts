// src/modules/posts/posts.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CreatePostDto } from './dto/create-post.dto.js';
import { UpdatePostDto } from './dto/update-post.dto.js';
import { Prisma } from '@prisma/client';

@Injectable()
export class PostsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createPost(authorId: string, dto: CreatePostDto) {
    return this.prisma.$transaction(async (tx) => {
      const post = await tx.post.create({
        data: {
          authorId,
          type: dto.type,
          visibility: dto.visibility ?? 'PUBLIC',
          content: dto.content,
          hashtags: dto.hashtags ?? [],
          mentions: dto.mentions ?? [],
          groupId: dto.groupId,
          publishedAt: new Date(),
        },
      });

      if (dto.mediaFileIds && dto.mediaFileIds.length > 0) {
        await tx.postMedia.createMany({
          data: dto.mediaFileIds.map((fileId, index) => ({
            postId: post.id,
            fileId,
            order: index,
          })),
        });
      }

      return this.findById(post.id);
    });
  }

  async findById(id: string) {
    return this.prisma.post.findFirst({
      where: { id, deletedAt: null },
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
          orderBy: { order: 'asc' },
        },
      },
    });
  }

  async updatePost(id: string, dto: UpdatePostDto) {
    return this.prisma.post.update({
      where: { id },
      data: dto,
    });
  }

  async softDeletePost(id: string) {
    return this.prisma.post.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  async incrementViews(id: string) {
    return this.prisma.post.update({
      where: { id },
      data: { viewsCount: { increment: 1 } },
    });
  }

  async findFeed(params: {
    skip?: number;
    take?: number;
    authorId?: string;
    groupId?: string;
    hashtag?: string;
  }) {
    const where: Prisma.PostWhereInput = {
      deletedAt: null,
      status: 'PUBLISHED',
      ...(params.authorId ? { authorId: params.authorId } : {}),
      ...(params.groupId ? { groupId: params.groupId } : {}),
      ...(params.hashtag ? { hashtags: { has: params.hashtag } } : {}),
    };

    const [items, total] = await Promise.all([
      this.prisma.post.findMany({
        where,
        skip: params.skip ?? 0,
        take: params.take ?? 20,
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
            orderBy: { order: 'asc' },
          },
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.post.count({ where }),
    ]);

    return { items, total };
  }
}
