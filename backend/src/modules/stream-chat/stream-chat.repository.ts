import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { StreamChatMessage, StreamChatRoom, Prisma } from '@prisma/client';

@Injectable()
export class StreamChatRepository {
  constructor(private readonly prisma: PrismaService) {}

  async getChatRoomByStreamId(liveStreamId: string): Promise<StreamChatRoom | null> {
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

  async saveMessage(data: Prisma.StreamChatMessageUncheckedCreateInput): Promise<StreamChatMessage> {
    return this.prisma.streamChatMessage.create({
      data,
      include: {
        sender: {
          select: { id: true, username: true, profile: { select: { avatarUrl: true } }, role: { select: { name: true } } },
        },
      },
    });
  }

  async getMessages(
    chatRoomId: string,
    limit: number,
    cursor?: string,
  ): Promise<StreamChatMessage[]> {
    const args: Prisma.StreamChatMessageFindManyArgs = {
      where: { chatRoomId, deletedAt: null },
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        sender: {
          select: { id: true, username: true, profile: { select: { avatarUrl: true } } },
        },
      },
    };

    if (cursor) {
      args.cursor = { id: cursor };
      args.skip = 1;
    }

    const messages = await this.prisma.streamChatMessage.findMany(args);
    return messages.reverse(); // Return in chronological order
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

  async pinMessage(messageId: string, isPinned: boolean): Promise<StreamChatMessage> {
    return this.prisma.streamChatMessage.update({
      where: { id: messageId },
      data: { isPinned, pinnedAt: isPinned ? new Date() : null },
    });
  }
}
