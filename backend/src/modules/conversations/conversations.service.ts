// src/modules/conversations/conversations.service.ts
import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
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
      throw new BadRequestException(
        'You cannot start a direct chat with yourself',
      );
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

  async getUserConversations(
    userId: string,
  ): Promise<ConversationResponseDto[]> {
    const conversations =
      await this.conversationsRepository.getUserConversations(userId);
    return conversations.map((conv) => this.mapToDto(conv, userId));
  }

  async getConversationById(
    conversationId: string,
    userId: string,
  ): Promise<ConversationResponseDto> {
    const conversation =
      await this.conversationsRepository.findById(conversationId);
    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    return this.mapToDto(conversation, userId);
  }

  async muteConversation(
    conversationId: string,
    userId: string,
  ): Promise<void> {
    await this.conversationsRepository.updateMemberSetting(
      conversationId,
      userId,
      { isMuted: true },
    );
  }

  async unmuteConversation(
    conversationId: string,
    userId: string,
  ): Promise<void> {
    await this.conversationsRepository.updateMemberSetting(
      conversationId,
      userId,
      { isMuted: false },
    );
  }

  async pinConversation(
    conversationId: string,
    userId: string,
  ): Promise<void> {
    await this.conversationsRepository.updateMemberSetting(
      conversationId,
      userId,
      { isPinned: true },
    );
  }

  async unpinConversation(
    conversationId: string,
    userId: string,
  ): Promise<void> {
    await this.conversationsRepository.updateMemberSetting(
      conversationId,
      userId,
      { isPinned: false },
    );
  }

  async markAsRead(conversationId: string, userId: string): Promise<void> {
    await this.conversationsRepository.resetUnreadCount(conversationId, userId);
  }

  private mapToDto(conv: any, currentUserId: string): ConversationResponseDto {
    let title: string | null = null;

    if (conv.type === 'DIRECT') {
      const otherMember = conv.members?.find(
        (m: any) => m.userId !== currentUserId,
      );
      title =
        otherMember?.user?.profile?.displayName ??
        otherMember?.user?.username ??
        'Direct Chat';
    } else if (conv.channel?.name) {
      title = `#${conv.channel.name}`;
    } else if (conv.group?.name) {
      title = conv.group.name;
    }

    const latestMsg = conv.messages && conv.messages.length > 0 ? conv.messages[0] : null;
    let lastMessage: any = undefined;
    if (latestMsg) {
      lastMessage = {
        id: latestMsg.id,
        content: latestMsg.content,
        type: latestMsg.type,
        senderName: latestMsg.sender?.profile?.displayName ?? latestMsg.sender?.username ?? 'User',
        isMe: latestMsg.senderId === currentUserId,
      };
    }

    return {
      id: conv.id,
      type: conv.type,
      groupId: conv.groupId,
      channelId: conv.channelId,
      title,
      lastMessageSnippet: latestMsg?.content ?? null,
      lastMessageAt: conv.lastMessageAt ?? latestMsg?.createdAt ?? null,
      lastMessage,
      members: (conv.members ?? []).map((m: any) => ({
        userId: m.user.id,
        username: m.user.username,
        displayName: m.user.profile?.displayName ?? m.user.username,
        avatarUrl: m.user.profile?.avatar?.url ?? null,
        unreadCount: m.unreadCount ?? 0,
        isMuted: m.isMuted ?? false,
        isPinned: m.isPinned ?? false,
      })),
      metadata: conv.group
        ? {
            groupName: conv.group.name,
            groupAvatar: conv.group.avatarUrl ?? null,
            channelName: conv.channel?.name ?? null,
          }
        : undefined,
      createdAt: conv.createdAt,
    };
  }
}
