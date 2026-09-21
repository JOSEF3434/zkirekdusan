// src/modules/admin/services/admin-chat.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';

@Injectable()
export class AdminChatService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AdminAuditService,
  ) {}

  async listConversations(query: {
    page?: number;
    limit?: number;
    type?: string;
    search?: string;
  }) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {};
    if (query.type && query.type !== 'ALL') {
      where.type = query.type;
    }

    const [items, total] = await Promise.all([
      this.prisma.conversation.findMany({
        where,
        skip,
        take: limit,
        orderBy: { lastMessageAt: 'desc' },
        include: {
          group: { select: { id: true, name: true } },
          channel: { select: { id: true, name: true } },
          members: {
            take: 5,
            include: {
              user: {
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
          },
          _count: {
            select: { messages: true, members: true },
          },
        },
      }),
      this.prisma.conversation.count({ where }),
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

  async listMessages(
    conversationId: string,
    query: { page?: number; limit?: number; search?: string },
  ) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 30));
    const skip = (page - 1) * limit;

    const where: any = { conversationId };
    if (query.search) {
      where.content = { contains: query.search, mode: 'insensitive' };
    }

    const [items, total] = await Promise.all([
      this.prisma.message.findMany({
        where,
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
      this.prisma.message.count({ where }),
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

  async deleteMessage(messageId: string, actorId: string, reason?: string) {
    const message = await this.prisma.message.findUnique({
      where: { id: messageId },
    });
    if (!message) {
      throw new NotFoundException(`Message ${messageId} not found`);
    }

    await this.prisma.message.delete({ where: { id: messageId } });

    await this.auditService.log({
      actorId,
      action: 'CHAT_MESSAGE_DELETED',
      targetType: 'MESSAGE',
      targetId: messageId,
      before: {
        senderId: message.senderId,
        content: message.content?.slice(0, 100),
      },
      reason,
    });

    return { success: true, message: 'Message deleted successfully' };
  }

  async purgeConversation(
    conversationId: string,
    actorId: string,
    reason?: string,
  ) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });
    if (!conversation) {
      throw new NotFoundException(`Conversation ${conversationId} not found`);
    }

    // Delete messages in the conversation
    const deleted = await this.prisma.message.deleteMany({
      where: { conversationId },
    });

    await this.auditService.log({
      actorId,
      action: 'CONVERSATION_PURGED',
      targetType: 'CONVERSATION',
      targetId: conversationId,
      before: { deletedMessagesCount: deleted.count },
      reason,
    });

    return {
      success: true,
      message: `Purged ${deleted.count} messages from conversation`,
      deletedCount: deleted.count,
    };
  }
}
