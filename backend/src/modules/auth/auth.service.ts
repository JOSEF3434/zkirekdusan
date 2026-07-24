// src/modules/auth/auth.service.ts
import { BadRequestException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RolesService } from '../roles/roles.service.js';
import { JwtService, JwtSignOptions } from '@nestjs/jwt';
import { RegisterDto } from './dto/register.dto.js';
import { PasswordService } from '../../common/service/password.service.js';
import type { StringValue } from 'ms'; // Import the type for the expiration string
import { UsersService } from '../users/users.service.js';
import { PrismaService } from '../../prisma/prisma.service.js';
import { UnauthorizedException } from '@nestjs/common';
import { LoginDto } from './dto/login.dto.js';
import { RefreshTokenDto } from './dto/refresh-token.dto.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly rolesService: RolesService,
    private readonly passwordService: PasswordService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
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
      throw new BadRequestException('Default USER role not found.');
    }

    const passwordHash = await this.passwordService.hash(dto.password);

    const user = await this.usersService.create({
      email: dto.email,
      username: dto.username,
      passwordHash,
      roleId: role.id,
    });

    const accessToken = await this.generateAccessToken(user);

    const refreshToken = await this.generateRefreshToken(user);

    const refreshHash = await this.passwordService.hash(refreshToken);

    await this.usersService.saveRefreshToken(
      user.id,
      refreshHash,
      new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    );

    await this.usersService.createSession({
      userId: user.id,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    });

    return {
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        role: user.role.name,
      },
      accessToken,
      refreshToken,
    };
  }

  async login(dto: LoginDto) {
    const user = await this.usersService.findByEmail(dto.email);

    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }

    if (user.lockedUntil && user.lockedUntil > new Date()) {
      throw new UnauthorizedException('Account is temporarily locked');
    }

    const passwordValid = await this.passwordService.compare(
      dto.password,
      user.passwordHash,
    );

    if (!passwordValid) {
      await this.usersService.incrementFailedLogin(user.id);

      throw new UnauthorizedException('Invalid email or password');
    }

    await this.usersService.updateLastLogin(user.id);

    const accessToken = await this.generateAccessToken(user);

    const refreshToken = await this.generateRefreshToken(user);

    await this.usersService.revokeRefreshTokens(user.id);

    const refreshHash = await this.passwordService.hash(refreshToken);

    await this.usersService.saveRefreshToken(
      user.id,
      refreshHash,
      new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    );

    await this.usersService.createSession({
      userId: user.id,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    });

    return {
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        role: user.role.name,
      },
      accessToken,
      refreshToken,
    };
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
  updateLastLogin(userId: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        lastLoginAt: new Date(),
        failedLoginAttempts: 0,
      },
    });
  }

  incrementFailedLogin(userId: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        failedLoginAttempts: {
          increment: 1,
        },
      },
    });
  }

  async refresh(dto: RefreshTokenDto) {
    if (!dto?.refreshToken) {
      throw new BadRequestException('Refresh token is required');
    }

    let payload: { sub: string };
    try {
      // Verify refresh JWT
      payload = await this.jwtService.verifyAsync<{ sub: string }>(
        dto.refreshToken,
        {
          secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
        },
      );
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    const user = await this.usersService.findById(payload.sub);

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    const storedToken = await this.usersService.findActiveRefreshToken(user.id);

    if (!storedToken) {
      throw new UnauthorizedException('Refresh token not found');
    }

    const matches = await this.passwordService.compare(
      dto.refreshToken,
      storedToken.tokenHash,
    );

    if (!matches) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    await this.usersService.revokeRefreshTokens(user.id);

    const accessToken = await this.generateAccessToken(user);

    const refreshToken = await this.generateRefreshToken(user);

    const refreshHash = await this.passwordService.hash(refreshToken);

    await this.usersService.saveRefreshToken(
      user.id,
      refreshHash,
      new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    );

    return {
      accessToken,
      refreshToken,
    };
  }

  async logout(userId: string) {
    await this.usersService.revokeRefreshTokens(userId);

    await this.usersService.revokeSessions(userId);

    return {
      message: 'Logged out successfully',
    };
  }
}
