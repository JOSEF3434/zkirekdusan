import {
  ForbiddenException,
  Injectable,
  NotFoundException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { MessagesRepository } from './messages.repository.js';
import { ConversationsRepository } from '../conversations/conversations.repository.js';
import { MessagingGateway } from '../messaging-gateway/messaging.gateway.js';
import { SendMessageDto } from './dto/send-message.dto.js';
import { EditMessageDto } from './dto/edit-message.dto.js';
import { AddReactionDto } from './dto/add-reaction.dto.js';
import {
  MessageResponseDto,
  PaginatedMessagesDto,
} from './dto/message-response.dto.js';

@Injectable()
export class MessagesService {
  constructor(
    private readonly messagesRepository: MessagesRepository,
    private readonly conversationsRepository: ConversationsRepository,
    @Inject(forwardRef(() => MessagingGateway))
    private readonly messagingGateway: MessagingGateway,
  ) {}

  // ── Send a message to a conversation (DM or Channel) ──────────────────────

  async sendMessage(
    conversationId: string,
    senderId: string,
    dto: SendMessageDto,
  ): Promise<MessageResponseDto> {
    const conversation =
      await this.conversationsRepository.findById(conversationId);
    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    const isMember = conversation.members.some(
      (m: any) => m.userId === senderId,
    );
    if (!isMember) {
      throw new ForbiddenException('You are not a member of this conversation');
    }

    const message = await this.messagesRepository.create(
      conversationId,
      senderId,
      dto,
      conversation.channelId ?? undefined,
    );

    // Update conversation last message & unread counts
    await this.messagesRepository.updateConversationLastMessage(
      conversationId,
      message.id,
    );
    await this.messagesRepository.incrementUnreadCountForOthers(
      conversationId,
      senderId,
    );

    const messageDto = this.mapToDto(message);
    const memberIds = conversation.members
      ? conversation.members.map((m: any) => m.userId)
      : [];
    this.messagingGateway.emitNewMessage(conversationId, messageDto, memberIds);

    return messageDto;
  }

  // ── Get paginated message history ─────────────────────────────────────────

  async getMessages(
    conversationId: string,
    userId: string,
    cursor?: string,
    limit = 50,
  ): Promise<PaginatedMessagesDto> {
    const conversation =
      await this.conversationsRepository.findById(conversationId);
    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    const isMember = conversation.members.some((m: any) => m.userId === userId);
    if (!isMember) {
      throw new ForbiddenException('You are not a member of this conversation');
    }

    const result = await this.messagesRepository.findByConversation(
      conversationId,
      cursor,
      limit,
    );

    // Mark all messages as read
    await this.messagesRepository.resetUnreadCount(conversationId, userId);

    return {
      data: result.data.map((m) => this.mapToDto(m)),
      nextCursor: result.nextCursor,
      hasMore: result.hasMore,
    };
  }

  // ── Edit message (owner only) ──────────────────────────────────────────────

  async editMessage(
    messageId: string,
    userId: string,
    dto: EditMessageDto,
  ): Promise<MessageResponseDto> {
    const message = await this.messagesRepository.findById(messageId);
    if (!message) {
      throw new NotFoundException('Message not found');
    }

    if (message.senderId !== userId) {
      throw new ForbiddenException('You can only edit your own messages');
    }

    if (message.deletedForEveryoneAt) {
      throw new ForbiddenException('Cannot edit a deleted message');
    }

    const updated = await this.messagesRepository.update(
      messageId,
      dto.content,
    );
    const updatedDto = this.mapToDto(updated);
    this.messagingGateway.emitMessageUpdated(message.conversationId, updatedDto);
    return updatedDto;
  }

  // ── Delete for everyone (owner or group admin) ─────────────────────────────

  async deleteMessage(
    messageId: string,
    userId: string,
    isAdminOrModerator = false,
  ): Promise<{ success: boolean }> {
    const message = await this.messagesRepository.findById(messageId);
    if (!message) {
      throw new NotFoundException('Message not found');
    }

    let hasPermission = message.senderId === userId || isAdminOrModerator;

    const conversation = (message as any).conversation;
    if (!hasPermission && conversation?.group) {
      const group = conversation.group;
      const isOwner = group.createdById === userId;
      const isGroupAdminOrMod = group.members?.some(
        (m: any) =>
          m.userId === userId &&
          (m.role === 'GROUP_ADMIN' || m.role === 'MODERATOR'),
      );
      if (isOwner || isGroupAdminOrMod) {
        hasPermission = true;
      }
    }

    if (!hasPermission) {
      throw new ForbiddenException(
        'You can only delete your own messages, or must be an owner/admin of the group',
      );
    }

    await this.messagesRepository.deleteForEveryone(messageId);
    this.messagingGateway.emitMessageDeleted(message.conversationId, messageId);
    return { success: true };
  }

  // ── React to message ───────────────────────────────────────────────────────

  async addReaction(
    messageId: string,
    userId: string,
    dto: AddReactionDto,
  ): Promise<{ success: boolean }> {
    const message = await this.messagesRepository.findById(messageId);
    if (!message) {
      throw new NotFoundException('Message not found');
    }

    await this.messagesRepository.addReaction(messageId, userId, dto.emoji);
    return { success: true };
  }

  async removeReaction(
    messageId: string,
    userId: string,
    emoji: string,
  ): Promise<{ success: boolean }> {
    await this.messagesRepository.removeReaction(messageId, userId, emoji);
    return { success: true };
  }

  // ── Mark as read ───────────────────────────────────────────────────────────

  async markAsRead(
    messageId: string,
    userId: string,
  ): Promise<{ success: boolean }> {
    const message = await this.messagesRepository.findById(messageId);
    if (!message) {
      throw new NotFoundException('Message not found');
    }

    await this.messagesRepository.markAsRead(messageId, userId);
    const payload = {
      messageId,
      conversationId: message.conversationId,
      userId,
      readAt: new Date(),
    };
    this.messagingGateway.emitReadReceipt(message.conversationId, payload);
    return { success: true };
  }

  // ── Pin/Unpin ──────────────────────────────────────────────────────────────

  async pinMessage(
    conversationId: string,
    messageId: string,
    userId: string,
    isAdmin = false,
  ): Promise<{ success: boolean }> {
    const message = await this.messagesRepository.findById(messageId);
    if (!message) {
      throw new NotFoundException('Message not found');
    }

    let hasPermission = message.senderId === userId || isAdmin;
    const conversation = (message as any).conversation;
    if (conversation) {
      if (conversation.type === 'DIRECT') {
        hasPermission = true;
      } else if (conversation.group) {
        const group = conversation.group;
        const isOwner = group.createdById === userId;
        const isGroupAdminOrMod = group.members?.some(
          (m: any) =>
            m.userId === userId &&
            (m.role === 'GROUP_ADMIN' || m.role === 'MODERATOR'),
        );
        if (isOwner || isGroupAdminOrMod) {
          hasPermission = true;
        }
      }
    }

    if (!hasPermission) {
      throw new ForbiddenException(
        'You do not have permission to pin messages in this group',
      );
    }

    await this.messagesRepository.pinMessage(conversationId, messageId, userId);
    return { success: true };
  }

  async unpinMessage(
    conversationId: string,
    messageId: string,
    userId?: string,
    isAdmin = false,
  ): Promise<{ success: boolean }> {
    if (userId) {
      const message = await this.messagesRepository.findById(messageId);
      if (message) {
        let hasPermission = message.senderId === userId || isAdmin;
        const conversation = (message as any).conversation;
        if (conversation) {
          if (conversation.type === 'DIRECT') {
            hasPermission = true;
          } else if (conversation.group) {
            const group = conversation.group;
            const isOwner = group.createdById === userId;
            const isGroupAdminOrMod = group.members?.some(
              (m: any) =>
                m.userId === userId &&
                (m.role === 'GROUP_ADMIN' || m.role === 'MODERATOR'),
            );
            if (isOwner || isGroupAdminOrMod) {
              hasPermission = true;
            }
          }
        }
        if (!hasPermission) {
          throw new ForbiddenException(
            'You do not have permission to unpin messages in this group',
          );
        }
      }
    }

    await this.messagesRepository.unpinMessage(conversationId, messageId);
    return { success: true };
  }

  async getPinnedMessages(
    conversationId: string,
  ): Promise<MessageResponseDto[]> {
    const pinned =
      await this.messagesRepository.getPinnedMessages(conversationId);
    return pinned.map((p: any) => this.mapToDto(p.message));
  }

  // ── Star/Unstar ────────────────────────────────────────────────────────────

  async starMessage(
    userId: string,
    messageId: string,
  ): Promise<{ success: boolean }> {
    await this.messagesRepository.starMessage(userId, messageId);
    return { success: true };
  }

  async unstarMessage(
    userId: string,
    messageId: string,
  ): Promise<{ success: boolean }> {
    await this.messagesRepository.unstarMessage(userId, messageId);
    return { success: true };
  }

  async getStarredMessages(userId: string): Promise<MessageResponseDto[]> {
    const starred = await this.messagesRepository.getStarredMessages(userId);
    return starred.map((s: any) => this.mapToDto(s.message));
  }

  // ── Mapper ─────────────────────────────────────────────────────────────────

  private mapToDto(message: any): MessageResponseDto {
    // Group reactions by emoji
    const reactionsMap: Record<string, { count: number; userIds: string[] }> =
      {};
    for (const r of message.reactions ?? []) {
      if (!reactionsMap[r.emoji]) {
        reactionsMap[r.emoji] = { count: 0, userIds: [] };
      }
      reactionsMap[r.emoji].count++;
      reactionsMap[r.emoji].userIds.push(r.userId as string);
    }

    return {
      id: message.id,
      conversationId: message.conversationId,
      channelId: message.channelId ?? undefined,
      sender: {
        id: message.sender.id,
        username: message.sender.username,
        displayName: message.sender.profile?.displayName ?? undefined,
        avatarUrl: message.sender.profile?.avatar?.url ?? undefined,
      },
      content: message.content ?? undefined,
      type: message.type,
      replyToId: message.replyToId ?? undefined,
      replyTo: message.replyTo
        ? {
            id: message.replyTo.id,
            content: message.replyTo.content,
            type: message.replyTo.type,
            sender: {
              id: message.replyTo.sender.id,
              username: message.replyTo.sender.username,
              displayName:
                message.replyTo.sender.profile?.displayName ?? undefined,
            },
          }
        : undefined,
      isEdited: message.isEdited,
      isPinned: message.isPinned,
      attachments: (message.attachments ?? [])
        .filter((a: any) => a.file != null)
        .map((a: any) => ({
          fileId: a.file.id,
          url: a.file.url,
          fileType: a.file.fileType,
          mimeType: a.file.mimeType,
          originalName: a.file.originalName ?? '',
        })),
      voiceNote: message.voiceNote
        ? {
            duration: message.voiceNote.duration ?? 0,
            waveform: message.voiceNote.waveform ?? undefined,
            url: message.voiceNote.file?.url ?? '',
          }
        : undefined,
      reactions: Object.entries(reactionsMap).map(([emoji, data]) => ({
        emoji,
        count: data.count,
        userIds: data.userIds,
      })),
      readBy: (message.reads ?? []).map((r: any) => r.userId),
      deliveredTo: (message.deliveries ?? []).map((d: any) => d.userId),
      createdAt: message.createdAt,
      updatedAt: message.updatedAt,
    };
  }

  async getMessageUpdates(
    conversationId: string,
    userId: string,
    since?: string,
    limit = 100,
  ) {
    const conversation =
      await this.conversationsRepository.findById(conversationId);
    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }
    const isMember = conversation.members.some(
      (m: any) => m.userId === userId,
    );
    if (!isMember) {
      throw new ForbiddenException('You are not a member of this conversation');
    }

    const sinceDate = since ? new Date(since) : new Date(0);
    const { messages, deletedIds } =
      await this.messagesRepository.getUpdatesSince(
        conversationId,
        sinceDate,
        limit,
      );

    return {
      messages: messages.map((m: any) => this.mapToDto(m)),
      deletedIds,
      serverTimestamp: new Date().toISOString(),
    };
  }
}
