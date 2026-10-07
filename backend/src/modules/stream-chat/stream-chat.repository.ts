import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { StreamChatMessage, StreamChatRoom, Prisma } from '@prisma/client';

/** Flatten the Prisma nested sender shape into what Flutter expects:
 *  { id, username, displayName, avatarUrl }
 */
function normalizeSenderShape(message: any): any {
  if (!message) return message;
  const { sender, ...rest } = message;
  if (!sender) return message;
  return {
    ...rest,
    sender: {
      id: sender.id,
      username: sender.username ?? null,
      displayName:
        sender.profile?.displayName ??
        sender.displayName ??
        sender.username ??
        null,
      avatarUrl:
        sender.profile?.avatar?.url ?? sender.avatarUrl ?? null,
    },
  };
}

@Injectable()
export class StreamChatRepository {
  constructor(private readonly prisma: PrismaService) {}

  async getChatRoomByStreamId(
    liveStreamId: string,
  ): Promise<StreamChatRoom | null> {
    return this.prisma.streamChatRoom.findUnique({
      where: { liveStreamId },
    });
  }

  async ensureChatRoomExists(liveStreamId: string): Promise<StreamChatRoom> {
    const room = await this.getChatRoomByStreamId(liveStreamId);
    if (room) return room;

    return this.prisma.streamChatRoom.create({
      data: { liveStreamId },
    });
  }

  async saveMessage(
    data: Prisma.StreamChatMessageUncheckedCreateInput,
  ): Promise<any> {
    const message = await this.prisma.streamChatMessage.create({
      data,
      include: {
        sender: {
          select: {
            id: true,
            username: true,
            profile: {
              select: { displayName: true, avatar: { select: { url: true } } },
            },
            role: { select: { name: true } },
          },
        },
      },
    });
    return normalizeSenderShape(message);
  }

  async getMessages(
    chatRoomId: string,
    limit: number,
    cursor?: string,
  ): Promise<any[]> {
    const args: Prisma.StreamChatMessageFindManyArgs = {
      where: { chatRoomId, deletedAt: null },
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        sender: {
          select: {
            id: true,
            username: true,
            profile: {
              select: { displayName: true, avatar: { select: { url: true } } },
            },
          },
        },
      },
    };

    if (cursor) {
      args.cursor = { id: cursor };
      args.skip = 1;
    }

    const messages = await this.prisma.streamChatMessage.findMany(args);
    // Return in chronological order with flat sender shape
    return messages.reverse().map(normalizeSenderShape);
  }

  async getMessageById(messageId: string): Promise<StreamChatMessage | null> {
    return this.prisma.streamChatMessage.findUnique({
      where: { id: messageId },
    });
  }

  async deleteMessage(messageId: string): Promise<StreamChatMessage> {
    return this.prisma.streamChatMessage.update({
      where: { id: messageId },
      data: { deletedAt: new Date() },
    });
  }

  async pinMessage(
    messageId: string,
    isPinned: boolean,
  ): Promise<StreamChatMessage> {
    return this.prisma.streamChatMessage.update({
      where: { id: messageId },
      data: { isPinned, pinnedAt: isPinned ? new Date() : null },
    });
  }
}
