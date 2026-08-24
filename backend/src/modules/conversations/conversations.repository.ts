// src/modules/conversations/conversations.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class ConversationsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findOrCreateDirect(userId1: string, userId2: string) {
    // Find existing direct conversation between these two users
    const existing = await this.prisma.conversation.findFirst({
      where: {
        type: 'DIRECT',
        AND: [
          { members: { some: { userId: userId1 } } },
          { members: { some: { userId: userId2 } } },
        ],
      },
      include: {
        members: {
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
        channel: { select: { name: true } },
      },
    });

    if (existing) return existing;

    // Create new direct conversation
    return this.prisma.conversation.create({
      data: {
        type: 'DIRECT',
        members: {
          create: [{ userId: userId1 }, { userId: userId2 }],
        },
      },
      include: {
        members: {
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
        channel: { select: { name: true } },
      },
    });
  }

  async findById(id: string) {
    return this.prisma.conversation.findUnique({
      where: { id },
      include: {
        members: {
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
        channel: { select: { name: true, isPrivate: true, groupId: true } },
      },
    });
  }

  async getUserConversations(userId: string) {
    return this.prisma.conversation.findMany({
      where: {
        members: { some: { userId } },
      },
      include: {
        members: {
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
        channel: { select: { name: true } },
      },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async updateLastMessage(conversationId: string, lastMessageId: string) {
    return this.prisma.conversation.update({
      where: { id: conversationId },
      data: {
        lastMessageId,
        lastMessageAt: new Date(),
      },
    });
  }
}

  async updateMemberSetting(
    conversationId: string,
    userId: string,
    settings: { isMuted?: boolean; isPinned?: boolean },
  ) {
    return this.prisma.conversationMember.updateMany({
      where: {
        conversationId,
        userId,
      },
      data: settings,
    });
  }

  async resetUnreadCount(conversationId: string, userId: string) {
    return this.prisma.conversationMember.updateMany({
      where: {
        conversationId,
        userId,
      },
      data: {
        unreadCount: 0,
      },
    });
  }
