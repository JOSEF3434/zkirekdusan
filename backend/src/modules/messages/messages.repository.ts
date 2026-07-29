// src/modules/messages/messages.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { SendMessageDto } from './dto/send-message.dto.js';

const MESSAGE_INCLUDE = {
  sender: {
    select: {
      id: true,
      username: true,
      profile: { select: { displayName: true, avatar: { select: { url: true } } } },
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
        },
      },
    },
  },
  reactions: { select: { emoji: true, userId: true } },
  reads: { select: { userId: true } },
  replyTo: {
    select: {
      id: true,
      content: true,
      sender: {
        select: {
          id: true,
          username: true,
          profile: { select: { displayName: true } },
        },
      },
    },
  },
} as const;

@Injectable()
export class MessagesRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    conversationId: string,
    senderId: string,
    dto: SendMessageDto,
    channelId?: string,
  ) {
    return this.prisma.message.create({
      data: {
        conversationId,
        senderId,
        channelId: channelId ?? null,
        content: dto.content,
        type: dto.type,
        replyToId: dto.replyToId ?? null,
        attachments:
          dto.fileIds && dto.fileIds.length > 0
            ? {
                create: dto.fileIds.map((fileId) => ({ fileId })),
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

  async addReaction(messageId: string, userId: string, emoji: string) {
    return this.prisma.messageReaction.upsert({
      where: { messageId_userId_emoji: { messageId, userId, emoji } },
      create: { messageId, userId, emoji },
      update: {},
    });
  }

  async removeReaction(messageId: string, userId: string, emoji: string) {
    return this.prisma.messageReaction.delete({
      where: { messageId_userId_emoji: { messageId, userId, emoji } },
    });
  }

  async markAsRead(messageId: string, userId: string) {
    await this.prisma.messageRead.upsert({
      where: { messageId_userId: { messageId, userId } },
      create: { messageId, userId },
      update: {},
    });
  }

  async pinMessage(conversationId: string, messageId: string, pinnedById: string) {
    return this.prisma.pinnedMessage.upsert({
      where: { conversationId_messageId: { conversationId, messageId } },
      create: { conversationId, messageId, pinnedById },
      update: {},
    });
  }

  async unpinMessage(conversationId: string, messageId: string) {
    return this.prisma.pinnedMessage.delete({
      where: { conversationId_messageId: { conversationId, messageId } },
    });
  }

  async starMessage(userId: string, messageId: string) {
    return this.prisma.starredMessage.upsert({
      where: { userId_messageId: { userId, messageId } },
      create: { userId, messageId },
      update: {},
    });
  }

  async unstarMessage(userId: string, messageId: string) {
    return this.prisma.starredMessage.delete({
      where: { userId_messageId: { userId, messageId } },
    });
  }

  async getStarredMessages(userId: string) {
    return this.prisma.starredMessage.findMany({
      where: { userId },
      include: {
        message: { include: MESSAGE_INCLUDE },
      },
      orderBy: { starredAt: 'desc' },
    });
  }

  async getPinnedMessages(conversationId: string) {
    return this.prisma.pinnedMessage.findMany({
      where: { conversationId },
      include: {
        message: { include: MESSAGE_INCLUDE },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateConversationLastMessage(conversationId: string, messageId: string) {
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

  async incrementUnreadCountForOthers(conversationId: string, excludeUserId: string) {
    return this.prisma.conversationMember.updateMany({
      where: { conversationId, userId: { not: excludeUserId } },
      data: { unreadCount: { increment: 1 } },
    });
  }
}
