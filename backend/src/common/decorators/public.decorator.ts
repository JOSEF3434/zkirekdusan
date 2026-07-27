// src/common/decorators/public.decorator.ts
import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';

/**
 * Mark a route as public — JwtAuthGuard will skip authentication for it.
 *
 * Usage:
 *   @Public()
 *   @Post('register')
 *   register(...) {}
 */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
