// src/modules/auth/auth.service.ts
import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { PasswordService } from '../../common/service/password.service.js';
import { UsersService } from '../users/users.service.js';
import { AuthPolicyService } from '../auth-policy/auth-policy.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshTokenDto } from './dto/refresh-token.dto.js';
import { AuthResponseDto } from './dto/auth-response.dto.js';
import { AppRole } from '../../common/constants/roles.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly passwordService: PasswordService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly authPolicyService: AuthPolicyService,
  ) {}

  async register(dto: RegisterDto): Promise<AuthResponseDto> {
    if (!dto.email && !dto.phoneNumber) {
      throw new BadRequestException(
        'Provide at least one of email or phone number',
      );
    }

    if (dto.email) {
      const emailExists = await this.usersService.findByEmail(dto.email);
      if (emailExists) {
        throw new BadRequestException('Email already registered');
      }
    }

    if (dto.phoneNumber) {
      const phoneExists = await this.usersService.findByPhoneNumber(
        dto.phoneNumber,
      );
      if (phoneExists) {
        throw new BadRequestException('Phone number already registered');
      }
    }

    if (dto.username) {
      const usernameExists = await this.usersService.findByUsername(
        dto.username,
      );
      if (usernameExists) {
        throw new BadRequestException('Username already taken');
      }
    }

    const defaultRole = await this.usersService.getRoleByName(AppRole.USER);
    if (!defaultRole) {
      throw new BadRequestException('Default USER role not found in system');
    }

    const passwordHash = await this.passwordService.hash(dto.password);

    const user = await this.usersService.create({
      email: dto.email,
      phoneNumber: dto.phoneNumber,
      username: dto.username,
      firstName: dto.firstName,
      lastName: dto.lastName,
      passwordHash,
      roleId: defaultRole.id,
    });

    const accessToken = await this.generateAccessToken(
      user.id,
      user.email ?? user.phoneNumber ?? user.username ?? 'user',
      user.role.name,
    );
    const refreshToken = await this.generateRefreshToken(user.id);

    const refreshHash = await this.passwordService.hash(refreshToken);
    const refreshExpires = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    await this.usersService.saveRefreshToken(
      user.id,
      refreshHash,
      refreshExpires,
    );
    await this.usersService.createSession({
      userId: user.id,
      expiresAt: refreshExpires,
    });

    return {
      user: {
        id: user.id,
        email: user.email,
        phoneNumber: user.phoneNumber,
        username: user.username,
        role: user.role.name,
      },
      accessToken,
      refreshToken,
    };
  }

  async login(dto: LoginDto): Promise<AuthResponseDto> {
    // ── Step 1: Fetch the active login policy ──────────────────────
    const policy = await this.authPolicyService.getActivePolicy();

    // ── Step 2: Enforce policy-specific identifier requirements ───
    let user: Awaited<ReturnType<typeof this.usersService.findByEmail>> | null = null;

    switch (policy.activePolicy) {
      case 'SINGLE_IDENTIFIER': {
        // Exactly one of email / phone / username must be supplied and allowed.
        user = await this.resolveSingleIdentifier(dto, policy);
        break;
      }

      case 'DUAL_IDENTIFIER': {
        // Two specific identifiers must be supplied and both must resolve to the same account.
        user = await this.resolveDualIdentifier(dto, policy);
        break;
      }

      case 'ALL_IDENTIFIERS': {
        // All three identifiers must be supplied and all must belong to the same account.
        user = await this.resolveAllIdentifiers(dto);
        break;
      }

      default:
        throw new UnauthorizedException('Invalid credentials');
    }

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // ── Step 3: Check account status ─────────────────────────────
    if (user.status !== 'ACTIVE') {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (user.lockedUntil && user.lockedUntil > new Date()) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // ── Step 4: Validate password ──────────────────────────────────
    const isPasswordValid = await this.passwordService.compare(
      dto.password,
      user.passwordHash,
    );

    if (!isPasswordValid) {
      await this.usersService.incrementFailedLogin(user.id);
      throw new UnauthorizedException('Invalid credentials');
    }

    await this.usersService.updateLastLogin(user.id);

    // ── Step 5: Issue tokens ───────────────────────────────────────
    const accessToken = await this.generateAccessToken(
      user.id,
      user.email ?? user.phoneNumber ?? user.username ?? 'user',
      user.role.name,
    );
    const refreshToken = await this.generateRefreshToken(user.id);

    await this.usersService.revokeRefreshTokens(user.id);

    const refreshHash = await this.passwordService.hash(refreshToken);
    const refreshExpires = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    await this.usersService.saveRefreshToken(
      user.id,
      refreshHash,
      refreshExpires,
    );
    await this.usersService.createSession({
      userId: user.id,
      expiresAt: refreshExpires,
    });

    return {
      user: {
        id: user.id,
        email: user.email,
        phoneNumber: user.phoneNumber,
        username: user.username,
        role: user.role.name,
      },
      accessToken,
      refreshToken,
    };
  }

  // ── Private: Policy Enforcement Helpers ───────────────────────────

  /**
   * SINGLE_IDENTIFIER mode:
   * Accept any enabled identifier type.
   * If multiple identifiers are supplied in the request, all must be permitted by policy
   * and all must resolve to the exact same registered account.
   */
  private async resolveSingleIdentifier(
    dto: LoginDto,
    policy: { allowEmail: boolean; allowPhone: boolean; allowUsername: boolean },
  ) {
    type ResolvedUser = NonNullable<
      Awaited<ReturnType<typeof this.usersService.findByEmail>>
    >;
    const matchedUsers: ResolvedUser[] = [];

    if (dto.email) {
      if (!policy.allowEmail) throw new UnauthorizedException('Invalid credentials');
      const u = await this.usersService.findByEmail(dto.email);
      if (!u) throw new UnauthorizedException('Invalid credentials');
      matchedUsers.push(u);
    }
    if (dto.phoneNumber) {
      if (!policy.allowPhone) throw new UnauthorizedException('Invalid credentials');
      const u = await this.usersService.findByPhoneNumber(dto.phoneNumber);
      if (!u) throw new UnauthorizedException('Invalid credentials');
      matchedUsers.push(u);
    }
    if (dto.username) {
      if (!policy.allowUsername) throw new UnauthorizedException('Invalid credentials');
      const u = await this.usersService.findByUsername(dto.username);
      if (!u) throw new UnauthorizedException('Invalid credentials');
      matchedUsers.push(u);
    }

    const firstUser = matchedUsers[0];
    if (!firstUser) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Security: All supplied identifiers must resolve to the exact same account
    const firstId = firstUser.id;
    for (const u of matchedUsers) {
      if (u.id !== firstId) {
        throw new UnauthorizedException('Invalid credentials');
      }
    }

    return firstUser;
  }

  /**
   * DUAL_IDENTIFIER mode:
   * Require exactly two specific identifiers that both belong to the same account.
   * SECURITY: Never reveal which identifier doesn't match. Always use 'Invalid credentials'.
   */
  private async resolveDualIdentifier(
    dto: LoginDto,
    policy: { dualCombination?: string | null },
  ) {
    const combo = policy.dualCombination;

    if (combo === 'EMAIL_PHONE') {
      if (!dto.email || !dto.phoneNumber) {
        throw new UnauthorizedException('Invalid credentials');
      }
      const byEmail = await this.usersService.findByEmail(dto.email);
      if (!byEmail) throw new UnauthorizedException('Invalid credentials');
      const byPhone = await this.usersService.findByPhoneNumber(dto.phoneNumber);
      if (!byPhone) throw new UnauthorizedException('Invalid credentials');
      // Both identifiers must belong to the same account
      if (byEmail.id !== byPhone.id) throw new UnauthorizedException('Invalid credentials');
      return byEmail;
    }

    if (combo === 'EMAIL_USERNAME') {
      if (!dto.email || !dto.username) {
        throw new UnauthorizedException('Invalid credentials');
      }
      const byEmail = await this.usersService.findByEmail(dto.email);
      if (!byEmail) throw new UnauthorizedException('Invalid credentials');
      const byUsername = await this.usersService.findByUsername(dto.username);
      if (!byUsername) throw new UnauthorizedException('Invalid credentials');
      if (byEmail.id !== byUsername.id) throw new UnauthorizedException('Invalid credentials');
      return byEmail;
    }

    if (combo === 'PHONE_USERNAME') {
      if (!dto.phoneNumber || !dto.username) {
        throw new UnauthorizedException('Invalid credentials');
      }
      const byPhone = await this.usersService.findByPhoneNumber(dto.phoneNumber);
      if (!byPhone) throw new UnauthorizedException('Invalid credentials');
      const byUsername = await this.usersService.findByUsername(dto.username);
      if (!byUsername) throw new UnauthorizedException('Invalid credentials');
      if (byPhone.id !== byUsername.id) throw new UnauthorizedException('Invalid credentials');
      return byPhone;
    }

    throw new UnauthorizedException('Invalid credentials');
  }

  /**
   * ALL_IDENTIFIERS mode:
   * Require email + phone + username, all belonging to the same account.
   */
  private async resolveAllIdentifiers(dto: LoginDto) {
    if (!dto.email || !dto.phoneNumber || !dto.username) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const byEmail = await this.usersService.findByEmail(dto.email);
    if (!byEmail) throw new UnauthorizedException('Invalid credentials');

    const byPhone = await this.usersService.findByPhoneNumber(dto.phoneNumber);
    if (!byPhone) throw new UnauthorizedException('Invalid credentials');

    const byUsername = await this.usersService.findByUsername(dto.username);
    if (!byUsername) throw new UnauthorizedException('Invalid credentials');

    // All three must reference the exact same account — prevent cross-account matching
    if (byEmail.id !== byPhone.id || byEmail.id !== byUsername.id) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return byEmail;
  }

  async refresh(
    dto: RefreshTokenDto,
  ): Promise<{ accessToken: string; refreshToken: string }> {
    if (!dto?.refreshToken) {
      throw new BadRequestException('Refresh token is required');
    }

    let payload: { sub: string };
    try {
      payload = await this.jwtService.verifyAsync<{ sub: string }>(
        dto.refreshToken,
        {
          secret: this.configService.getOrThrow<string>('JWT_REFRESH_SECRET'),
        },
      );
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    const user = await this.usersService.findById(payload.sub);
    if (!user || user.status !== 'ACTIVE') {
      throw new UnauthorizedException('User account invalid or inactive');
    }

    const activeToken = await this.usersService.findActiveRefreshToken(user.id);
    if (!activeToken) {
      throw new UnauthorizedException('Refresh token revoked or not found');
    }

    const matches = await this.passwordService.compare(
      dto.refreshToken,
      activeToken.tokenHash,
    );

    if (!matches) {
      // Security warning: possible token reuse attempt — revoke all user tokens
      await this.usersService.revokeRefreshTokens(user.id);
      throw new UnauthorizedException(
        'Invalid refresh token — all sessions revoked for security',
      );
    }

    await this.usersService.revokeRefreshTokens(user.id);

    const accessToken = await this.generateAccessToken(
      user.id,
      user.email ?? user.phoneNumber ?? user.username ?? 'user',
      user.role.name,
    );
    const newRefreshToken = await this.generateRefreshToken(user.id);

    const newRefreshHash = await this.passwordService.hash(newRefreshToken);
    const refreshExpires = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    await this.usersService.saveRefreshToken(
      user.id,
      newRefreshHash,
      refreshExpires,
    );

    return {
      accessToken,
      refreshToken: newRefreshToken,
    };
  }

  async getLoginConfig() {
    return this.authPolicyService.getActivePolicy();
  }

  async logout(userId: string): Promise<{ message: string }> {
    await this.usersService.revokeRefreshTokens(userId);
    await this.usersService.revokeSessions(userId);
    return { message: 'Successfully logged out' };
  }

  private async generateAccessToken(
    userId: string,
    identifier: string,
    role: string,
  ): Promise<string> {
    const payload = { sub: userId, email: identifier, role };
    return this.jwtService.signAsync(payload, {
      secret: this.configService.getOrThrow<string>('JWT_ACCESS_SECRET'),
      expiresIn: (this.configService.get<string>('JWT_ACCESS_EXPIRES') ??
        '15m') as any,
    });
  }

  private async generateRefreshToken(userId: string): Promise<string> {
    const payload = { sub: userId };
    return this.jwtService.signAsync(payload, {
      secret: this.configService.getOrThrow<string>('JWT_REFRESH_SECRET'),
      expiresIn: (this.configService.get<string>('JWT_REFRESH_EXPIRES') ??
        '7d') as any,
    });
  }
}
