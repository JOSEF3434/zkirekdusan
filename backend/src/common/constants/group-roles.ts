// src/common/constants/group-roles.ts
// Group-scoped roles — define what a user can do inside a specific group

export enum GroupRole {
  GROUP_ADMIN = 'GROUP_ADMIN',
  MODERATOR = 'MODERATOR',
  MEMBER = 'MEMBER',
  GUEST = 'GUEST',
}

/** Hierarchy — higher index = more permissions */
export const GROUP_ROLE_HIERARCHY: Record<GroupRole, number> = {
  [GroupRole.GROUP_ADMIN]: 4,
  [GroupRole.MODERATOR]: 3,
  [GroupRole.MEMBER]: 2,
  [GroupRole.GUEST]: 1,
};

/**
 * Returns true if `userRole` has at least the required level of `requiredRole`
 */
export function hasGroupRoleAtLeast(
  userRole: GroupRole,
  requiredRole: GroupRole,
): boolean {
  return GROUP_ROLE_HIERARCHY[userRole] >= GROUP_ROLE_HIERARCHY[requiredRole];
}
