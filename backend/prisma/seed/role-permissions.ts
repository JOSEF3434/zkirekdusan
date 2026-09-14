// prisma/seed/role-permissions.ts
// Idempotent role→permission mapping used by seed.ts
// Source of truth is now permissions.ts ROLE_PERMISSIONS export.
// This file re-exports it so seed.ts can import from a relative path.

export { ROLE_PERMISSIONS } from '../../src/common/constants/permissions.js';
