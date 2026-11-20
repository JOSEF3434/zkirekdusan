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

  // ─── Auth Login Policy ──────────────────────────────────
  AUTH_POLICY: {
    MANAGE: 'auth.login-policy.manage',
    VIEW: 'auth.login-policy.view',
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

  // ─── Books / Digital Library ─────────────────────────────
  BOOKS: {
    VIEW: 'books.view',
    CREATE: 'books.create',
    UPDATE: 'books.update',
    DELETE: 'books.delete',
    PUBLISH: 'books.publish',
    MANAGE_CATEGORIES: 'books.manage_categories',
    MANAGE_LANGUAGES: 'books.manage_languages',
    MANAGE_LIBRARY: 'books.manage_library',
    DOWNLOAD: 'books.download',
  },

  // ─── Amharic Alephat Learning & Reference ────────────────
  ALEPHAT: {
    VIEW: 'alephat.view',
    CREATE: 'alephat.create',
    UPDATE: 'alephat.update',
    DELETE: 'alephat.delete',
    PUBLISH: 'alephat.publish',
  },

  // ─── Ethiopian Calendar Fasts & Holidays ─────────────────
  CALENDAR: {
    VIEW: 'calendar.view',
    CREATE: 'calendar.create',
    UPDATE: 'calendar.update',
    DELETE: 'calendar.delete',
    MANAGE: 'calendar.manage',
  },
} as const;

export type Permission =
  (typeof PERMISSIONS)[keyof typeof PERMISSIONS][keyof (typeof PERMISSIONS)[keyof typeof PERMISSIONS]];

// ─── Rich permission metadata registry ────────────────────────────────────────
// Single authoritative source for ALL permission definitions.
// Used by the seed to write metadata to DB; returned by GET /admin/rbac/permissions.

export interface PermissionMeta {
  code: string;
  displayName: string;
  description: string;
  category: string;
  riskLevel: 'low' | 'medium' | 'high' | 'critical';
}

export const PERMISSION_REGISTRY: PermissionMeta[] = [
  // ── User Management ──
  { code: 'users.view',           displayName: 'View Users',               description: 'List and search platform users',                       category: 'User Management',       riskLevel: 'low' },
  { code: 'users.create',         displayName: 'Create Users',             description: 'Create new user accounts',                             category: 'User Management',       riskLevel: 'medium' },
  { code: 'users.update',         displayName: 'Edit Users',               description: 'Update user profile and metadata',                     category: 'User Management',       riskLevel: 'medium' },
  { code: 'users.delete',         displayName: 'Delete Users',             description: 'Permanently delete user accounts',                     category: 'User Management',       riskLevel: 'critical' },
  { code: 'users.suspend',        displayName: 'Suspend Users',            description: 'Temporarily suspend user accounts',                    category: 'User Management',       riskLevel: 'high' },
  { code: 'users.ban',            displayName: 'Ban Users',                description: 'Permanently ban a user from the platform',             category: 'User Management',       riskLevel: 'high' },
  { code: 'users.reset_password', displayName: 'Reset Passwords',          description: 'Force reset user account passwords',                   category: 'User Management',       riskLevel: 'high' },
  // ── Roles & Permissions ──
  { code: 'roles.view',           displayName: 'View Roles',               description: 'View platform role definitions and assignments',       category: 'Roles & Permissions',   riskLevel: 'low' },
  { code: 'roles.assign',         displayName: 'Assign Roles',             description: 'Change the platform role of any user',                 category: 'Roles & Permissions',   riskLevel: 'critical' },
  { code: 'roles.update',         displayName: 'Manage RBAC',              description: 'Edit role permission assignments (RBAC management)',   category: 'Roles & Permissions',   riskLevel: 'critical' },
  // ── Groups & Channels ──
  { code: 'groups.view',          displayName: 'View Groups',              description: 'List and inspect all platform groups',                 category: 'Groups & Channels',     riskLevel: 'low' },
  { code: 'groups.create',        displayName: 'Create Groups',            description: 'Create new groups on behalf of users',                 category: 'Groups & Channels',     riskLevel: 'medium' },
  { code: 'groups.update',        displayName: 'Edit Groups',              description: 'Modify group settings and metadata',                   category: 'Groups & Channels',     riskLevel: 'medium' },
  { code: 'groups.delete',        displayName: 'Delete Groups',            description: 'Permanently delete groups and their content',          category: 'Groups & Channels',     riskLevel: 'critical' },
  { code: 'groups.approve',       displayName: 'Approve Groups',           description: 'Approve or reject pending group creation requests',    category: 'Groups & Channels',     riskLevel: 'medium' },
  { code: 'groups.manage_members',displayName: 'Manage Group Members',     description: 'Add or remove members from any group',                 category: 'Groups & Channels',     riskLevel: 'medium' },
  { code: 'groups.suspend',       displayName: 'Suspend Groups',           description: 'Temporarily suspend a group',                          category: 'Groups & Channels',     riskLevel: 'high' },
  { code: 'channels.view',        displayName: 'View Channels',            description: 'List and inspect group channels',                      category: 'Groups & Channels',     riskLevel: 'low' },
  { code: 'channels.create',      displayName: 'Create Channels',          description: 'Create new channels inside groups',                    category: 'Groups & Channels',     riskLevel: 'medium' },
  { code: 'channels.update',      displayName: 'Edit Channels',            description: 'Modify channel settings',                              category: 'Groups & Channels',     riskLevel: 'medium' },
  { code: 'channels.delete',      displayName: 'Delete Channels',          description: 'Delete specific group channels',                       category: 'Groups & Channels',     riskLevel: 'high' },
  { code: 'channels.manage_members', displayName: 'Manage Channel Members', description: 'Control who has access to specific channels',         category: 'Groups & Channels',     riskLevel: 'medium' },
  // ── Content Moderation ──
  { code: 'media.view',           displayName: 'View Media',               description: 'View platform media files for moderation',             category: 'Content Moderation',    riskLevel: 'low' },
  { code: 'media.upload',         displayName: 'Upload Media',             description: 'Upload media files on behalf of users',                category: 'Content Moderation',    riskLevel: 'medium' },
  { code: 'media.update',         displayName: 'Edit Media',               description: 'Update media metadata',                                category: 'Content Moderation',    riskLevel: 'medium' },
  { code: 'media.delete',         displayName: 'Delete Media',             description: 'Delete media files from the platform',                 category: 'Content Moderation',    riskLevel: 'high' },
  { code: 'media.moderate',       displayName: 'Moderate Media',           description: 'Flag, feature, or restrict media content',             category: 'Content Moderation',    riskLevel: 'medium' },
  { code: 'videos.view',          displayName: 'View Videos',              description: 'View and inspect video content',                       category: 'Content Moderation',    riskLevel: 'low' },
  { code: 'videos.update',        displayName: 'Edit Videos',              description: 'Update video metadata and settings',                   category: 'Content Moderation',    riskLevel: 'medium' },
  { code: 'videos.delete',        displayName: 'Delete Videos',            description: 'Remove videos from the platform',                      category: 'Content Moderation',    riskLevel: 'high' },
  { code: 'videos.moderate',      displayName: 'Moderate Videos',          description: 'Flag, restrict, or feature videos',                    category: 'Content Moderation',    riskLevel: 'medium' },
  // ── Reports & Moderation ──
  { code: 'reports.view',         displayName: 'View Reports',             description: 'See all user-submitted reports',                       category: 'Reports & Moderation',  riskLevel: 'low' },
  { code: 'reports.review',       displayName: 'Review Reports',           description: 'Start review of pending reports',                      category: 'Reports & Moderation',  riskLevel: 'medium' },
  { code: 'reports.resolve',      displayName: 'Resolve Reports',          description: 'Mark reports as resolved',                             category: 'Reports & Moderation',  riskLevel: 'medium' },
  { code: 'reports.dismiss',      displayName: 'Dismiss Reports',          description: 'Dismiss invalid or resolved reports',                  category: 'Reports & Moderation',  riskLevel: 'medium' },
  { code: 'spam.view',            displayName: 'View Spam',                description: 'View spam and abuse reports',                          category: 'Reports & Moderation',  riskLevel: 'low' },
  { code: 'spam.review',          displayName: 'Review Spam',              description: 'Review spam reports for action',                       category: 'Reports & Moderation',  riskLevel: 'medium' },
  { code: 'spam.block',           displayName: 'Block Spammers',           description: 'Block accounts identified as spam',                    category: 'Reports & Moderation',  riskLevel: 'high' },
  { code: 'spam.unblock',         displayName: 'Unblock Accounts',         description: 'Remove spam blocks from accounts',                     category: 'Reports & Moderation',  riskLevel: 'medium' },
  // ── Chat & Live Streaming ──
  { code: 'chat.view',            displayName: 'View Chats',               description: 'Inspect conversations for moderation',                 category: 'Chat & Live Streaming', riskLevel: 'medium' },
  { code: 'chat.moderate',        displayName: 'Moderate Chat',            description: 'Take moderation actions in chat',                      category: 'Chat & Live Streaming', riskLevel: 'medium' },
  { code: 'chat.delete',          displayName: 'Delete Messages',          description: 'Remove individual chat messages',                      category: 'Chat & Live Streaming', riskLevel: 'high' },
  { code: 'chat.manage_reports',  displayName: 'Manage Chat Reports',      description: 'Review and resolve chat-specific reports',             category: 'Chat & Live Streaming', riskLevel: 'medium' },
  { code: 'live.view',            displayName: 'View Live Streams',        description: 'Monitor active and past live streams',                 category: 'Chat & Live Streaming', riskLevel: 'low' },
  { code: 'live.manage',          displayName: 'Manage Streams',           description: 'Configure live stream settings and metadata',          category: 'Chat & Live Streaming', riskLevel: 'medium' },
  { code: 'live.moderate',        displayName: 'Moderate Streams',         description: 'Moderate live stream chat and participants',           category: 'Chat & Live Streaming', riskLevel: 'medium' },
  { code: 'live.stop',            displayName: 'Terminate Streams',        description: 'Force-end any active live stream',                     category: 'Chat & Live Streaming', riskLevel: 'high' },
  // ── Platform Operations ──
  { code: 'notifications.view',        displayName: 'View Notifications',       description: 'View platform notification history',               category: 'Platform Operations',   riskLevel: 'low' },
  { code: 'notifications.send',        displayName: 'Send Notifications',       description: 'Send notifications to users',                      category: 'Platform Operations',   riskLevel: 'medium' },
  { code: 'notifications.manage',      displayName: 'Broadcast Notifications',  description: 'Send platform-wide push notifications',            category: 'Platform Operations',   riskLevel: 'high' },
  { code: 'system.view',               displayName: 'View System Info',         description: 'View system status and configuration',             category: 'Platform Operations',   riskLevel: 'low' },
  { code: 'system.manage',             displayName: 'Manage System',            description: 'Manage system-level settings and processes',       category: 'Platform Operations',   riskLevel: 'critical' },
  { code: 'system.settings',           displayName: 'System Settings',          description: 'Modify platform-level configuration',              category: 'Platform Operations',   riskLevel: 'critical' },
  { code: 'audit.view',                displayName: 'View Audit Logs',          description: 'Read the platform admin audit trail',              category: 'Platform Operations',   riskLevel: 'low' },
  { code: 'storage.view',              displayName: 'View Storage',             description: 'Inspect platform storage statistics',              category: 'Platform Operations',   riskLevel: 'low' },
  { code: 'storage.manage',            displayName: 'Manage Storage',           description: 'Run storage cleanup and management tasks',         category: 'Platform Operations',   riskLevel: 'high' },
  { code: 'auth.login-policy.view',    displayName: 'View Login Policy',        description: 'View the platform authentication policy',          category: 'Platform Operations',   riskLevel: 'low' },
  { code: 'auth.login-policy.manage',  displayName: 'Manage Login Policy',      description: 'Update platform authentication requirements',      category: 'Platform Operations',   riskLevel: 'critical' },
  // ── Books & Learning ──
  { code: 'books.view',                displayName: 'View Books',               description: 'View the digital library catalogue',               category: 'Books & Learning',      riskLevel: 'low' },
  { code: 'books.create',              displayName: 'Create Books',             description: 'Add new books to the digital library',             category: 'Books & Learning',      riskLevel: 'medium' },
  { code: 'books.update',              displayName: 'Edit Books',               description: 'Update book metadata and content',                 category: 'Books & Learning',      riskLevel: 'medium' },
  { code: 'books.delete',              displayName: 'Delete Books',             description: 'Remove books from the digital library',            category: 'Books & Learning',      riskLevel: 'high' },
  { code: 'books.publish',             displayName: 'Publish Books',            description: 'Publish or unpublish books',                       category: 'Books & Learning',      riskLevel: 'medium' },
  { code: 'books.manage_categories',   displayName: 'Manage Book Categories',   description: 'Create and manage book categories',               category: 'Books & Learning',      riskLevel: 'medium' },
  { code: 'books.manage_languages',    displayName: 'Manage Dictionary Languages', description: 'Configure supported dictionary languages',       category: 'Books & Learning',      riskLevel: 'medium' },
  { code: 'books.manage_library',      displayName: 'Manage Library',           description: 'Curate and manage the digital library',            category: 'Books & Learning',      riskLevel: 'medium' },
  { code: 'books.download',            displayName: 'Download Books',           description: 'Download books from the library',                  category: 'Books & Learning',      riskLevel: 'low' },
  { code: 'alephat.view',              displayName: 'View Alephat',             description: 'View Amharic alphabet learning content',           category: 'Books & Learning',      riskLevel: 'low' },
  { code: 'alephat.create',            displayName: 'Create Alephat',           description: 'Add new Alephat learning content',                 category: 'Books & Learning',      riskLevel: 'medium' },
  { code: 'alephat.update',            displayName: 'Edit Alephat',             description: 'Update Alephat learning entries',                  category: 'Books & Learning',      riskLevel: 'medium' },
  { code: 'alephat.delete',            displayName: 'Delete Alephat',           description: 'Remove Alephat learning content',                  category: 'Books & Learning',      riskLevel: 'high' },
  { code: 'alephat.publish',           displayName: 'Publish Alephat',          description: 'Publish or unpublish Alephat content',             category: 'Books & Learning',      riskLevel: 'medium' },
  // ── Ethiopian Calendar Fasts & Holidays ──
  { code: 'calendar.view',             displayName: 'View Calendar Events',     description: 'View Ethiopian fasting periods and holidays',       category: 'Calendar',              riskLevel: 'low' },
  { code: 'calendar.create',           displayName: 'Create Calendar Events',   description: 'Create Ethiopian fasting periods and holidays',     category: 'Calendar',              riskLevel: 'medium' },
  { code: 'calendar.update',           displayName: 'Edit Calendar Events',     description: 'Update Ethiopian fasting periods and holidays',     category: 'Calendar',              riskLevel: 'medium' },
  { code: 'calendar.delete',           displayName: 'Delete Calendar Events',   description: 'Remove Ethiopian fasting periods and holidays',     category: 'Calendar',              riskLevel: 'high' },
  { code: 'calendar.manage',           displayName: 'Manage Calendar',          description: 'Full management of fasting and holiday calendar system', category: 'Calendar',        riskLevel: 'medium' },
  // ── User Features (standard USER permissions) ──
  { code: 'profile.read',              displayName: 'Read Profile',             description: 'Read own and others public profiles',              category: 'User Features',         riskLevel: 'low' },
  { code: 'profile.update',            displayName: 'Update Profile',           description: 'Edit own profile information',                     category: 'User Features',         riskLevel: 'low' },
  { code: 'posts.create',              displayName: 'Create Posts',             description: 'Create and publish posts',                         category: 'User Features',         riskLevel: 'low' },
  { code: 'posts.update',              displayName: 'Edit Posts',               description: 'Edit own posts',                                   category: 'User Features',         riskLevel: 'low' },
  { code: 'posts.delete',              displayName: 'Delete Posts',             description: 'Delete own posts',                                 category: 'User Features',         riskLevel: 'low' },
  { code: 'comments.create',           displayName: 'Create Comments',          description: 'Comment on posts and videos',                      category: 'User Features',         riskLevel: 'low' },
  { code: 'comments.delete',           displayName: 'Delete Comments',          description: 'Delete own comments',                              category: 'User Features',         riskLevel: 'low' },
  { code: 'messages.send',             displayName: 'Send Messages',            description: 'Send direct and group messages',                   category: 'User Features',         riskLevel: 'low' },
  { code: 'messages.read',             displayName: 'Read Messages',            description: 'Read conversations',                               category: 'User Features',         riskLevel: 'low' },
  { code: 'messages.pin',              displayName: 'Pin Messages',             description: 'Pin important messages in conversations',          category: 'User Features',         riskLevel: 'low' },
  { code: 'messages.delete_everyone',  displayName: 'Delete for Everyone',      description: 'Delete messages for all participants',             category: 'User Features',         riskLevel: 'low' },
  { code: 'messages.announce',         displayName: 'Send Announcements',       description: 'Send announcement messages in channels',           category: 'User Features',         riskLevel: 'low' },
  { code: 'stories.create',            displayName: 'Create Stories',           description: 'Create and publish stories',                       category: 'User Features',         riskLevel: 'low' },
  { code: 'stories.delete',            displayName: 'Delete Stories',           description: 'Delete own stories',                               category: 'User Features',         riskLevel: 'low' },
  { code: 'reels.create',              displayName: 'Create Reels',             description: 'Create and publish short video reels',             category: 'User Features',         riskLevel: 'low' },
  { code: 'reels.delete',              displayName: 'Delete Reels',             description: 'Delete own reels',                                 category: 'User Features',         riskLevel: 'low' },
  { code: 'uploads.create',            displayName: 'Upload Files',             description: 'Upload files to the platform',                     category: 'User Features',         riskLevel: 'low' },
  { code: 'uploads.delete',            displayName: 'Delete Uploads',           description: 'Delete own uploaded files',                        category: 'User Features',         riskLevel: 'low' },
  { code: 'streams.start',             displayName: 'Start Streams',            description: 'Start a live stream',                              category: 'User Features',         riskLevel: 'low' },
  { code: 'streams.end',               displayName: 'End Streams',              description: 'End own live streams',                             category: 'User Features',         riskLevel: 'low' },
  { code: 'analytics.read',            displayName: 'View Analytics',           description: 'View personal content analytics',                  category: 'User Features',         riskLevel: 'low' },
];

// ─── Flat list for backward-compatible seed usage ─────────────────────────────
export const DEFAULT_PERMISSIONS = PERMISSION_REGISTRY.map((p) => ({
  name: p.code,
  displayName: p.displayName,
  description: p.description,
  category: p.category,
  riskLevel: p.riskLevel,
}));

// ─── Role → Permission assignments ────────────────────────────────────────────
// Used by the seed script for idempotent setup.
// IMPORTANT: Once the DB is initialized, admin changes via RBAC page are authoritative.
// The seed only ADDS missing permissions — it never deletes custom assignments.

export const ROLE_PERMISSIONS: Record<string, string[]> = {
  SUPER_ADMIN: ['*'], // Wildcard — checked in AuthorizationService (never stored as rows)

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
    'system.view', 'audit.view', 'storage.view', 'storage.manage',
    'auth.login-policy.view', 'auth.login-policy.manage',
    'books.view', 'books.create', 'books.update', 'books.delete',
    'books.publish', 'books.manage_categories', 'books.manage_languages', 'books.manage_library', 'books.download',
    'alephat.view', 'alephat.create', 'alephat.update', 'alephat.delete', 'alephat.publish',
    'calendar.view', 'calendar.create', 'calendar.update', 'calendar.delete', 'calendar.manage',
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
    'books.view', 'books.manage_library', 'books.create', 'books.update', 'books.publish',
    'alephat.view', 'alephat.create', 'alephat.update', 'alephat.publish',
    'calendar.view', 'calendar.create', 'calendar.update', 'calendar.manage',
  ],

  SUPPORT: [
    'users.view',
    'reports.view', 'reports.review', 'reports.resolve', 'reports.dismiss',
    'notifications.view',
    'calendar.view',
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
    'books.view', 'books.download',
    'alephat.view',
    'calendar.view',
  ],
};
