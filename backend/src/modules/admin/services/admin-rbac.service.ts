// src/modules/admin/services/admin-rbac.service.ts
import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
import { AppRole } from '../../../common/constants/roles.js';

@Injectable()
export class AdminRbacService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AdminAuditService,
  ) {}

  /**
   * Retrieves all platform roles along with their assigned permissions from the database.
   */
  async getRbacRoles() {
    const roles = await this.prisma.role.findMany({
      include: {
        permissions: {
          include: {
            permission: true,
          },
        },
      },
      orderBy: { name: 'asc' },
    });

    const formatted = roles.map((role) => {
      const permsMap: Record<string, boolean> = {};
      for (const rp of role.permissions) {
        if (rp.permission?.name) {
          permsMap[rp.permission.name] = true;
        }
      }
      return {
        id: role.id,
        name: role.name,
        description: role.description,
        permissions: permsMap,
      };
    });

    return { roles: formatted };
  }

  /**
   * Updates permission grants for a specific role and persists them into the database.
   * Inserts new permissions into `permissions` and role links into `role_permissions`.
   */
  async updateRolePermissions(
    roleName: string,
    permissions: Record<string, boolean>,
    actorId?: string,
  ) {
    if (!roleName) {
      throw new BadRequestException('Role name is required');
    }

    const normalizedRole = roleName.toUpperCase();

    if (normalizedRole === AppRole.SUPER_ADMIN) {
      throw new ForbiddenException(
        'SUPER_ADMIN permissions are immutable and cannot be restricted',
      );
    }

    const role = await this.prisma.role.findUnique({
      where: { name: normalizedRole },
      include: {
        permissions: {
          include: {
            permission: true,
          },
        },
      },
    });

    if (!role) {
      throw new NotFoundException(
        `Role '${normalizedRole}' not found in database`,
      );
    }

    const beforePerms: Record<string, boolean> = {};
    for (const rp of role.permissions) {
      if (rp.permission?.name) {
        beforePerms[rp.permission.name] = true;
      }
    }

    // Execute atomic persistence in a Prisma transaction
    await this.prisma.$transaction(async (tx) => {
      for (const [permKey, isGranted] of Object.entries(permissions)) {
        if (!permKey || typeof permKey !== 'string') continue;

        // Ensure permission record exists in database
        const perm = await tx.permission.upsert({
          where: { name: permKey },
          update: {},
          create: {
            name: permKey,
            description: permKey,
          },
        });

        if (isGranted) {
          // Grant permission: link role to permission in database
          await tx.rolePermission.upsert({
            where: {
              roleId_permissionId: {
                roleId: role.id,
                permissionId: perm.id,
              },
            },
            update: {},
            create: {
              roleId: role.id,
              permissionId: perm.id,
            },
          });
        } else {
          // Revoke permission: remove link from database
          await tx.rolePermission.deleteMany({
            where: {
              roleId: role.id,
              permissionId: perm.id,
            },
          });
        }
      }
    });

    // Record audit log for security compliance
    if (actorId) {
      try {
        await this.auditService.emit({
          actorId,
          action: 'RBAC_UPDATE_ROLE_PERMISSIONS',
          resource: 'RBAC',
          targetType: 'ROLE',
          targetId: role.id,
          before: beforePerms,
          after: permissions,
          reason: `Updated RBAC permissions for role ${normalizedRole}`,
        });
      } catch {
        // Non-blocking audit log emission
      }
    }

    return {
      success: true,
      role: normalizedRole,
      updatedCount: Object.keys(permissions).length,
    };
  }
}
