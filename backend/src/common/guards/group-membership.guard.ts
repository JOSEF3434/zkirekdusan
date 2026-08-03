// src/common/guards/group-membership.guard.ts
import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../prisma/prisma.service.js';
import { GROUP_ROLES_KEY } from '../decorators/group-roles.decorator.js';
import { GroupRole, hasGroupRoleAtLeast } from '../constants/group-roles.js';
import { AppRole } from '../constants/roles.js';
import { JwtPayload } from '../interfaces/jwt-payload.interface.js';

/**
 * Group membership & role guard.
 *
 * Extracts `groupId` from request params and verifies:
 * 1. The group exists and is ACTIVE
 * 2. The user is a member of the group
 * 3. The member's group role satisfies the @GroupRoles() requirement
 *
 * SUPER_ADMIN and ADMIN bypass membership checks.
 *
 * Usage — apply directly on a specific route or controller:
 *   @UseGuards(GroupMembershipGuard)
 *   @GroupRoles(GroupRole.GROUP_ADMIN)
 *   @Patch(':groupId')
 *   updateGroup() {}
 */
@Injectable()
export class GroupMembershipGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<{
      user: JwtPayload;
      params: Record<string, string>;
      groupMember?: { role: GroupRole };
    }>();

    const user = request.user;

    if (!user?.sub) {
      throw new ForbiddenException('Authentication required');
    }

    // Platform admins can access any group
    if (user.role === AppRole.SUPER_ADMIN || user.role === AppRole.ADMIN) {
      return true;
    }

    const groupId = request.params['groupId'];
    if (!groupId) {
      // No groupId in params — guard has nothing to check
      return true;
    }

    // Verify the group exists and is active
    const group = await this.prisma.group.findUnique({
      where: { id: groupId, deletedAt: null },
      select: { id: true, status: true },
    });

    if (!group) {
      throw new NotFoundException('Group not found');
    }

    if (group.status !== 'ACTIVE') {
      throw new ForbiddenException('This group is not active');
    }

    // Check membership
    const membership = await this.prisma.groupMember.findUnique({
      where: {
        groupId_userId: { groupId, userId: user.sub },
        removedAt: null,
      },
      select: { role: true },
    });

    if (!membership) {
      throw new ForbiddenException('You are not a member of this group');
    }

    // Attach membership to request for downstream use
    request.groupMember = { role: membership.role as GroupRole };

    // Check group role requirement if @GroupRoles() is set
    const requiredGroupRoles = this.reflector.getAllAndOverride<GroupRole[]>(
      GROUP_ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (requiredGroupRoles && requiredGroupRoles.length > 0) {
      const memberRole = membership.role as GroupRole;
      const hasRequiredRole = requiredGroupRoles.some((required) =>
        hasGroupRoleAtLeast(memberRole, required),
      );

      if (!hasRequiredRole) {
        throw new ForbiddenException(
          `This action requires group role: ${requiredGroupRoles.join(' or ')}`,
        );
      }
    }

    return true;
  }
}
