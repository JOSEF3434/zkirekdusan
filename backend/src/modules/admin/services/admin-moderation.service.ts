// src/modules/admin/services/admin-moderation.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';

@Injectable()
export class AdminModerationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AdminAuditService,
  ) {}

  async getReports(query: {
    page?: number;
    limit?: number;
    status?: string;
    targetType?: string;
    reason?: string;
  }) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {};
    if (query.status && query.status !== 'ALL') {
      where.status = query.status;
    }
    if (query.targetType && query.targetType !== 'ALL') {
      where.targetType = query.targetType;
    }
    if (query.reason && query.reason !== 'ALL') {
      where.reason = query.reason;
    }

    const [items, total] = await Promise.all([
      this.prisma.report.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          reporter: {
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
      this.prisma.report.count({ where }),
    ]);

    // Enrich with target entity details (targetUser, targetPost, etc.)
    const enriched = await Promise.all(
      items.map(async (report: any) => {
        let targetDetail: any = null;
        const targetUserId =
          report.targetUserId ||
          (report.targetType === 'USER' ? report.targetId : null);

        if (targetUserId) {
          targetDetail = await this.prisma.user.findUnique({
            where: { id: targetUserId },
            select: {
              id: true,
              username: true,
              status: true,
              role: { select: { name: true } },
              profile: {
                select: {
                  displayName: true,
                  avatar: { select: { url: true } },
                },
              },
            },
          });
        }
        return {
          ...report,
          targetUser: targetDetail,
        };
      }),
    );

    return {
      items: enriched,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      hasNext: page * limit < total,
    };
  }

  async getReportDetail(id: string) {
    const report = await this.prisma.report.findUnique({
      where: { id },
      include: {
        reporter: {
          select: {
            id: true,
            username: true,
            profile: {
              select: { displayName: true, avatar: { select: { url: true } } },
            },
          },
        },
      },
    });

    if (!report) {
      throw new NotFoundException(`Report ${id} not found`);
    }

    let targetEntity: any = null;
    if (report.targetType === 'USER' || report.targetUserId) {
      targetEntity = await this.prisma.user.findUnique({
        where: { id: report.targetUserId || report.targetId },
        select: {
          id: true,
          username: true,
          status: true,
          profile: { select: { displayName: true } },
        },
      });
    } else if (report.targetType === 'POST') {
      targetEntity = await this.prisma.post.findUnique({
        where: { id: report.targetId },
        include: { author: { select: { id: true, username: true } } },
      });
    }

    return {
      ...report,
      targetEntity,
    };
  }

  async performAction(
    id: string,
    actorId: string,
    dto: {
      action:
        | 'BAN_USER'
        | 'DEACTIVATE_USER'
        | 'SUSPEND_USER'
        | 'DISMISS'
        | 'RESOLVE'
        | 'DELETE_CONTENT';
      note?: string;
    },
  ) {
    const report = await this.prisma.report.findUnique({ where: { id } });
    if (!report) {
      throw new NotFoundException(`Report ${id} not found`);
    }

    const targetUserId =
      report.targetUserId ||
      (report.targetType === 'USER' ? report.targetId : null);

    if (targetUserId) {
      if (dto.action === 'BAN_USER') {
        await this.prisma.user.update({
          where: { id: targetUserId },
          data: { status: 'BANNED' },
        });
      } else if (dto.action === 'DEACTIVATE_USER') {
        await this.prisma.user.update({
          where: { id: targetUserId },
          data: { status: 'INACTIVE' },
        });
      } else if (dto.action === 'SUSPEND_USER') {
        await this.prisma.user.update({
          where: { id: targetUserId },
          data: { status: 'SUSPENDED' },
        });
      }
    }

    if (dto.action === 'DELETE_CONTENT') {
      if (report.targetType === 'POST') {
        await this.prisma.post
          .delete({ where: { id: report.targetId } })
          .catch(() => null);
      }
    }

    const newStatus = dto.action === 'DISMISS' ? 'DISMISSED' : 'RESOLVED';
    const updated = await this.prisma.report.update({
      where: { id },
      data: {
        status: newStatus as any,
        actionTaken: dto.action,
        resolvedById: actorId,
        resolvedAt: new Date(),
      },
    });

    await this.auditService.log({
      actorId,
      action: `REPORT_ACTION_${dto.action}`,
      targetType: 'REPORT',
      targetId: id,
      before: { status: report.status },
      after: { status: newStatus, actionTaken: dto.action },
      reason: dto.note,
    });

    return updated;
  }

  async resolveReport(
    id: string,
    actorId: string,
    dto: { status: 'RESOLVED' | 'DISMISSED'; actionTaken?: string },
  ) {
    const report = await this.prisma.report.findUnique({ where: { id } });
    if (!report) {
      throw new NotFoundException(`Report ${id} not found`);
    }

    const updated = await this.prisma.report.update({
      where: { id },
      data: {
        status: dto.status as any,
        actionTaken: dto.actionTaken ?? dto.status,
        resolvedById: actorId,
        resolvedAt: new Date(),
      },
    });

    await this.auditService.log({
      actorId,
      action: `REPORT_${dto.status}`,
      targetType: 'REPORT',
      targetId: id,
      before: { status: report.status },
      after: { status: dto.status },
    });

    return updated;
  }

  async listModerationCases(query: {
    page?: number;
    limit?: number;
    status?: string;
    entityType?: string;
  }) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {};
    if (query.status && query.status !== 'ALL') {
      where.status = query.status;
    }
    if (query.entityType && query.entityType !== 'ALL') {
      where.entityType = query.entityType;
    }

    const [items, total] = await Promise.all([
      this.prisma.moderationCase.findMany({
        where,
        skip,
        take: limit,
        orderBy: [{ priority: 'desc' }, { createdAt: 'desc' }],
        include: {
          actions: {
            take: 5,
            orderBy: { createdAt: 'desc' },
          },
        },
      }),
      this.prisma.moderationCase.count({ where }),
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
