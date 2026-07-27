// src/common/decorators/group-roles.decorator.ts
import { SetMetadata } from '@nestjs/common';
import { GroupRole } from '../constants/group-roles.js';

export const GROUP_ROLES_KEY = 'groupRoles';

/**
 * Restrict a group-scoped route to members with at least the given group role.
 * Must be used together with GroupMembershipGuard.
 *
 * Usage:
 *   @GroupRoles(GroupRole.GROUP_ADMIN)
 *   @Patch(':groupId')
 *   updateGroup() {}
 */
export const GroupRoles = (...roles: GroupRole[]) =>
  SetMetadata(GROUP_ROLES_KEY, roles);
