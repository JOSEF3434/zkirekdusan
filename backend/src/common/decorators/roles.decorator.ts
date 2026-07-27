// src/common/decorators/roles.decorator.ts
import { SetMetadata } from '@nestjs/common';
import { AppRole } from '../constants/roles.js';

export const ROLES_KEY = 'roles';

/**
 * Restrict a route to specific global platform roles.
 *
 * Usage:
 *   @Roles(AppRole.ADMIN, AppRole.SUPER_ADMIN)
 *   @Get('admin-only')
 *   adminOnly() {}
 */
export const Roles = (...roles: AppRole[]) => SetMetadata(ROLES_KEY, roles);
