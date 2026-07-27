// src/common/decorators/current-user.decorator.ts
import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { JwtPayload } from '../interfaces/jwt-payload.interface.js';

/**
 * Extracts the authenticated user from the request.
 * The user is set by JwtStrategy.validate() after successful JWT verification.
 *
 * Usage:
 *   @Get('me')
 *   me(@CurrentUser() user: JwtPayload) { ... }
 *
 *   @Get('id')
 *   getById(@CurrentUser('sub') userId: string) { ... }
 */
export const CurrentUser = createParamDecorator(
  (field: keyof JwtPayload | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest<{ user: JwtPayload }>();
    const user = request.user;

    if (field) {
      return user?.[field];
    }

    return user;
  },
);
