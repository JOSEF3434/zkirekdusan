// src/modules/notifications/notifications.service.ts
import { Injectable, forwardRef, Inject } from '@nestjs/common';
import { NotificationType } from '@prisma/client';
import { NotificationsRepository } from './notifications.repository.js';
import { NotificationResponseDto } from './dto/notification-response.dto.js';
import { NotificationsGateway } from './notifications.gateway.js';
import { FirebaseService } from './firebase.service.js';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class NotificationsService {
  constructor(
    private readonly notificationsRepository: NotificationsRepository,
    @Inject(forwardRef(() => NotificationsGateway))
    private readonly notificationsGateway: NotificationsGateway,
    private readonly firebaseService: FirebaseService,
    private readonly prisma: PrismaService,
  ) {}

  // ── Create (used internally by other services) ─────────────────────────────
  async create(payload: {
    userId: string;
    type: NotificationType;
    title: string;
    body: string;
    data?: Record<string, any>;
  }): Promise<NotificationResponseDto> {
    const notif = await this.notificationsRepository.create(payload);
    const dto = this.mapToDto(notif);

    // 1. Push real-time Socket.IO notification
    this.notificationsGateway.emitNotification(payload.userId, dto);

    // 2. Push FCM mobile notification (fire-and-forget)
    this.sendPushToUser(payload.userId, payload.title, payload.body).catch(() => null);

    return dto;
  }

  private async sendPushToUser(userId: string, title: string, body: string): Promise<void> {
    const tokens = await this.prisma.deviceToken.findMany({
      where: { userId },
      select: { token: true },
    });
    if (tokens.length === 0) return;
    await this.firebaseService.sendMulticast({
      tokens: tokens.map((t) => t.token),
      title,
      body,
    });
  }

  // ── Factory helpers ────────────────────────────────────────────────────────

  async notifyMessage(
    recipientId: string,
    senderName: string,
    preview: string,
    conversationId: string,
  ) {
    return this.create({
      userId: recipientId,
      type: NotificationType.MESSAGE,
      title: `New message from ${senderName}`,
      body: preview,
      data: { conversationId },
    });
  }

  async notifyGroupInvite(
    recipientId: string,
    groupName: string,
    groupId: string,
  ) {
    return this.create({
      userId: recipientId,
      type: NotificationType.GROUP_INVITE,
      title: `You have been invited to ${groupName}`,
      body: 'Tap to view the invitation',
      data: { groupId },
    });
  }

  async notifyGroupJoinRequest(
    adminId: string,
    requesterName: string,
    groupId: string,
  ) {
    return this.create({
      userId: adminId,
      type: NotificationType.GROUP_JOIN_REQUEST,
      title: `${requesterName} wants to join your group`,
      body: 'Review the join request',
      data: { groupId },
    });
  }

  async notifyGroupApprove(userId: string, groupName: string, groupId: string) {
    return this.create({
      userId,
      type: NotificationType.GROUP_APPROVE,
      title: `Your request to join ${groupName} was approved`,
      body: 'You are now a member of the group',
      data: { groupId },
    });
  }

  async notifyMention(
    recipientId: string,
    senderName: string,
    context: string,
    conversationId: string,
  ) {
    return this.create({
      userId: recipientId,
      type: NotificationType.MENTION,
      title: `${senderName} mentioned you`,
      body: context,
      data: { conversationId },
    });
  }

  async notifyReaction(
    recipientId: string,
    senderName: string,
    emoji: string,
    messageId: string,
  ) {
    return this.create({
      userId: recipientId,
      type: NotificationType.REACTION,
      title: `${senderName} reacted ${emoji} to your message`,
      body: '',
      data: { messageId },
    });
  }

  // ── User-facing queries ────────────────────────────────────────────────────

  async getMyNotifications(userId: string): Promise<NotificationResponseDto[]> {
    const notifications = await this.notificationsRepository.findByUser(userId);
    return notifications.map((n) => this.mapToDto(n));
  }

  async getUnreadNotifications(
    userId: string,
  ): Promise<NotificationResponseDto[]> {
    const notifications = await this.notificationsRepository.findByUser(
      userId,
      true,
    );
    return notifications.map((n) => this.mapToDto(n));
  }

  async getUnreadCount(userId: string): Promise<{ count: number }> {
    const count = await this.notificationsRepository.unreadCount(userId);
    return { count };
  }

  async markAsRead(id: string, userId: string): Promise<{ success: boolean }> {
    await this.notificationsRepository.markAsRead(id, userId);
    return { success: true };
  }

  async markAllAsRead(userId: string): Promise<{ success: boolean }> {
    await this.notificationsRepository.markAllAsRead(userId);
    return { success: true };
  }

  async delete(id: string, userId: string): Promise<{ success: boolean }> {
    await this.notificationsRepository.delete(id, userId);
    return { success: true };
  }

  // ── Mapper ─────────────────────────────────────────────────────────────────
  private mapToDto(n: any): NotificationResponseDto {
    return {
      id: n.id,
      type: n.type,
      title: n.title,
      body: n.body,
      data: n.data ?? undefined,
      isRead: n.isRead,
      createdAt: n.createdAt,
    };
  }
}
