// src/modules/admin/services/admin-live.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';

@Injectable()
export class AdminLiveService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AdminAuditService,
  ) {}

  async listStreams(query: {
    page?: number;
    limit?: number;
    status?: string;
    search?: string;
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

    const [items, total] = await Promise.all([
      this.prisma.liveStream.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          createdBy: {
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
          videoChannel: {
            select: {
              id: true,
              name: true,
            },
          },
          _count: {
            select: {
              viewers: true,
              reports: true,
            },
          },
        },
      }),
      this.prisma.liveStream.count({ where }),
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

  async getStreamDetail(id: string) {
    const stream = await this.prisma.liveStream.findUnique({
      where: { id },
      include: {
        createdBy: {
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
        videoChannel: true,
        chatRoom: {
          include: {
            _count: {
              select: { messages: true },
            },
          },
        },
        _count: {
          select: {
            viewers: true,
            reports: true,
          },
        },
      },
    });

    if (!stream) {
      throw new NotFoundException(`LiveStream ${id} not found`);
    }

    return stream;
  }

  async terminateStream(id: string, actorId: string, reason?: string) {
    const stream = await this.prisma.liveStream.findUnique({ where: { id } });
    if (!stream) {
      throw new NotFoundException(`LiveStream ${id} not found`);
    }

    const before = { status: stream.status };
    const updated = await this.prisma.liveStream.update({
      where: { id },
      data: {
        status: 'ENDED' as any,
        endedAt: new Date(),
      },
    });

    await this.auditService.log({
      actorId,
      action: 'STREAM_TERMINATED',
      targetType: 'LIVE_STREAM',
      targetId: id,
      before,
      after: { status: 'ENDED' },
      reason,
    });

    return updated;
  }

  async deleteStream(id: string, actorId: string, reason?: string) {
    const stream = await this.prisma.liveStream.findUnique({ where: { id } });
    if (!stream) {
      throw new NotFoundException(`LiveStream ${id} not found`);
    }

    await this.prisma.liveStream.delete({ where: { id } });

    await this.auditService.log({
      actorId,
      action: 'STREAM_DELETED',
      targetType: 'LIVE_STREAM',
      targetId: id,
      before: { title: stream.title, createdById: stream.createdById },
      reason,
    });

    return { success: true, message: 'Stream deleted successfully' };
  }

  async listStreamChat(
    streamId: string,
    query: { page?: number; limit?: number },
  ) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 50));
    const skip = (page - 1) * limit;

    const stream = await this.prisma.liveStream.findUnique({
      where: { id: streamId },
      include: { chatRoom: true },
    });

    if (!stream || !stream.chatRoom) {
      return {
        items: [],
        total: 0,
        page,
        limit,
        totalPages: 0,
        hasNext: false,
      };
    }

    const [items, total] = await Promise.all([
      this.prisma.streamChatMessage.findMany({
        where: { chatRoomId: stream.chatRoom.id },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          sender: {
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
      this.prisma.streamChatMessage.count({
        where: { chatRoomId: stream.chatRoom.id },
      }),
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

  async deleteChatMessage(messageId: string, actorId: string, reason?: string) {
    const msg = await this.prisma.streamChatMessage.findUnique({
      where: { id: messageId },
    });
    if (!msg) {
      throw new NotFoundException(`Stream chat message ${messageId} not found`);
    }

    await this.prisma.streamChatMessage.delete({ where: { id: messageId } });

    await this.auditService.log({
      actorId,
      action: 'STREAM_CHAT_MESSAGE_DELETED',
      targetType: 'STREAM_CHAT_MESSAGE',
      targetId: messageId,
      before: { senderId: msg.senderId, content: msg.content.slice(0, 100) },
      reason,
    });

    return { success: true, message: 'Chat message deleted' };
  }
}
