// src/modules/admin/services/admin-notifications.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';

@Injectable()
export class AdminNotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AdminAuditService,
  ) {}

  async broadcastSystemNotification(dto: {
    title: string;
    body: string;
    targetRole?: string;
    actorId: string;
    data?: any;
  }) {
    const userWhere: any = { status: 'ACTIVE' };
    if (dto.targetRole && dto.targetRole !== 'ALL') {
      userWhere.role = { name: dto.targetRole };
    }

    const users = await this.prisma.user.findMany({
      where: userWhere,
      select: { id: true },
    });

    if (users.length > 0) {
      const records = users.map((u) => ({
        userId: u.id,
        type: 'SYSTEM_ANNOUNCEMENT' as any,
        title: dto.title,
        body: dto.body,
        data: dto.data ?? {},
      }));

      // Batch insert in chunks of 500
      const chunkSize = 500;
      for (let i = 0; i < records.length; i += chunkSize) {
        await this.prisma.notification.createMany({
          data: records.slice(i, i + chunkSize),
        });
      }
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

    const where: any = { type: 'SYSTEM_ANNOUNCEMENT' };

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
