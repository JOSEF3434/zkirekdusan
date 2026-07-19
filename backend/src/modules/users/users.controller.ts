import { Controller, Get, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import type { JwtPayload } from '../auth/interfaces/jwt-payload.interface.js';
import { AuthService } from '../auth/auth.service.js';
import { CurrentUser } from '../auth/decorators/urrent-user.decorator.js';

@Controller('users')
export class UsersController {
  constructor(private readonly authService: AuthService) {}

  @Get('me')
  @UseGuards(JwtAuthGuard)
  getMe(
    @CurrentUser()
    user: JwtPayload,
  ) {
    return this.authService.getMe(user);
  }
}
