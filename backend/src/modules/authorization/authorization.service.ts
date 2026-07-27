// src/modules/authorization/authorization.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { AppRole } from '../../common/constants/roles.js';
import { GroupRole, hasGroupRoleAtLeast } from '../../common/constants/group-roles.js';

@Injectable()
export class AuthorizationService {
  constructor(private readonly prisma: PrismaService) {}

  private async getUserWithRole(userId: string) {
    if (!userId) throw new NotFoundException('User ID is required');

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        role: {
          include: {
            permissions: {
              include: {
                permission: true,
              },
            },
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async getUserRole(userId: string): Promise<string> {
    const user = await this.getUserWithRole(userId);
    return user.role.name;
  }

  async getUserPermissions(userId: string): Promise<string[]> {
    const user = await this.getUserWithRole(userId);

    // SUPER_ADMIN gets wildcard access
    if (user.role.name === AppRole.SUPER_ADMIN) {
      return ['*'];
    }

    return [
      ...new Set(
        user.role.permissions.map((rp) => rp.permission.name),
      ),
    ];
  }

  async hasRole(userId: string, role: string): Promise<boolean> {
    const userRole = await this.getUserRole(userId);
    return userRole === AppRole.SUPER_ADMIN || userRole === role;
  }

  async hasPermission(userId: string, permission: string): Promise<boolean> {
    const permissions = await this.getUserPermissions(userId);
    return permissions.includes('*') || permissions.includes(permission);
  }

  async hasAllPermissions(userId: string, requiredPermissions: string[]): Promise<boolean> {
    const userPermissions = await this.getUserPermissions(userId);
    if (userPermissions.includes('*')) return true;

    return requiredPermissions.every((perm) => userPermissions.includes(perm));
  }

  /**
   * Group-scoped authorization check:
   * Checks if user has a required GroupRole in a specific group.
   * SUPER_ADMIN and ADMIN bypass all group role checks.
   */
  async hasGroupRole(
    userId: string,
    groupId: string,
    requiredRole: GroupRole,
  ): Promise<boolean> {
    const globalRole = await this.getUserRole(userId);
    if (globalRole === AppRole.SUPER_ADMIN || globalRole === AppRole.ADMIN) {
      return true;
    }

    const member = await this.prisma.groupMember.findUnique({
      where: {
        groupId_userId: { groupId, userId },
        removedAt: null,
      },
      select: { role: true },
    });

    if (!member) return false;

    return hasGroupRoleAtLeast(member.role as GroupRole, requiredRole);
  }
}
