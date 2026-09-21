// src/modules/messages/messages.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { SendMessageDto } from './dto/send-message.dto.js';

const MESSAGE_INCLUDE = {
  sender: {
    select: {
      id: true,
      username: true,
      profile: {
        select: { displayName: true, avatar: { select: { url: true } } },
      },
    },
  },
  attachments: {
    include: {
      file: {
        select: {
          id: true,
          url: true,
          fileType: true,
          mimeType: true,
          originalName: true,
          size: true,
          width: true,
          height: true,
          duration: true,
          thumbnailUrl: true,
        },
      },
    },
  },
  reactions: { select: { emoji: true, userId: true } },
  reads: { select: { userId: true } },
  deliveries: { select: { userId: true } },
  replyTo: {
    select: {
      id: true,
      content: true,
      type: true,
      sender: {
        select: {
          id: true,
          username: true,
          profile: { select: { displayName: true } },
        },
      },
      attachments: {
        include: {
          file: {
            select: {
              id: true,
              url: true,
              fileType: true,
              mimeType: true,
              originalName: true,
              thumbnailUrl: true,
            },
          },
        },
      },
    },
  },
  voiceNote: {
    include: {
      file: { select: { url: true } },
    },
  },
  forward: {
    include: {
      originalSender: {
        select: {
          id: true,
          username: true,
          profile: {
            select: { displayName: true, avatar: { select: { url: true } } },
          },
        },
      },
    },
  },
  mentions: {
    select: { mentionedUserId: true },
  },
  conversation: {
    select: {
      id: true,
      type: true,
      groupId: true,
      members: { select: { userId: true } },
      group: {
        select: {
          createdById: true,
          members: { select: { userId: true, role: true } },
        },
      },
    },
  },
} as const;

@Injectable()
export class MessagesRepository {
  constructor(private readonly prisma: PrismaService) { }

  async create(
    conversationId: string,
    senderId: string,
    dto: SendMessageDto,
    channelId?: string,
  ) {
    if (dto.clientId) {
      // Idempotency check: if message with this clientId from this sender already exists, return it
      const existing = await this.prisma.message.findFirst({
        where: {
          senderId,
          clientId: dto.clientId,
        },
        include: MESSAGE_INCLUDE,
      });
      if (existing) {
        return existing;
      }
    }

    return this.prisma.message.create({
      data: {
        conversationId,
        senderId,
        channelId: channelId ?? null,
        clientId: dto.clientId ?? null,
        content: dto.content,
        type: dto.type,
        replyToId: dto.replyToId ?? null,
        attachments:
          dto.fileIds && dto.fileIds.length > 0
            ? { create: dto.fileIds.map((fileId) => ({ fileId })) }
            : undefined,
        forward: dto.forwardFromMessageId
          ? {
            create: {
              originalMessageId: dto.forwardFromMessageId,
              originalSenderId: senderId,
              originalConversationId:
                dto.forwardFromConversationId ?? conversationId,
            },
          }
          : undefined,
        mentions:
          dto.mentionedUserIds && dto.mentionedUserIds.length > 0
            ? {
              create: dto.mentionedUserIds.map((userId) => ({
                mentionedUserId: userId,
              })),
            }
            : undefined,
      },
      include: MESSAGE_INCLUDE,
    });
  }

  async findByConversation(
    conversationId: string,
    cursor?: string,
    limit = 50,
  ) {
    const messages = await this.prisma.message.findMany({
      where: {
        conversationId,
        deletedForEveryoneAt: null,
      },
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      take: limit + 1,
      orderBy: { createdAt: 'desc' },
      include: MESSAGE_INCLUDE,
    });

    const hasMore = messages.length > limit;
    const data = hasMore ? messages.slice(0, limit) : messages;
    const nextCursor = hasMore ? data[data.length - 1].id : undefined;

    return { data, hasMore, nextCursor };
  }

  async findById(id: string) {
    return this.prisma.message.findUnique({
      where: { id },
      include: MESSAGE_INCLUDE,
    });
  }

  async update(id: string, content: string) {
    return this.prisma.message.update({
      where: { id },
      data: { content, isEdited: true },
      include: MESSAGE_INCLUDE,
    });
  }

  async deleteForEveryone(id: string) {
    return this.prisma.message.update({
      where: { id },
      data: { deletedForEveryoneAt: new Date(), content: null },
    });
  }

  async bulkDeleteForEveryone(ids: string[], senderId: string) {
    return this.prisma.message.updateMany({
      where: { id: { in: ids }, senderId },
      data: { deletedForEveryoneAt: new Date(), content: null },
    });
  }

  async addReaction(messageId: string, userId: string, emoji: string) {
    return this.prisma.$transaction(async (tx) => {
      await tx.messageReaction.deleteMany({
        where: {
          messageId,
          userId,
          emoji: { not: emoji },
        },
      });

      return tx.messageReaction.upsert({
        where: { messageId_userId_emoji: { messageId, userId, emoji } },
        create: { messageId, userId, emoji },
        update: {},
      });
    });
  }

  async removeReaction(messageId: string, userId: string, emoji: string) {
    return this.prisma.messageReaction.deleteMany({
      where: { messageId, userId, emoji },
    });
  }

  async markAsRead(messageId: string, userId: string) {
    await this.prisma.messageRead.upsert({
      where: { messageId_userId: { messageId, userId } },
      create: { messageId, userId },
      update: {},
    });
  }

  async markBulkAsRead(conversationId: string, userId: string) {
    // Get all unread messages in conversation
    const unread = await this.prisma.message.findMany({
      where: {
        conversationId,
        deletedForEveryoneAt: null,
        reads: { none: { userId } },
        senderId: { not: userId },
      },
      select: { id: true },
    });
    if (unread.length === 0) return;
    await this.prisma.messageRead.createMany({
      data: unread.map((m) => ({ messageId: m.id, userId })),
      skipDuplicates: true,
    });
  }

  async markDelivered(messageId: string, userId: string) {
    await this.prisma.messageDelivery.upsert({
      where: { messageId_userId: { messageId, userId } },
      create: { messageId, userId },
      update: {},
    });
  }

  async pinMessage(
    conversationId: string,
    messageId: string,
    pinnedById: string,
  ) {
    return this.prisma.$transaction([
      this.prisma.pinnedMessage.upsert({
        where: { conversationId_messageId: { conversationId, messageId } },
        create: { conversationId, messageId, pinnedById },
        update: {},
      }),
      this.prisma.message.update({
        where: { id: messageId },
        data: { isPinned: true },
      }),
    ]);
  }

  async unpinMessage(conversationId: string, messageId: string) {
    return this.prisma.$transaction([
      this.prisma.pinnedMessage.delete({
        where: { conversationId_messageId: { conversationId, messageId } },
      }),
      this.prisma.message.update({
        where: { id: messageId },
        data: { isPinned: false },
      }),
    ]);
  }

  async starMessage(userId: string, messageId: string) {
    return this.prisma.starredMessage.upsert({
      where: { userId_messageId: { userId, messageId } },
      create: { userId, messageId },
      update: {},
    });
  }

  async unstarMessage(userId: string, messageId: string) {
    return this.prisma.starredMessage.deleteMany({
      where: { userId, messageId },
    });
  }

  async getStarredMessages(userId: string) {
    return this.prisma.starredMessage.findMany({
      where: { userId },
      include: { message: { include: MESSAGE_INCLUDE } },
      orderBy: { starredAt: 'desc' },
    });
  }

  async getPinnedMessages(conversationId: string) {
    return this.prisma.pinnedMessage.findMany({
      where: { conversationId },
      include: { message: { include: MESSAGE_INCLUDE } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async searchMessages(conversationId: string, query: string, limit = 30) {
    return this.prisma.message.findMany({
      where: {
        conversationId,
        deletedForEveryoneAt: null,
        content: { contains: query, mode: 'insensitive' },
      },
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: MESSAGE_INCLUDE,
    });
  }

  async updateConversationLastMessage(
    conversationId: string,
    messageId: string,
  ) {
    return this.prisma.conversation.update({
      where: { id: conversationId },
      data: { lastMessageId: messageId, lastMessageAt: new Date() },
    });
  }

  async resetUnreadCount(conversationId: string, userId: string) {
    return this.prisma.conversationMember.updateMany({
      where: { conversationId, userId },
      data: { unreadCount: 0 },
    });
  }

  async incrementUnreadCountForOthers(
    conversationId: string,
    excludeUserId: string,
  ) {
    return this.prisma.conversationMember.updateMany({
      where: { conversationId, userId: { not: excludeUserId } },
      data: { unreadCount: { increment: 1 } },
    });
  }

  async muteConversation(
    conversationId: string,
    userId: string,
    muted: boolean,
  ) {
    return this.prisma.conversationMember.updateMany({
      where: { conversationId, userId },
      data: { isMuted: muted },
    });
  }

  async pinConversation(
    conversationId: string,
    userId: string,
    pinned: boolean,
  ) {
    return this.prisma.conversationMember.updateMany({
      where: { conversationId, userId },
      data: { isPinned: pinned },
    });
  }

  async blockUser(blockerId: string, blockedUserId: string) {
    return this.prisma.conversationBlock.upsert({
      where: { blockerId_blockedUserId: { blockerId, blockedUserId } },
      create: { blockerId, blockedUserId },
      update: {},
    });
  }

  async unblockUser(blockerId: string, blockedUserId: string) {
    return this.prisma.conversationBlock.deleteMany({
      where: { blockerId, blockedUserId },
    });
  }

  async isBlocked(blockerId: string, blockedUserId: string): Promise<boolean> {
    const block = await this.prisma.conversationBlock.findFirst({
      where: { blockerId, blockedUserId },
    });
    return !!block;
  }

  async getTotalUnreadCount(userId: string): Promise<number> {
    const result = await this.prisma.conversationMember.aggregate({
      where: { userId },
      _sum: { unreadCount: true },
    });
    return result._sum.unreadCount ?? 0;
  }

  async getUpdatesSince(conversationId: string, since: Date, limit = 100) {
    const activeMessages = await this.prisma.message.findMany({
      where: {
        conversationId,
        updatedAt: { gt: since },
        deletedForEveryoneAt: null,
      },
      orderBy: { updatedAt: 'asc' },
      take: limit,
      include: MESSAGE_INCLUDE,
    });

    const deletedMessages = await this.prisma.message.findMany({
      where: {
        conversationId,
        deletedForEveryoneAt: { gt: since },
      },
      select: {
        id: true,
        deletedForEveryoneAt: true,
      },
      take: limit,
    });

    return {
      messages: activeMessages,
      deletedIds: deletedMessages.map((m) => m.id),
    };
  }
}
