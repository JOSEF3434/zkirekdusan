// src/modules/auth/auth.service.ts

import { BadRequestException, Get, Injectable, UseGuards } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service.js';
import { RolesService } from '../roles/roles.service.js';
import { JwtService, JwtSignOptions } from '@nestjs/jwt';
import { RegisterDto } from './dto/register.dto.js';
import { PasswordService } from '@/common/service/password.service.js';
import { JwtPayload } from './interfaces/jwt-payload.interface.js';
import { JwtAuthGuard } from './guards/jwt-auth.guard.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly rolesService: RolesService,
    private readonly passwordService: PasswordService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}
  async register(dto: RegisterDto) {
    const emailExists = await this.usersService.findByEmail(dto.email);

    if (emailExists) {
      throw new BadRequestException('Email already exists');
    }

    const usernameExists = await this.usersService.findByUsername(dto.username);

    if (usernameExists) {
      throw new BadRequestException('Username already exists');
    }

    const role = await this.rolesService.getDefaultRole();

    if (!role) {
      throw new BadRequestException('Default role not found');
    }

    const passwordHash = await this.passwordService.hash(dto.password);

    const user = await this.usersService.create({
      email: dto.email,
      username: dto.username,
      passwordHash,
      roleId: role.id,
    });

    return user;
  }

  private async generateAccessToken(user: any): Promise<string> {
    const payload = {
      sub: user.id,
      email: user.email,
      role: user?.role?.name,
    };

    const token = await this.jwtService.signAsync(payload);
    return token;
  }

  private async generateRefreshToken(user: any): Promise<string> {
    const payload = { sub: user.id };

    const secret = this.configService.get<string>('JWT_REFRESH_SECRET');
    const expiresIn = this.configService.get<string>('JWT_REFRESH_EXPIRES');

    const options: JwtSignOptions = {
      secret,
      expiresIn,
    };

    const token = await this.jwtService.signAsync(payload, options);
    return token;
  }
  @Get('me')
  @UseGuards(JwtAuthGuard)
  getMe(
    @CurrentUser()
    user: JwtPayload,
  ) {
    return this.authService.getMe(user);
  }
}
