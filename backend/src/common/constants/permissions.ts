// src/common/constants/permissions.ts
// Full resource.action permission matrix for the administration system.
// Naming convention: resource.action (all lowercase, dot-separated)

export const PERMISSIONS = {
  // ─── User Management ───────────────────────────────────
  USERS: {
    VIEW: 'users.view',
    CREATE: 'users.create',
    UPDATE: 'users.update',
    DELETE: 'users.delete',
    SUSPEND: 'users.suspend',
    BAN: 'users.ban',
    RESET_PASSWORD: 'users.reset_password',
  },

  // ─── Roles & Permissions ────────────────────────────────
  ROLES: {
    VIEW: 'roles.view',
    ASSIGN: 'roles.assign',
    UPDATE: 'roles.update',
  },

  // ─── Group Management ───────────────────────────────────
  GROUPS: {
    VIEW: 'groups.view',
    CREATE: 'groups.create',
    UPDATE: 'groups.update',
    DELETE: 'groups.delete',
    APPROVE: 'groups.approve',
    MANAGE_MEMBERS: 'groups.manage_members',
    SUSPEND: 'groups.suspend',
  },

  // ─── Channel Management ─────────────────────────────────
  CHANNELS: {
    VIEW: 'channels.view',
    CREATE: 'channels.create',
    UPDATE: 'channels.update',
    DELETE: 'channels.delete',
    MANAGE_MEMBERS: 'channels.manage_members',
  },

  // ─── Media/File Administration ──────────────────────────
  MEDIA: {
    VIEW: 'media.view',
    UPLOAD: 'media.upload',
    UPDATE: 'media.update',
    DELETE: 'media.delete',
    MODERATE: 'media.moderate',
  },

  // ─── Video Administration ───────────────────────────────
  VIDEOS: {
    VIEW: 'videos.view',
    UPDATE: 'videos.update',
    DELETE: 'videos.delete',
    MODERATE: 'videos.moderate',
  },

  // ─── Reports & Moderation ───────────────────────────────
  REPORTS: {
    VIEW: 'reports.view',
    REVIEW: 'reports.review',
    RESOLVE: 'reports.resolve',
    DISMISS: 'reports.dismiss',
  },

  // ─── Spam & Abuse ───────────────────────────────────────
  SPAM: {
    VIEW: 'spam.view',
    REVIEW: 'spam.review',
    BLOCK: 'spam.block',
    UNBLOCK: 'spam.unblock',
  },

  // ─── Chat & Messaging ───────────────────────────────────
  CHAT: {
    VIEW: 'chat.view',
    MODERATE: 'chat.moderate',
    DELETE: 'chat.delete',
    MANAGE_REPORTS: 'chat.manage_reports',
  },

  // ─── Live Streaming ─────────────────────────────────────
  LIVE: {
    VIEW: 'live.view',
    MANAGE: 'live.manage',
    MODERATE: 'live.moderate',
    STOP: 'live.stop',
  },

  // ─── Notifications ──────────────────────────────────────
  NOTIFICATIONS: {
    VIEW: 'notifications.view',
    SEND: 'notifications.send',
    MANAGE: 'notifications.manage',
  },

  // ─── System Management ──────────────────────────────────
  SYSTEM: {
    VIEW: 'system.view',
    MANAGE: 'system.manage',
    SETTINGS: 'system.settings',
  },

  // ─── Audit Logs ─────────────────────────────────────────
  AUDIT: {
    VIEW: 'audit.view',
  },

  // ─── Storage & Cache ────────────────────────────────────
  STORAGE: {
    VIEW: 'storage.view',
    MANAGE: 'storage.manage',
  },

  // ─── Preserved user-facing permissions ──────────────────
  PROFILE: {
    READ: 'profile.read',
    UPDATE: 'profile.update',
  },

  POSTS: {
    CREATE: 'posts.create',
    UPDATE: 'posts.update',
    DELETE: 'posts.delete',
  },

  COMMENTS: {
    CREATE: 'comments.create',
    DELETE: 'comments.delete',
  },

  MESSAGES: {
    SEND: 'messages.send',
    READ: 'messages.read',
    PIN: 'messages.pin',
    DELETE_EVERYONE: 'messages.delete_everyone',
    ANNOUNCE: 'messages.announce',
  },

  STREAMS: {
    START: 'streams.start',
    END: 'streams.end',
  },

  STORIES: {
    CREATE: 'stories.create',
    DELETE: 'stories.delete',
  },

  REELS: {
    CREATE: 'reels.create',
    DELETE: 'reels.delete',
  },

  UPLOADS: {
    CREATE: 'uploads.create',
    DELETE: 'uploads.delete',
  },

  ANALYTICS: {
    READ: 'analytics.read',
  },
} as const;

export type Permission =
  (typeof PERMISSIONS)[keyof typeof PERMISSIONS][keyof (typeof PERMISSIONS)[keyof typeof PERMISSIONS]];

export const DEFAULT_PERMISSIONS = Object.values(PERMISSIONS)
  .flatMap((group) => Object.values(group))
  .map((permission) => ({
    name: permission,
    description: permission,
  }));

// ─── Role → Permission assignments ────────────────────────────────────────────
// Used by the seed script for idempotent setup.

export const ROLE_PERMISSIONS: Record<string, string[]> = {
  SUPER_ADMIN: ['*'], // Wildcard — checked in AuthorizationService

  ADMIN: [
    'users.view', 'users.create', 'users.update', 'users.delete',
    'users.suspend', 'users.ban', 'users.reset_password',
    'roles.view', 'roles.assign', 'roles.update',
    'groups.view', 'groups.create', 'groups.update', 'groups.delete',
    'groups.approve', 'groups.manage_members', 'groups.suspend',
    'channels.view', 'channels.create', 'channels.update', 'channels.delete',
    'channels.manage_members',
    'media.view', 'media.upload', 'media.update', 'media.delete', 'media.moderate',
    'videos.view', 'videos.update', 'videos.delete', 'videos.moderate',
    'reports.view', 'reports.review', 'reports.resolve', 'reports.dismiss',
    'spam.view', 'spam.review', 'spam.block', 'spam.unblock',
    'chat.view', 'chat.moderate', 'chat.delete', 'chat.manage_reports',
    'live.view', 'live.manage', 'live.moderate', 'live.stop',
    'notifications.view', 'notifications.send', 'notifications.manage',
    'system.view',
    'audit.view',
    'storage.view', 'storage.manage',
  ],

  MODERATOR: [
    'users.view',
    'groups.view', 'groups.approve', 'groups.manage_members',
    'channels.view',
    'media.view', 'media.moderate',
    'videos.view', 'videos.moderate',
    'reports.view', 'reports.review', 'reports.resolve', 'reports.dismiss',
    'spam.view', 'spam.review', 'spam.block', 'spam.unblock',
    'chat.view', 'chat.moderate', 'chat.delete', 'chat.manage_reports',
    'live.view', 'live.moderate', 'live.stop',
  ],

  SUPPORT: [
    'users.view',
    'reports.view', 'reports.review', 'reports.resolve', 'reports.dismiss',
    'notifications.view',
  ],

  USER: [
    'profile.read', 'profile.update',
    'posts.create', 'posts.update', 'posts.delete',
    'comments.create', 'comments.delete',
    'messages.send', 'messages.read',
    'stories.create', 'stories.delete',
    'reels.create', 'reels.delete',
    'uploads.create', 'uploads.delete',
    'streams.start', 'streams.end',
  ],
};
