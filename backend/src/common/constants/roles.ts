// src/common/constants/roles.ts
// Global platform roles — 5 tiers at the platform level.
// Group-level roles (GROUP_ADMIN, MODERATOR, MEMBER, GUEST) live in group-roles.ts

export enum AppRole {
  SUPER_ADMIN = 'SUPER_ADMIN',
  ADMIN = 'ADMIN',
  MODERATOR = 'MODERATOR',
  SUPPORT = 'SUPPORT',
  USER = 'USER',
}

export const DEFAULT_ROLES = [
  {
    name: AppRole.SUPER_ADMIN,
    description:
      'Full platform access — bypasses all permission checks; can manage all resources and settings',
  },
  {
    name: AppRole.ADMIN,
    description:
      'Platform administrator — can manage users, groups, content, reports, and all admin sections except system.settings',
  },
  {
    name: AppRole.MODERATOR,
    description:
      'Content moderator — can view users, moderate content/reports/chat/live; cannot manage roles or system settings',
  },
  {
    name: AppRole.SUPPORT,
    description:
      'Support agent — can view reports, resolve support tickets, view users and notifications',
  },
  {
    name: AppRole.USER,
    description: 'Standard platform user',
  },
] as const;

/** Admin-tier roles — can access /admin routes */
export const ADMIN_ROLES: AppRole[] = [
  AppRole.SUPER_ADMIN,
  AppRole.ADMIN,
  AppRole.MODERATOR,
  AppRole.SUPPORT,
];
