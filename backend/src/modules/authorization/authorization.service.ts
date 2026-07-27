import { PrismaService } from '../../prisma/prisma.service.js';
import {
  Injectable,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';

@Injectable()
export class AuthorizationService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Get complete user with role and permissions
   */
  private async getUserWithRole(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: {
        id: userId,
      },
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
      throw new NotFoundException('User not found.');
    }

    return user;
  }

  /**
   * Get user's role
   */
  async getUserRole(userId: string): Promise<string> {
    const user = await this.getUserWithRole(userId);

    return user.role.name;
  }

  /**
   * Get all user permissions
   */
  async getUserPermissions(userId: string): Promise<string[]> {
    const user = await this.getUserWithRole(userId);

    return [
      ...new Set(
        user.role.permissions.map(
          (rolePermission) => rolePermission.permission.name,
        ),
      ),
    ];
  }

  /**
   * Check single role
   */
  async hasRole(userId: string, role: string): Promise<boolean> {
    const userRole = await this.getUserRole(userId);

    return userRole === role;
  }

  /**
   * Check multiple roles
   */
  async hasAnyRole(userId: string, roles: string[]): Promise<boolean> {
    const userRole = await this.getUserRole(userId);

    return roles.includes(userRole);
  }

  /**
   * Check one permission
   */
  async hasPermission(userId: string, permission: string): Promise<boolean> {
    const permissions = await this.getUserPermissions(userId);

    return permissions.includes(permission);
  }

  /**
   * Check if user has ANY permission
   */
  async hasAnyPermission(
    userId: string,
    permissions: string[],
  ): Promise<boolean> {
    const userPermissions = await this.getUserPermissions(userId);

    return permissions.some((permission) =>
      userPermissions.includes(permission),
    );
  }

  /**
   * Check if user has ALL permissions
   */
  async hasAllPermissions(
    userId: string,
    permissions: string[],
  ): Promise<boolean> {
    const userPermissions = await this.getUserPermissions(userId);

    return permissions.every((permission) =>
      userPermissions.includes(permission),
    );
  }

  /**
   * Require role or throw exception
   */
  async authorizeRole(userId: string, roles: string[]): Promise<void> {
    const hasRole = await this.hasAnyRole(userId, roles);

    if (!hasRole) {
      throw new ForbiddenException('You do not have the required role.');
    }
  }

  /**
   * Require permission or throw exception
   */
  async authorizePermission(
    userId: string,
    permissions: string[],
  ): Promise<void> {
    const hasPermission = await this.hasAnyPermission(userId, permissions);

    if (!hasPermission) {
      throw new ForbiddenException('You do not have the required permission.');
    }
  }

  /**
   * Return authorization summary
   */
  async getAuthorizationInfo(userId: string) {
    const user = await this.getUserWithRole(userId);

    return {
      userId: user.id,
      email: user.email,
      username: user.username,
      role: user.role.name,
      permissions: user.role.permissions.map((rp) => rp.permission.name),
    };
  }
}
