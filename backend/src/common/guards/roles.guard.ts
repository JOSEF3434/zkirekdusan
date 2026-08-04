// src/common/guards/roles.guard.ts
import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../decorators/roles.decorator.js';
import { AppRole } from '../constants/roles.js';
import { JwtPayload } from '../interfaces/jwt-payload.interface.js';

/**
 * Global roles guard.
 *
 * FIX: Previously compared user.role (an object) against a string — always failed.
 * Now reads `user.role` which is embedded as a string in the JWT payload by JwtStrategy.
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<AppRole[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    // No @Roles() decorator — allow all authenticated users through
    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest<{ user: JwtPayload }>();
    const user = request.user;

    if (!user) {
      // JwtAuthGuard should have caught this already
      throw new ForbiddenException('Access denied');
    }

    // SUPER_ADMIN bypasses all role checks
    if ((user.role as AppRole) === AppRole.SUPER_ADMIN) {
      return true;
    }

    if (!requiredRoles.includes(user.role as AppRole)) {
      throw new ForbiddenException(
        `Access denied. Required role: ${requiredRoles.join(' or ')}`,
      );
    }

    return true;
  }
}
