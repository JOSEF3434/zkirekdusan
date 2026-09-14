// src/modules/admin/services/admin-groups.service.ts
import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';

export interface GroupListFilters {
  search?: string;
  status?: string;
  visibility?: string;
  sortBy?: string;
  sortDir?: 'asc' | 'desc';
  page?: number;
  limit?: number;
}

@Injectable()
export class AdminGroupsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AdminAuditService,
  ) {}

  async listGroups(filters: GroupListFilters) {
    const {
      search,
      status,
      visibility,
      sortBy = 'createdAt',
      sortDir = 'desc',
      page = 1,
      limit = 20,
    } = filters;

    const pageNum = Math.max(1, Number(page) || 1);
    const limitNum = Math.min(100, Math.max(1, Number(limit) || 20));
    const skip = (pageNum - 1) * limitNum;
    const where: any = {};

    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { slug: { contains: search, mode: 'insensitive' } },
      ];
    }
    if (status && status !== 'ALL') where.status = status;
    if (visibility && visibility !== 'ALL') where.visibility = visibility;

    const orderBy: any = {};
    const allowed = ['createdAt', 'name', 'status'];
    orderBy[allowed.includes(sortBy) ? sortBy : 'createdAt'] = sortDir;

    const [items, total] = await Promise.all([
      this.prisma.group.findMany({
        where,
        skip,
        take: limitNum,
        orderBy,
        include: {
          createdBy: {
            select: {
              id: true, username: true,
              profile: { select: { displayName: true, avatar: { select: { url: true } } } },
            },
          },
          _count: { select: { members: true, posts: true, channels: true } },
        },
      }),
      this.prisma.group.count({ where }),
    ]);

    return {
      items,
      total,
      page: pageNum,
      limit: limitNum,
      totalPages: Math.ceil(total / limitNum),
      hasNext: pageNum * limitNum < total,
    };
  }

  async getGroupDetail(id: string) {
    const group = await this.prisma.group.findUnique({
      where: { id },
      include: {
        createdBy: { select: { id: true, username: true, profile: { select: { displayName: true } } } },
        approvedBy: { select: { id: true, username: true } },
        members: {
          where: { removedAt: null },
          take: 50,
          orderBy: { joinedAt: 'desc' },
          include: {
            user: {
              select: {
                id: true, username: true,
                profile: { select: { displayName: true, avatar: { select: { url: true } } } },
              },
            },
          },
        },
        channels: { take: 20 },
        _count: { select: { members: true, posts: true, channels: true, liveStreams: true } },
      },
    });
    if (!group) throw new NotFoundException(`Group ${id} not found`);
    return group;
  }

  async approveGroup(actorId: string, id: string, reason?: string) {
    const group = await this.findGroupOrThrow(id);

    const updated = await this.prisma.group.update({
      where: { id },
      data: { status: 'ACTIVE', approvedById: actorId, approvedAt: new Date() },
    });

    await this.audit.emit({
      actorId,
      action: 'GROUP_APPROVED',
      targetType: 'GROUP',
      targetId: id,
      before: { status: group.status },
      after: { status: 'ACTIVE' },
      reason,
    });

    return updated;
  }

  async restoreGroup(actorId: string, id: string, reason?: string) {
    const group = await this.findGroupOrThrow(id);

    const updated = await this.prisma.group.update({
      where: { id },
      data: { status: 'ACTIVE', deletedAt: null },
    });

    await this.audit.emit({
      actorId,
      action: 'GROUP_RESTORED',
      targetType: 'GROUP',
      targetId: id,
      before: { status: group.status },
      after: { status: 'ACTIVE' },
      reason,
    });

    return updated;
  }

  async rejectGroup(actorId: string, id: string, reason?: string) {
    if (!reason) throw new BadRequestException('A reason is required to reject a group');
    const group = await this.findGroupOrThrow(id);

    const updated = await this.prisma.group.update({
      where: { id },
      data: { status: 'REJECTED' },
    });

    await this.audit.emit({
      actorId,
      action: 'GROUP_REJECTED',
      targetType: 'GROUP',
      targetId: id,
      before: { status: group.status },
      after: { status: 'REJECTED' },
      reason,
    });

    return updated;
  }

  async suspendGroup(actorId: string, id: string, reason?: string) {
    if (!reason) throw new BadRequestException('A reason is required to suspend a group');
    const group = await this.findGroupOrThrow(id);

    const updated = await this.prisma.group.update({
      where: { id },
      data: { status: 'SUSPENDED' },
    });

    await this.audit.emit({
      actorId,
      action: 'GROUP_SUSPENDED',
      targetType: 'GROUP',
      targetId: id,
      before: { status: group.status },
      after: { status: 'SUSPENDED' },
      reason,
    });

    return updated;
  }

  async archiveGroup(actorId: string, id: string, reason?: string) {
    if (!reason) throw new BadRequestException('A reason is required to archive a group');
    const group = await this.findGroupOrThrow(id);

    const updated = await this.prisma.group.update({
      where: { id },
      data: { status: 'ARCHIVED' },
    });

    await this.audit.emit({
      actorId,
      action: 'GROUP_ARCHIVED',
      targetType: 'GROUP',
      targetId: id,
      before: { status: group.status },
      after: { status: 'ARCHIVED' },
      reason,
    });

    return updated;
  }

  async deleteGroup(actorId: string, id: string, reason?: string) {
    if (!reason) throw new BadRequestException('A reason is required to delete a group');
    const group = await this.findGroupOrThrow(id);

    await this.prisma.group.update({
      where: { id },
      data: { deletedAt: new Date(), status: 'ARCHIVED' },
    });

    await this.audit.emit({
      actorId,
      action: 'GROUP_DELETED',
      targetType: 'GROUP',
      targetId: id,
      before: { name: group.name, status: group.status },
      after: { deletedAt: new Date().toISOString() },
      reason,
    });

    return { success: true };
  }

  async removeMember(actorId: string, groupId: string, userId: string, reason?: string) {
    const member = await this.prisma.groupMember.findFirst({
      where: { groupId, userId, removedAt: null },
    });
    if (!member) throw new NotFoundException('Member not found in group');

    await this.prisma.groupMember.update({
      where: { id: member.id },
      data: { removedAt: new Date() },
    });

    await this.audit.emit({
      actorId,
      action: 'GROUP_MEMBER_REMOVED',
      targetType: 'GROUP',
      targetId: groupId,
      metadata: { removedUserId: userId },
      reason,
    });

    return { success: true };
  }

  private async findGroupOrThrow(id: string) {
    const group = await this.prisma.group.findUnique({ where: { id } });
    if (!group) throw new NotFoundException(`Group ${id} not found`);
    return group;
  }
}
