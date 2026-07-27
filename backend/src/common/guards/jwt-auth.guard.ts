// src/common/guards/jwt-auth.guard.ts
import {
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator.js';

/**
 * Global JWT authentication guard.
 * - Skips routes decorated with @Public()
 * - Throws UnauthorizedException when JWT is missing/invalid (instead of returning null)
 * - Registered as APP_GUARD so it applies to every route by default
 */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private readonly reflector: Reflector) {
    super();
  }

  canActivate(context: ExecutionContext) {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    return super.canActivate(context);
  }

  /**
   * Override handleRequest to throw a proper 401 when authentication fails
   * instead of returning null and causing downstream PrismaClientValidationError
   */
  handleRequest<TUser>(
    err: Error | null,
    user: TUser | false | null,
    info: { message?: string } | Error | null,
  ): TUser {
    if (err) {
      throw err;
    }

    if (!user) {
      const message =
        info instanceof Error
          ? info.message
          : info?.message ?? 'Authentication required';

      throw new UnauthorizedException(message);
    }

    return user;
  }
}
