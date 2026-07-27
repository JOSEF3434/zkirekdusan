// src/common/decorators/permissions.decorator.ts
import { SetMetadata } from '@nestjs/common';

export const PERMISSIONS_KEY = 'permissions';

/**
 * Restrict a route to users who hold all specified permissions.
 *
 * Usage:
 *   @Permissions('users.read', 'users.update')
 *   @Get()
 *   listUsers() {}
 */
export const Permissions = (...permissions: string[]) =>
  SetMetadata(PERMISSIONS_KEY, permissions);
