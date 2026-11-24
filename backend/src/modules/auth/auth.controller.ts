// src/modules/auth/auth.controller.ts
import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Query,
  Req,
} from '@nestjs/common';
import type { Request } from 'express';
import { SkipThrottle, Throttle } from '@nestjs/throttler';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { AuthService } from './auth.service.js';
import { PasswordRecoveryService } from './services/password-recovery.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshTokenDto } from './dto/refresh-token.dto.js';
import { AuthResponseDto } from './dto/auth-response.dto.js';
import { ForgotPasswordDto } from './dto/forgot-password.dto.js';
import { ResetPasswordDto } from './dto/reset-password.dto.js';
import {
  RecoveryRequestDto,
  RecoveryVerifyDto,
  RecoveryResendDto,
} from './dto/recovery.dto.js';
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
  constructor(
    private readonly authService: AuthService,
    private readonly passwordRecoveryService: PasswordRecoveryService,
  ) {}

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

  // ── Password Recovery Endpoints ────────────────────────────────────

  @Public()
  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Request password recovery via email or Ethiopian phone number',
  })
  @ApiResponse({
    status: 200,
    description: 'Generic recovery message indicating code or link was sent if account exists',
  })
  forgotPassword(
    @Body() dto: ForgotPasswordDto,
    @Req() req: Request,
  ) {
    const ip = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.ip;
    const ua = req.headers['user-agent'];
    return this.passwordRecoveryService.requestRecovery(dto, ip, ua);
  }

  @Public()
  @Post('recovery/request')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Request password recovery (alias for forgot-password)',
  })
  recoveryRequest(
    @Body() dto: RecoveryRequestDto,
    @Req() req: Request,
  ) {
    const ip = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.ip;
    const ua = req.headers['user-agent'];
    return this.passwordRecoveryService.requestRecovery(dto, ip, ua);
  }

  @Public()
  @Post('recovery/verify')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Verify phone OTP code or validate email recovery token',
  })
  @ApiResponse({ status: 200, description: 'Code or token is valid' })
  @ApiResponse({ status: 400, description: 'Code is invalid, expired, or deactivated' })
  verifyRecoveryCode(@Body() dto: RecoveryVerifyDto) {
    return this.passwordRecoveryService.verifyChallenge(dto);
  }

  @Public()
  @Get('recovery/validate-token')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Validate email reset token status before displaying reset password form',
  })
  validateRecoveryToken(@Query('token') token: string) {
    return this.passwordRecoveryService.validateEmailToken(token);
  }

  @Public()
  @Post('recovery/resend')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Resend recovery OTP or email link (enforces 60s cooldown and hourly limit)',
  })
  resendRecovery(
    @Body() dto: RecoveryResendDto,
    @Req() req: Request,
  ) {
    const ip = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.ip;
    const ua = req.headers['user-agent'];
    return this.passwordRecoveryService.resendRecovery(dto, ip, ua);
  }

  @Public()
  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Complete password reset using verified token or phone OTP',
  })
  @ApiResponse({ status: 200, description: 'Password reset successful' })
  @ApiResponse({ status: 400, description: 'Invalid or expired credentials' })
  resetPassword(
    @Body() dto: ResetPasswordDto,
    @Req() req: Request,
  ) {
    const ip = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.ip;
    return this.passwordRecoveryService.resetPassword(dto, ip);
  }
}
