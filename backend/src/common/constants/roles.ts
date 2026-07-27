export enum AppRole {
  SUPER_ADMIN = 'SUPER_ADMIN',
  ADMIN = 'ADMIN',
  MODERATOR = 'MODERATOR',
  CREATOR = 'CREATOR',
  USER = 'USER',
}

export const DEFAULT_ROLES = [
  {
    name: AppRole.SUPER_ADMIN,
    description: 'Full system access',
  },
  {
    name: AppRole.ADMIN,
    description: 'System administrator',
  },
  {
    name: AppRole.MODERATOR,
    description: 'Community moderator',
  },
  {
    name: AppRole.CREATOR,
    description: 'Content creator',
  },
  {
    name: AppRole.USER,
    description: 'Standard user',
  },
];
