// src/common/constants/roles.ts
// Global platform roles — only 3 tiers at the platform level.
// Group-level roles (GROUP_ADMIN, MODERATOR, MEMBER, GUEST) live in group-roles.ts

export enum AppRole {
  SUPER_ADMIN = 'SUPER_ADMIN',
  ADMIN = 'ADMIN',
  USER = 'USER',
}

export const DEFAULT_ROLES = [
  {
    name: AppRole.SUPER_ADMIN,
    description:
      'Full platform access — can approve groups, manage all resources',
  },
  {
    name: AppRole.ADMIN,
    description: 'Platform administrator — can approve groups, manage users',
  },
  {
    name: AppRole.USER,
    description: 'Standard platform user',
  },
] as const;
