// src/modules/channels/channels.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CreateChannelDto } from './dto/create-channel.dto.js';
import { UpdateChannelDto } from './dto/update-channel.dto.js';

@Injectable()
export class ChannelsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createChannel(groupId: string, dto: CreateChannelDto) {
    return this.prisma.$transaction(async (tx) => {
      const channel = await tx.channel.create({
        data: {
          groupId,
          name: dto.name,
          slug: dto.slug,
          type: dto.type ?? 'TEXT',
          description: dto.description,
          isPrivate: dto.isPrivate ?? false,
        },
      });

      // Automatically create linked Conversation entity for the channel
      const conversation = await tx.conversation.create({
        data: {
          type: 'GROUP_CHANNEL',
          groupId,
          channelId: channel.id,
        },
      });

      return { ...channel, conversationId: conversation.id };
    });
  }

  async findById(id: string) {
    return this.prisma.channel.findFirst({
      where: { id, deletedAt: null },
      include: {
        conversations: { select: { id: true } },
      },
    });
  }

  async findBySlug(groupId: string, slug: string) {
    return this.prisma.channel.findFirst({
      where: { groupId, slug, deletedAt: null },
      include: {
        conversations: { select: { id: true } },
      },
    });
  }

  async findByGroup(groupId: string, isPrivateFilter?: boolean) {
    return this.prisma.channel.findMany({
      where: {
        groupId,
        deletedAt: null,
        ...(typeof isPrivateFilter === 'boolean'
          ? { isPrivate: isPrivateFilter }
          : {}),
      },
      include: {
        conversations: { select: { id: true } },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async updateChannel(id: string, dto: UpdateChannelDto) {
    return this.prisma.channel.update({
      where: { id },
      data: dto,
      include: {
        conversations: { select: { id: true } },
      },
    });
  }

  async softDeleteChannel(id: string) {
    return this.prisma.channel.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }
}
