import { Controller, Get, UseGuards } from '@nestjs/common';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';

import type { JwtPayload } from '../auth/interfaces/jwt-payload.interface.js';

import { AuthService } from '../auth/auth.service.js';

import { CurrentUser } from '../auth/decorators/Current-user.decorator.js';

import { Roles } from '../../common/decorators/roles.decorator.js';

import { Permissions } from '../../common/decorators/permissions.decorator.js';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly authService: AuthService) {}

  @Get('me')
  me(@CurrentUser() user: JwtPayload) {
    return this.authService.getMe(user);
  }

  @Get()
  @Roles('ADMIN')
  @Permissions('users.read')
  findAll() {
    return {
      message: 'Users access granted',

      data: [
        {
          id: 1,
          username: 'admin',
        },
        {
          id: 2,
          username: 'creator',
        },
      ],
    };
  }
}
