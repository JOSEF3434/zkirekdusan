// src/modules/admin/services/admin-audit.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service.js';

export interface AuditLogInput {
  actorId: string;
  action: string;
  targetType?: string;
  targetId?: string;
  before?: Record<string, unknown>;
  after?: Record<string, unknown>;
  reason?: string;
  metadata?: Record<string, unknown>;
  resource?: string;
}

export interface AuditLogFilters {
  actorId?: string;
  action?: string;
  targetType?: string;
  targetId?: string;
  dateFrom?: Date;
  dateTo?: Date;
  search?: string;
  page?: number;
  limit?: number;
}

@Injectable()
export class AdminAuditService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Central audit log emission — called by ALL admin services on sensitive actions.
   */
  async emit(input: AuditLogInput): Promise<void> {
    await this.prisma.auditLog.create({
      data: {
        userId: input.actorId,
        action: input.action,
        resource: input.resource ?? input.targetType ?? 'SYSTEM',
        targetType: input.targetType,
        targetId: input.targetId,
        before: input.before as any,
        after: input.after as any,
        reason: input.reason,
        metadata: input.metadata as any,
      },
    });
  }

  /**
   * Alias for emit
   */
  async log(input: AuditLogInput): Promise<void> {
    return this.emit(input);
  }

  /**
   * Query audit logs with full pagination and filtering.
   */
  async listAuditLogs(
    queryOrFilters: AuditLogFilters,
    pagination?: { page: number; limit: number },
  ) {
    const page = Math.max(
      1,
      Number(pagination?.page ?? queryOrFilters.page) || 1,
    );
    const limit = Math.min(
      100,
      Math.max(1, Number(pagination?.limit ?? queryOrFilters.limit) || 30),
    );
    const skip = (page - 1) * limit;

    const where: any = {};

    if (queryOrFilters.actorId) where.userId = queryOrFilters.actorId;
    if (queryOrFilters.action)
      where.action = { contains: queryOrFilters.action, mode: 'insensitive' };
    if (queryOrFilters.targetType) where.targetType = queryOrFilters.targetType;
    if (queryOrFilters.targetId) where.targetId = queryOrFilters.targetId;
    if (queryOrFilters.dateFrom || queryOrFilters.dateTo) {
      where.createdAt = {};
      if (queryOrFilters.dateFrom)
        where.createdAt.gte = queryOrFilters.dateFrom;
      if (queryOrFilters.dateTo) where.createdAt.lte = queryOrFilters.dateTo;
    }

    const [items, total] = await Promise.all([
      this.prisma.auditLog.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            select: {
              id: true,
              username: true,
              profile: {
                select: {
                  displayName: true,
                  avatar: { select: { url: true } },
                },
              },
            },
          },
        },
      }),
      this.prisma.auditLog.count({ where }),
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
