import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConversationsRepository } from './conversations.repository.js';
import { UsersRepository } from '../users/users.repository.js';
import { ConversationResponseDto } from './dto/conversation-response.dto.js';
import {
  ChatDiscoveryResponseDto,
  ChatGroupItemDto,
  ChatUserItemDto,
} from './dto/chat-discovery-response.dto.js';

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

  async findOrCreateGroupConversation(
    groupId: string,
    userId: string,
  ): Promise<ConversationResponseDto> {
    const conv =
      await this.conversationsRepository.findOrCreateGroupConversation(
        groupId,
        userId,
      );
    return this.mapToDto(conv, userId);
  }

  async getChatDiscovery(userId: string): Promise<ChatDiscoveryResponseDto> {
    try {
      const [conversations, allUsers, publicGroups, myPrivateGroups] =
        await Promise.all([
          this.getUserConversations(userId),
          this.conversationsRepository.getAllUsersSortedNewest(userId),
          this.conversationsRepository.getAllPublicGroupsSortedNewest(),
          this.conversationsRepository.getUserPrivateGroups(userId),
        ]);

      const formattedUsers: ChatUserItemDto[] = allUsers.map((u) => {
        const isOnline = u.presence?.status === 'ONLINE';
        return {
          id: u.id,
          username: u.username,
          displayName: u.profile?.displayName ?? u.username ?? 'User',
          avatarUrl: u.profile?.avatar?.url ?? null,
          bio: u.profile?.bio ?? null,
          isOnline,
          lastSeenAt: u.presence?.lastSeenAt ?? u.lastLoginAt ?? null,
          createdAt: u.createdAt,
        };
      });

      const formattedPublicGroups: ChatGroupItemDto[] = publicGroups.map((g) => ({
        id: g.id,
        name: g.name,
        slug: g.slug,
        description: g.description,
        avatarUrl: g.avatarUrl,
        coverUrl: g.coverUrl,
        visibility: g.visibility,
        status: g.status,
        membersCount: g._count?.members ?? 0,
        conversationId: g.conversations?.[0]?.id ?? null,
        isMember: true,
        createdAt: g.createdAt,
      }));

      const formattedPrivateGroups: ChatGroupItemDto[] = myPrivateGroups.map((g) => ({
        id: g.id,
        name: g.name,
        slug: g.slug,
        description: g.description,
        avatarUrl: g.avatarUrl,
        coverUrl: g.coverUrl,
        visibility: g.visibility,
        status: g.status,
        membersCount: g._count?.members ?? 0,
        conversationId: g.conversations?.[0]?.id ?? null,
        isMember: true,
        createdAt: g.createdAt,
      }));

      return {
        conversations,
        publicGroups: formattedPublicGroups,
        myPrivateGroups: formattedPrivateGroups,
        allUsers: formattedUsers,
      };
    } catch (error) {
      console.error('Error in getChatDiscovery:', error);
      // Return empty data rather than throwing
      return {
        conversations: [],
        publicGroups: [],
        myPrivateGroups: [],
        allUsers: [],
      };
    }
  }

  async getUserConversations(
    userId: string,
  ): Promise<ConversationResponseDto[]> {
    const conversations =
      await this.conversationsRepository.getUserConversations(userId);
    return conversations.map((conv) => this.mapToDto(conv, userId));
  }

  async getConversationUpdates(
    userId: string,
    since?: string,
  ) {
    const sinceDate = since ? new Date(since) : new Date(0);
    const conversations =
      await this.conversationsRepository.getUserConversations(userId);

    const updated = conversations.filter(
      (c: any) =>
        new Date(c.updatedAt) > sinceDate ||
        (c.lastMessageAt && new Date(c.lastMessageAt) > sinceDate),
    );

    return {
      conversations: updated.map((conv: any) => this.mapToDto(conv, userId)),
      serverTimestamp: new Date().toISOString(),
    };
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

