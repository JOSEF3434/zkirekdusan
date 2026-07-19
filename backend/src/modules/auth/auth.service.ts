// src/modules/auth/auth.service.ts
import { BadRequestException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RolesService } from '../roles/roles.service.js';
import { JwtService, JwtSignOptions } from '@nestjs/jwt';
import { RegisterDto } from './dto/register.dto.js';
import { PasswordService } from '../../common/service/password.service.js';
import type { StringValue } from 'ms'; // Import the type for the expiration string
import { UsersService } from '../users/users.service.js';

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
    if (emailExists) throw new BadRequestException('Email already exists');

    const usernameExists = await this.usersService.findByUsername(dto.username);
    if (usernameExists)
      throw new BadRequestException('Username already exists');

    const role = await this.rolesService.getDefaultRole();
    if (!role) throw new BadRequestException('Default role not found');

    const passwordHash = await this.passwordService.hash(dto.password);

    return this.usersService.create({
      email: dto.email,
      username: dto.username,
      passwordHash,
      roleId: role.id,
    });
  }

  async generateAccessToken(user: {
    id: string;
    email?: string;
    role?: { name?: string };
  }): Promise<string> {
    const payload = { sub: user.id, email: user.email, role: user?.role?.name };
    return this.jwtService.signAsync(payload);
  }

  async generateRefreshToken(user: { id: string }): Promise<string> {
    const payload = { sub: user.id };
    const secret = this.configService.get<string>('JWT_REFRESH_SECRET');

    // Cast this explicitly so TypeScript knows it matches ms's layout
    const expiresIn = this.configService.get<string>(
      'JWT_REFRESH_EXPIRES',
    ) as StringValue;

    const options: JwtSignOptions = { secret, expiresIn };
    return this.jwtService.signAsync(payload, options);
  }

  // Move the HTTP logic to your controller! This service method should just return the user profile.
  async getMe(userPayload: { sub: string }) {
    return this.usersService.findById(userPayload.sub);
  }
}
