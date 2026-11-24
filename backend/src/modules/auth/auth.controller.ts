// src/modules/auth/auth.controller.ts
import { Body, Controller, Get, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { SkipThrottle, Throttle } from '@nestjs/throttler';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { AuthService } from './auth.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshTokenDto } from './dto/refresh-token.dto.js';
import { AuthResponseDto } from './dto/auth-response.dto.js';
import {
  GoogleAuthDto,
  GoogleLinkAccountDto,
  UserIdentitiesDto,
} from './dto/google-auth.dto.js';
import { Public } from '../../common/decorators/public.decorator.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Authentication')
@Controller('auth')
@Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 requests per minute for auth endpoints
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @SkipThrottle() // Public read-only config — not a sensitive auth endpoint; skip the class-level 5/min limit
  @Get('login-config')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Get active login identifier policy configuration' })
  @ApiResponse({ status: 200, description: 'Current login policy configuration' })
  getLoginConfig() {
    return this.authService.getLoginConfig();
  }

  @Public()
  @Post('register')
  @ApiOperation({ summary: 'Register a new platform account' })
  @ApiResponse({ status: 201, type: AuthResponseDto })
  @ApiResponse({ status: 400, description: 'Email/Username already exists' })
  register(@Body() dto: RegisterDto): Promise<AuthResponseDto> {
    return this.authService.register(dto);
  }

  @Public()
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Authenticate user and obtain JWT tokens' })
  @ApiResponse({ status: 200, type: AuthResponseDto })
  @ApiResponse({
    status: 401,
    description: 'Invalid credentials or inactive account',
  })
  login(@Body() dto: LoginDto): Promise<AuthResponseDto> {
    return this.authService.login(dto);
  }

  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Rotate refresh token and issue new access token' })
  @ApiResponse({ status: 200, description: 'Tokens rotated successfully' })
  @ApiResponse({ status: 401, description: 'Invalid or revoked refresh token' })
  refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refresh(dto);
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Revoke active refresh tokens and logout' })
  @ApiResponse({ status: 200, description: 'Logout successful' })
  logout(@CurrentUser('sub') userId: string) {
    return this.authService.logout(userId);
  }

  // ── Google Authentication & Identity Endpoints ────────────────────

  @Public()
  @Post('google')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Authenticate or register via Google OpenID Connect ID token',
  })
  @ApiResponse({ status: 200, type: AuthResponseDto })
  @ApiResponse({
    status: 401,
    description: 'Invalid, expired, unverified, or unauthorized Google token',
  })
  @ApiResponse({
    status: 409,
    description:
      'Account with this email already exists — requires linking via password',
  })
  googleAuth(@Body() dto: GoogleAuthDto): Promise<AuthResponseDto> {
    return this.authService.authenticateWithGoogle(dto);
  }

  @Public()
  @Post('google/link-account')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Link Google identity to an existing account using account credentials',
  })
  @ApiResponse({ status: 200, type: AuthResponseDto })
  @ApiResponse({
    status: 401,
    description: 'Invalid credentials or invalid Google token',
  })
  linkGoogleAccount(@Body() dto: GoogleLinkAccountDto): Promise<AuthResponseDto> {
    return this.authService.linkGoogleAccount(dto);
  }

  @Post('google/connect')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Connect Google identity to the currently authenticated account (from Settings)',
  })
  @ApiResponse({ status: 200, description: 'Google account linked successfully' })
  connectGoogle(
    @CurrentUser('sub') userId: string,
    @Body() dto: GoogleAuthDto,
  ) {
    return this.authService.connectGoogle(userId, dto);
  }

  @Post('google/disconnect')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Disconnect Google identity from current account (prevented if sole auth method)',
  })
  @ApiResponse({
    status: 200,
    description: 'Google account disconnected successfully',
  })
  disconnectGoogle(@CurrentUser('sub') userId: string) {
    return this.authService.disconnectGoogle(userId);
  }

  @Get('identities')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Get external identities (Google, etc.) and auth methods for current user',
  })
  @ApiResponse({ status: 200, type: UserIdentitiesDto })
  getIdentities(@CurrentUser('sub') userId: string): Promise<UserIdentitiesDto> {
    return this.authService.getUserIdentities(userId);
  }
}
