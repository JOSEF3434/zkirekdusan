export const PERMISSIONS = {
  USERS: {
    READ: 'users.read',
    CREATE: 'users.create',
    UPDATE: 'users.update',
    DELETE: 'users.delete',
  },

  ROLES: {
    READ: 'roles.read',
    CREATE: 'roles.create',
    UPDATE: 'roles.update',
    DELETE: 'roles.delete',
  },

  PERMISSIONS: {
    READ: 'permissions.read',
    CREATE: 'permissions.create',
    UPDATE: 'permissions.update',
    DELETE: 'permissions.delete',
  },

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

  VIDEOS: {
    UPLOAD: 'videos.upload',
    UPDATE: 'videos.update',
    DELETE: 'videos.delete',
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

  CHAT: {
    READ: 'chat.read',
    WRITE: 'chat.write',
    DELETE: 'chat.delete',
  },

  UPLOADS: {
    CREATE: 'uploads.create',
    DELETE: 'uploads.delete',
  },

  ANALYTICS: {
    READ: 'analytics.read',
  },

  SYSTEM: {
    MANAGE: 'system.manage',
  },
} as const;
export const DEFAULT_PERMISSIONS = Object.values(PERMISSIONS)
  .flatMap((group) => Object.values(group))
  .map((permission) => ({
    name: permission,
    description: permission,
  }));
