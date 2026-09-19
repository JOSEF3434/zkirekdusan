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
    this.sendPushToUser(
      payload.userId,
      payload.title,
      payload.body,
      dto.id,
      payload.type,
      payload.data,
    ).catch(() => null);

    return dto;
  }

  private async sendPushToUser(
    userId: string,
    title: string,
    body: string,
    notificationId?: string,
    type?: string,
    data?: Record<string, any>,
  ): Promise<void> {
    const tokens = await this.prisma.deviceToken.findMany({
      where: { userId },
      select: { token: true },
    });
    if (tokens.length === 0) return;

    const stringData: Record<string, string> = {
      notificationId: notificationId ?? '',
      type: type ?? 'SYSTEM',
    };
    if (data) {
      for (const [k, v] of Object.entries(data)) {
        if (v !== undefined && v !== null) {
          stringData[k] = typeof v === 'string' ? v : JSON.stringify(v);
        }
      }
    }

    await this.firebaseService.sendMulticast({
      tokens: tokens.map((t) => t.token),
      title,
      body,
      data: stringData,
    });
  }

  // ── Broadcast to all users ────────────────────────────────────────────────
  async notifyAllUsers(payload: {
    title: string;
    body: string;
    type?: NotificationType;
    data?: Record<string, any>;
  }): Promise<void> {
    const type = payload.type ?? NotificationType.SYSTEM;

    // 1. Fetch active users to record notifications
    const users = await this.prisma.user.findMany({
      select: { id: true },
      take: 2000,
    });

    // 2. Real-time Socket.IO event broadcast
    try {
      this.notificationsGateway.server?.emit('notification_broadcast', {
        title: payload.title,
        body: payload.body,
        type,
        data: payload.data,
        createdAt: new Date().toISOString(),
      });
    } catch {
      // socket broadcast error fallback
    }

    // 3. Persist DB notifications in batches
    if (users.length > 0) {
      await this.prisma.notification
        .createMany({
          data: users.map((u) => ({
            userId: u.id,
            type,
            title: payload.title,
            body: payload.body,
            data: payload.data ? payload.data : undefined,
          })),
          skipDuplicates: true,
        })
        .catch(() => null);
    }

    // 4. Send FCM Multicast to all registered device tokens in batches of 500
    const deviceTokens = await this.prisma.deviceToken.findMany({
      select: { token: true },
    });

    if (deviceTokens.length > 0) {
      const stringData: Record<string, string> = {
        type: type.toString(),
      };
      if (payload.data) {
        for (const [k, v] of Object.entries(payload.data)) {
          if (v !== undefined && v !== null) {
            stringData[k] = typeof v === 'string' ? v : JSON.stringify(v);
          }
        }
      }

      const allTokens = deviceTokens.map((t) => t.token);
      const batchSize = 500;
      for (let i = 0; i < allTokens.length; i += batchSize) {
        const batch = allTokens.slice(i, i + batchSize);
        await this.firebaseService
          .sendMulticast({
            tokens: batch,
            title: payload.title,
            body: payload.body,
            data: stringData,
          })
          .catch(() => null);
      }
    }
  }

  async notifyCalendarNotePublished(note: {
    id: string;
    title?: string | null;
    content?: string | null;
    ethiopianDay: number;
    ethiopianMonth: number;
    ethiopianYear: number;
  }): Promise<void> {
    const title =
      note.title && note.title.trim().length > 0
        ? `አዲስ የዝክረ ቅዱሳን ማስታወሻ: ${note.title}`
        : 'አዲስ የዝክረ ቅዱሳን ማስታወሻ ተለጥፏል';
    const body =
      note.content && note.content.trim().length > 0
        ? (note.content.length > 120 ? `${note.content.substring(0, 117)}...` : note.content)
        : `ለዕለት ${note.ethiopianDay}/${note.ethiopianMonth}/${note.ethiopianYear} የተለጠፈ ማስታወሻ ለመመልከት ይጫኑ`;

    return this.notifyAllUsers({
      title,
      body,
      type: NotificationType.SYSTEM,
      data: {
        noteId: note.id,
        calendarNoteId: note.id,
        type: 'CALENDAR_NOTE',
      },
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
