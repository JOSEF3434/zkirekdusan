// src/modules/admin/services/admin-notifications.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
import { NotificationsService } from '../../notifications/notifications.service.js';
import { NotificationType } from '@prisma/client';

@Injectable()
export class AdminNotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AdminAuditService,
    private readonly notificationsService: NotificationsService,
  ) { }

  async broadcastSystemNotification(dto: {
    title: string;
    body: string;
    targetRole?: string;
    actorId: string;
    data?: any;
  }) {
    const userWhere: any = { status: 'ACTIVE' };
    if (dto.targetRole && dto.targetRole !== 'ALL') {
      userWhere.role =
        dto.targetRole === 'ADMIN'
          ? { name: { in: ['ADMIN', 'SUPER_ADMIN'] } }
          : { name: dto.targetRole };
    }

    const users = await this.prisma.user.findMany({
      where: userWhere,
      select: { id: true },
    });

    // Use the notification service so every recipient receives both the
    // Socket.IO event and an FCM push in addition to the persisted record.
    const batchSize = 50;
    for (let i = 0; i < users.length; i += batchSize) {
      await Promise.all(
        users.slice(i, i + batchSize).map((user) =>
          this.notificationsService.create({
            userId: user.id,
            type: NotificationType.SYSTEM,
            title: dto.title,
            body: dto.body,
            data: dto.data,
          }),
        ),
      );
    }

    await this.auditService.log({
      actorId: dto.actorId,
      action: 'SYSTEM_NOTIFICATION_BROADCAST',
      targetType: 'NOTIFICATION',
      targetId: 'BROADCAST',
      after: {
        title: dto.title,
        recipientsCount: users.length,
        targetRole: dto.targetRole ?? 'ALL',
      },
    });

    return {
      success: true,
      recipientsCount: users.length,
      message: `Broadcast delivered to ${users.length} users`,
    };
  }

  async listAdminNotifications(query: { page?: number; limit?: number }) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = { type: NotificationType.SYSTEM };

    const [items, total] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        distinct: ['title'],
      }),
      this.prisma.notification.count({ where }),
    ]);

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      hasNext: page * limit < total,
    };
  }
}
