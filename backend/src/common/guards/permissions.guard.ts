// src/common/guards/permissions.guard.ts
import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PERMISSIONS_KEY } from '../decorators/permissions.decorator.js';
import { AppRole } from '../constants/roles.js';
import { JwtPayload } from '../interfaces/jwt-payload.interface.js';
import { AuthorizationService } from '../../modules/authorization/authorization.service.js';

/**
 * Global permissions guard.
 * Reads permission requirements from @Permissions() decorator
 * and checks them against the DB via AuthorizationService.
 *
 * FIX: Previously could receive an undefined user.id — now validates user presence first.
 */
@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly authorizationService: AuthorizationService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredPermissions = this.reflector.getAllAndOverride<string[]>(
      PERMISSIONS_KEY,
      [context.getHandler(), context.getClass()],
    );

    // No @Permissions() decorator — pass through
    if (!requiredPermissions || requiredPermissions.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest<{ user: JwtPayload }>();
    const user = request.user;

    if (!user?.sub) {
      throw new ForbiddenException('Access denied');
    }

    // SUPER_ADMIN bypasses all permission checks
    if (user.role === AppRole.SUPER_ADMIN) {
      return true;
    }

    const hasAll = await this.authorizationService.hasAllPermissions(
      user.sub,
      requiredPermissions,
    );

    if (!hasAll) {
      throw new ForbiddenException(
        `Access denied. Missing permissions: ${requiredPermissions.join(', ')}`,
      );
    }

    return true;
  }
}
