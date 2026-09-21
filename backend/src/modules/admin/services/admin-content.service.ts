// src/modules/admin/services/admin-content.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';

@Injectable()
export class AdminContentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AdminAuditService,
  ) {}

  async listPosts(query: {
    page?: number;
    limit?: number;
    search?: string;
    status?: string;
    groupId?: string;
    authorId?: string;
  }) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {};
    if (query.search) {
      where.OR = [
        { content: { contains: query.search, mode: 'insensitive' } },
        { hashtags: { has: query.search } },
      ];
    }
    if (query.status && query.status !== 'ALL') {
      where.status = query.status;
    }
    if (query.groupId) {
      where.groupId = query.groupId;
    }
    if (query.authorId) {
      where.authorId = query.authorId;
    }

    const [items, total] = await Promise.all([
      this.prisma.post.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
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
          group: {
            select: {
              id: true,
              name: true,
              slug: true,
            },
          },
          media: {
            select: {
              id: true,
              order: true,
              file: {
                select: {
                  url: true,
                  mimeType: true,
                },
              },
            },
          },
          _count: {
            select: {
              likes: true,
              comments: true,
            },
          },
        },
      }),
      this.prisma.post.count({ where }),
    ]);

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      hasNext: page * limit < total,
    };
  }

  async getPostDetail(id: string) {
    const post = await this.prisma.post.findUnique({
      where: { id },
      include: {
        author: {
          select: {
            id: true,
            username: true,
            email: true,
            profile: {
              select: {
                displayName: true,
                avatar: { select: { url: true } },
              },
            },
          },
        },
        group: true,
        media: {
          include: {
            file: true,
          },
        },
        comments: {
          take: 10,
          orderBy: { createdAt: 'desc' },
          include: {
            author: {
              select: {
                id: true,
                username: true,
                profile: { select: { displayName: true } },
              },
            },
          },
        },
        _count: {
          select: {
            likes: true,
            comments: true,
          },
        },
      },
    });

    if (!post) {
      throw new NotFoundException(`Post ${id} not found`);
    }

    return post;
  }

  async updatePostStatus(
    id: string,
    status: any,
    actorId: string,
    reason?: string,
  ) {
    const post = await this.prisma.post.findUnique({ where: { id } });
    if (!post) {
      throw new NotFoundException(`Post ${id} not found`);
    }

    const before = { status: post.status };
    const updated = await this.prisma.post.update({
      where: { id },
      data: { status },
    });

    await this.auditService.log({
      actorId,
      action: 'POST_STATUS_UPDATED',
      targetType: 'POST',
      targetId: id,
      before,
      after: { status },
      reason,
    });

    return updated;
  }

  async deletePost(id: string, actorId: string, reason?: string) {
    const post = await this.prisma.post.findUnique({ where: { id } });
    if (!post) {
      throw new NotFoundException(`Post ${id} not found`);
    }

    await this.prisma.post.delete({ where: { id } });

    await this.auditService.log({
      actorId,
      action: 'POST_DELETED',
      targetType: 'POST',
      targetId: id,
      before: { authorId: post.authorId, content: post.content?.slice(0, 100) },
      reason,
    });

    return { success: true, message: 'Post deleted successfully' };
  }

  async listVideos(query: {
    page?: number;
    limit?: number;
    search?: string;
    status?: string;
    channelId?: string;
  }) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {};
    if (query.search) {
      where.OR = [
        { title: { contains: query.search, mode: 'insensitive' } },
        { description: { contains: query.search, mode: 'insensitive' } },
      ];
    }
    if (query.status && query.status !== 'ALL') {
      where.status = query.status;
    }
    if (query.channelId) {
      where.videoChannelId = query.channelId;
    }

    const [items, total] = await Promise.all([
      this.prisma.video.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          uploadedBy: {
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
          videoChannel: {
            select: {
              id: true,
              name: true,
              slug: true,
            },
          },
          sourceFile: {
            select: {
              url: true,
              mimeType: true,
              size: true,
            },
          },
        },
      }),
      this.prisma.video.count({ where }),
    ]);

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      hasNext: page * limit < total,
    };
  }

  async updateVideoStatus(
    id: string,
    status: any,
    actorId: string,
    reason?: string,
  ) {
    const video = await this.prisma.video.findUnique({ where: { id } });
    if (!video) {
      throw new NotFoundException(`Video ${id} not found`);
    }

    const before = { status: video.status };
    const updated = await this.prisma.video.update({
      where: { id },
      data: { status },
    });

    await this.auditService.log({
      actorId,
      action: 'VIDEO_STATUS_UPDATED',
      targetType: 'VIDEO',
      targetId: id,
      before,
      after: { status },
      reason,
    });

    return updated;
  }

  async deleteVideo(id: string, actorId: string, reason?: string) {
    const video = await this.prisma.video.findUnique({ where: { id } });
    if (!video) {
      throw new NotFoundException(`Video ${id} not found`);
    }

    await this.prisma.video.delete({ where: { id } });

    await this.auditService.log({
      actorId,
      action: 'VIDEO_DELETED',
      targetType: 'VIDEO',
      targetId: id,
      before: { title: video.title, channelId: video.videoChannelId },
      reason,
    });

    return { success: true, message: 'Video deleted successfully' };
  }

  async listReels(query: {
    page?: number;
    limit?: number;
    search?: string;
    authorId?: string;
  }) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {};
    if (query.search) {
      where.caption = { contains: query.search, mode: 'insensitive' };
    }
    if (query.authorId) {
      where.authorId = query.authorId;
    }

    const [items, total] = await Promise.all([
      this.prisma.reel.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
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
          file: {
            select: {
              url: true,
              mimeType: true,
              size: true,
            },
          },
        },
      }),
      this.prisma.reel.count({ where }),
    ]);

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      hasNext: page * limit < total,
    };
  }

  async deleteReel(id: string, actorId: string, reason?: string) {
    const reel = await this.prisma.reel.findUnique({ where: { id } });
    if (!reel) {
      throw new NotFoundException(`Reel ${id} not found`);
    }

    await this.prisma.reel.delete({ where: { id } });

    await this.auditService.log({
      actorId,
      action: 'REEL_DELETED',
      targetType: 'REEL',
      targetId: id,
      before: { authorId: reel.authorId, caption: reel.caption?.slice(0, 100) },
      reason,
    });

    return { success: true, message: 'Reel deleted successfully' };
  }

  async listComments(query: {
    page?: number;
    limit?: number;
    search?: string;
    postId?: string;
  }) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {};
    if (query.search) {
      where.content = { contains: query.search, mode: 'insensitive' };
    }
    if (query.postId) {
      where.postId = query.postId;
    }

    const [items, total] = await Promise.all([
      this.prisma.comment.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
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
        },
      }),
      this.prisma.comment.count({ where }),
    ]);

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      hasNext: page * limit < total,
    };
  }

  async deleteComment(id: string, actorId: string, reason?: string) {
    const comment = await this.prisma.comment.findUnique({ where: { id } });
    if (!comment) {
      throw new NotFoundException(`Comment ${id} not found`);
    }

    await this.prisma.comment.delete({ where: { id } });

    await this.auditService.log({
      actorId,
      action: 'COMMENT_DELETED',
      targetType: 'COMMENT',
      targetId: id,
      before: { postId: comment.postId, authorId: comment.authorId },
      reason,
    });

    return { success: true, message: 'Comment deleted successfully' };
  }
}
