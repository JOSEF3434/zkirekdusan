// src/modules/conversations/conversations.service.ts
import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { ConversationsRepository } from './conversations.repository.js';
import { UsersRepository } from '../users/users.repository.js';
import { ConversationResponseDto } from './dto/conversation-response.dto.js';

@Injectable()
export class ConversationsService {
  constructor(
    private readonly conversationsRepository: ConversationsRepository,
    private readonly usersRepository: UsersRepository,
  ) {}

  async createDirectConversation(
    currentUserId: string,
    recipientId: string,
  ): Promise<ConversationResponseDto> {
    if (currentUserId === recipientId) {
      throw new BadRequestException('You cannot start a direct chat with yourself');
    }

    const recipient = await this.usersRepository.findById(recipientId);
    if (!recipient) {
      throw new NotFoundException('Recipient user not found');
    }

    const conversation = await this.conversationsRepository.findOrCreateDirect(
      currentUserId,
      recipientId,
    );
    return this.mapToDto(conversation, currentUserId);
  }

  async getUserConversations(userId: string): Promise<ConversationResponseDto[]> {
    const conversations = await this.conversationsRepository.getUserConversations(userId);
    return conversations.map((conv) => this.mapToDto(conv, userId));
  }

  async getConversationById(conversationId: string, userId: string): Promise<ConversationResponseDto> {
    const conversation = await this.conversationsRepository.findById(conversationId);
    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    return this.mapToDto(conversation, userId);
  }

  private mapToDto(conv: any, currentUserId: string): ConversationResponseDto {
    let title: string | null = null;

    if (conv.type === 'DIRECT') {
      const otherMember = conv.members?.find((m: any) => m.userId !== currentUserId);
      title = otherMember?.user?.profile?.displayName ?? otherMember?.user?.username ?? 'Direct Chat';
    } else if (conv.channel?.name) {
      title = `#${conv.channel.name}`;
    }

    return {
      id: conv.id,
      type: conv.type,
      groupId: conv.groupId,
      channelId: conv.channelId,
      title,
      lastMessageAt: conv.lastMessageAt,
      members: (conv.members ?? []).map((m: any) => ({
        userId: m.user.id,
        username: m.user.username,
        displayName: m.user.profile?.displayName ?? m.user.username,
        avatarUrl: m.user.profile?.avatar?.url ?? null,
        unreadCount: m.unreadCount ?? 0,
        isMuted: m.isMuted ?? false,
      })),
      createdAt: conv.createdAt,
    };
  }
}
