// src/modules/admin/services/admin-users.service.ts
import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service.js';
import { AppRole } from '../../../common/constants/roles.js';
import { AdminAuditService } from './admin-audit.service.js';

export interface UserListFilters {
  search?: string;
  status?: string;
  role?: string;
  sortBy?: string;
  sortDir?: 'asc' | 'desc';
  page?: number;
  limit?: number;
}

@Injectable()
export class AdminUsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AdminAuditService,
  ) {}

  async listUsers(filters: UserListFilters) {
    const {
      search,
      status,
      role,
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
        { username: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
        { profile: { displayName: { contains: search, mode: 'insensitive' } } },
      ];
    }
    if (status && status !== 'ALL') where.status = status;
    if (role && role !== 'ALL') where.role = { name: role };

    const orderBy: any = {};
    const allowedSortFields = [
      'createdAt',
      'username',
      'email',
      'status',
      'lastLoginAt',
    ];
    const safeSort = allowedSortFields.includes(sortBy) ? sortBy : 'createdAt';
    orderBy[safeSort] = sortDir;

    const [items, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limitNum,
        orderBy,
        include: {
          role: { select: { name: true } },
          profile: {
            select: {
              displayName: true,
              avatar: { select: { url: true } },
            },
          },
          _count: {
            select: {
              groupMemberships: true,
              reports: true,
              sessions: true,
            },
          },
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      items: items.map((u) => ({
        id: u.id,
        username: u.username,
        email: u.email,
        phoneNumber: u.phoneNumber,
        status: u.status,
        role: (u.role as any)?.name ?? 'USER',
        displayName: (u.profile as any)?.displayName,
        avatarUrl: (u.profile as any)?.avatar?.url,
        lastLoginAt: u.lastLoginAt,
        createdAt: u.createdAt,
        groupCount: (u._count as any).groupMemberships,
        reportCount: (u._count as any).reports,
        sessionCount: (u._count as any).sessions,
      })),
      total,
      page: pageNum,
      limit: limitNum,
      totalPages: Math.ceil(total / limitNum),
      hasNext: pageNum * limitNum < total,
    };
  }

  async getUserDetail(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        role: {
          include: {
            permissions: {
              include: { permission: { select: { name: true } } },
            },
          },
        },
        profile: {
          include: {
            avatar: { select: { url: true } },
            cover: { select: { url: true } },
          },
        },
        groupMemberships: {
          where: { removedAt: null },
          include: {
            group: {
              select: { id: true, name: true, slug: true, status: true },
            },
          },
          take: 20,
        },
        sessions: {
          where: { status: 'ACTIVE' },
          orderBy: { createdAt: 'desc' },
          take: 5,
          select: {
            id: true,
            device: true,
            ipAddress: true,
            lastSeenAt: true,
            createdAt: true,
          },
        },
        _count: {
          select: {
            reports: true,
            uploadedFiles: true,
            uploadedVideos: true,
            createdGroups: true,
          },
        },
      },
    });

    if (!user) throw new NotFoundException(`User ${id} not found`);

    const permissions =
      (user.role as any).name === AppRole.SUPER_ADMIN
        ? ['*']
        : (user.role as any).permissions.map((rp: any) => rp.permission.name);

    return { ...user, effectivePermissions: permissions };
  }

  async getUserEffectivePermissions(id: string): Promise<string[]> {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        role: {
          include: { permissions: { include: { permission: true } } },
        },
      },
    });
    if (!user) throw new NotFoundException(`User ${id} not found`);
    if ((user.role as any).name === AppRole.SUPER_ADMIN) return ['*'];
    return (user.role as any).permissions.map((rp: any) => rp.permission.name);
  }

  async updateUserStatus(
    actorId: string,
    userId: string,
    status: 'ACTIVE' | 'INACTIVE' | 'SUSPENDED' | 'BANNED',
    reason?: string,
  ) {
    await this.assertNotLastSuperAdmin(userId, 'status update');

    const before = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { status: true },
    });
    if (!before) throw new NotFoundException(`User ${userId} not found`);

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { status },
    });

    const actionMap: Record<string, string> = {
      BANNED: 'USER_BANNED',
      SUSPENDED: 'USER_SUSPENDED',
      INACTIVE: 'USER_DEACTIVATED',
      ACTIVE: 'USER_ACTIVATED',
    };

    await this.audit.emit({
      actorId,
      action: actionMap[status] ?? 'USER_STATUS_CHANGED',
      targetType: 'USER',
      targetId: userId,
      before: { status: before.status },
      after: { status },
      reason,
    });

    return updated;
  }

  async banUser(actorId: string, userId: string, reason?: string) {
    return this.updateUserStatus(actorId, userId, 'BANNED', reason);
  }

  async suspendUser(actorId: string, userId: string, reason?: string) {
    return this.updateUserStatus(actorId, userId, 'SUSPENDED', reason);
  }

  async deactivateUser(actorId: string, userId: string, reason?: string) {
    return this.updateUserStatus(actorId, userId, 'INACTIVE', reason);
  }

  async activateUser(actorId: string, userId: string) {
    return this.updateUserStatus(actorId, userId, 'ACTIVE', undefined);
  }

  async assignRole(
    actorId: string,
    userId: string,
    targetRoleName: string,
    reason?: string,
  ) {
    // Privilege escalation protection: only SUPER_ADMIN can assign SUPER_ADMIN
    const actor = await this.prisma.user.findUnique({
      where: { id: actorId },
      include: { role: { select: { name: true } } },
    });
    if (!actor) throw new NotFoundException('Actor not found');

    if (
      targetRoleName === AppRole.SUPER_ADMIN &&
      (actor.role as any).name !== AppRole.SUPER_ADMIN
    ) {
      throw new ForbiddenException(
        'Only SUPER_ADMIN can assign the SUPER_ADMIN role',
      );
    }

    // Prevent demoting the last super_admin
    if (targetRoleName !== AppRole.SUPER_ADMIN) {
      await this.assertNotLastSuperAdmin(userId, 'role assignment');
    }

    const targetRole = await this.prisma.role.findUnique({
      where: { name: targetRoleName },
    });
    if (!targetRole)
      throw new NotFoundException(`Role ${targetRoleName} not found`);

    const before = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { role: { select: { name: true } } },
    });

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { roleId: targetRole.id },
    });

    await this.audit.emit({
      actorId,
      action: 'ROLE_ASSIGNED',
      targetType: 'USER',
      targetId: userId,
      before: { role: (before?.role as any)?.name },
      after: { role: targetRoleName },
      reason,
    });

    return updated;
  }

  async deleteUser(actorId: string, userId: string, reason?: string) {
    if (!reason)
      throw new BadRequestException('A reason is required to delete a user');
    await this.assertNotLastSuperAdmin(userId, 'delete');

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException(`User ${userId} not found`);

    // Soft delete via status + anonymize sensitive data
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        status: 'BANNED',
        email: `deleted_${userId}@deleted.invalid`,
        username: `deleted_${userId}`,
      },
    });

    await this.audit.emit({
      actorId,
      action: 'USER_DELETED',
      targetType: 'USER',
      targetId: userId,
      before: { username: user.username, email: user.email },
      after: { status: 'BANNED', anonymized: true },
      reason,
    });

    return { success: true };
  }

  /**
   * Guard: prevents removing / demoting the last active SUPER_ADMIN.
   */
  private async assertNotLastSuperAdmin(userId: string, operation: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { role: { select: { name: true } } },
    });
    if (!user) return; // Will 404 elsewhere

    if ((user.role as any).name !== AppRole.SUPER_ADMIN) return;

    const superAdminCount = await this.prisma.user.count({
      where: {
        role: { name: AppRole.SUPER_ADMIN },
        status: 'ACTIVE',
      },
    });

    if (superAdminCount <= 1) {
      throw new ForbiddenException(
        `Cannot perform ${operation} on the last active SUPER_ADMIN account`,
      );
    }
  }
}
