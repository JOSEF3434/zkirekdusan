// src/modules/auth/services/password-recovery.service.ts
import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import crypto from 'crypto';
import { PrismaService } from '../../../prisma/prisma.service.js';
import { UsersService } from '../../users/users.service.js';
import { PasswordService } from '../../../common/service/password.service.js';
import { AuthPolicyService } from '../../auth-policy/auth-policy.service.js';
import { EmailDeliveryService } from './email-delivery.service.js';
import { SmsDeliveryService } from './sms-delivery.service.js';
import {
  EthiopianPhoneDetails,
  normalizeEthiopianPhoneNumber,
  parseEthiopianPhoneNumber,
} from './phone-normalizer.js';
import {
  RecoveryMethodType,
  RecoveryRequestDto,
  RecoveryResendDto,
  RecoveryResetPasswordDto,
  RecoveryVerifyDto,
} from '../dto/recovery.dto.js';
import { RecoveryMethod, UserStatus } from '@prisma/client';

export interface RecoveryRequestResult {
  success: boolean;
  message: string;
  method: RecoveryMethodType;
  destinationMasked?: string;
  resendCooldownSeconds: number;
}

export interface RecoveryVerifyResult {
  valid: boolean;
  message: string;
  resetToken: string;
  method: RecoveryMethodType;
}

@Injectable()
export class PasswordRecoveryService {
  private readonly logger = new Logger(PasswordRecoveryService.name);
  private readonly hmacSecret: string;
  private readonly emailTokenTtlMinutes = 15;
  private readonly otpTtlMinutes = 5;
  private readonly maxAttempts = 5;
  private readonly resendCooldownSeconds = 60;
  private readonly hourlyRequestLimit = 5;

  constructor(
    private readonly prisma: PrismaService,
    private readonly usersService: UsersService,
    private readonly passwordService: PasswordService,
    private readonly emailDeliveryService: EmailDeliveryService,
    private readonly smsDeliveryService: SmsDeliveryService,
    private readonly configService: ConfigService,
    private readonly authPolicyService: AuthPolicyService,
  ) {
    this.hmacSecret =
      this.configService.get<string>('RECOVERY_HMAC_SECRET') ||
      this.configService.get<string>('JWT_ACCESS_SECRET') ||
      'zikre-kedusan-secure-recovery-pepper-key-2026';
  }

  /**
   * Request password recovery for Email or Ethiopian phone number.
   * Always returns generic response to prevent account enumeration.
   */
  async requestRecovery(
    dto: RecoveryRequestDto,
    reqIp?: string,
    userAgent?: string,
  ): Promise<RecoveryRequestResult> {
    const policy = await this.authPolicyService.getActivePolicy();
    if (policy && policy.allowPasswordReset === false) {
      throw new ForbiddenException(
        'Password reset and account recovery are currently disabled by administrator.',
      );
    }

    const { method, rawIdentifier } = this.resolveMethodAndIdentifier(dto);

    if (method === RecoveryMethodType.EMAIL) {
      return this.handleEmailRecoveryRequest(rawIdentifier, reqIp, userAgent);
    } else {
      return this.handlePhoneRecoveryRequest(rawIdentifier, reqIp, userAgent);
    }
  }

  /**
   * Verify an OTP or validate a token before allowing password reset.
   */
  async verifyChallenge(dto: RecoveryVerifyDto): Promise<RecoveryVerifyResult> {
    const policy = await this.authPolicyService.getActivePolicy();
    if (policy && policy.allowPasswordReset === false) {
      throw new ForbiddenException(
        'Password reset and account recovery are currently disabled by administrator.',
      );
    }

    if (dto.method === RecoveryMethodType.PHONE) {
      if (!dto.code) {
        throw new BadRequestException('Verification code is required for phone recovery.');
      }
      return this.verifyPhoneOtp(dto.destination, dto.code);
    } else {
      const token = dto.token || dto.code;
      if (!token) {
        throw new BadRequestException('Reset token is required for email recovery.');
      }
      return this.verifyEmailToken(token);
    }
  }

  /**
   * Validates an email reset token when user opens the link.
   */
  async validateEmailToken(token: string): Promise<{ valid: boolean; email?: string; message: string }> {
    const policy = await this.authPolicyService.getActivePolicy();
    if (policy && policy.allowPasswordReset === false) {
      return {
        valid: false,
        message: 'Password reset and account recovery are currently disabled by administrator.',
      };
    }

    if (!token) {
      throw new BadRequestException('Recovery token is required.');
    }

    const tokenHash = this.hashEmailToken(token);
    const challenge = await this.prisma.passwordRecoveryChallenge.findFirst({
      where: {
        tokenHash,
        method: RecoveryMethod.EMAIL,
        consumedAt: null,
      },
      include: { user: true },
    });

    if (!challenge) {
      return {
        valid: false,
        message: 'This recovery link is invalid or has already been used.',
      };
    }

    if (challenge.expiresAt < new Date()) {
      return {
        valid: false,
        message: 'This recovery link has expired. Please request a new recovery link.',
      };
    }

    return {
      valid: true,
      email: this.maskEmail(challenge.destination),
      message: 'Recovery link is valid.',
    };
  }

  /**
   * Resends recovery credentials respecting 60s cooldown and hourly limits.
   */
  async resendRecovery(
    dto: RecoveryResendDto,
    reqIp?: string,
    userAgent?: string,
  ): Promise<RecoveryRequestResult> {
    return this.requestRecovery(
      {
        method: dto.method,
        identifier: dto.identifier,
      },
      reqIp,
      userAgent,
    );
  }

  /**
   * Completes password reset and invalidates sessions/refresh tokens.
   */
  async resetPassword(
    dto: RecoveryResetPasswordDto,
    reqIp?: string,
  ): Promise<{ success: boolean; message: string }> {
    const policy = await this.authPolicyService.getActivePolicy();
    if (policy && policy.allowPasswordReset === false) {
      throw new ForbiddenException(
        'Password reset and account recovery are currently disabled by administrator.',
      );
    }

    const rawToken = dto.resetToken || dto.token;

    let challenge: (any & { user: any }) | null = null;

    if (rawToken) {
      // Check if rawToken is email token hash or a verified challenge ID / token
      const tokenHash = this.hashEmailToken(rawToken);
      challenge = await this.prisma.passwordRecoveryChallenge.findFirst({
        where: {
          OR: [{ tokenHash }, { id: rawToken }],
          consumedAt: null,
        },
        include: { user: true },
      });
    } else if (dto.method === RecoveryMethodType.PHONE && dto.destination && dto.code) {
      const normalizedPhone = normalizeEthiopianPhoneNumber(dto.destination);
      if (!normalizedPhone) {
        throw new BadRequestException('Invalid Ethiopian phone number.');
      }
      const otpHash = this.hashPhoneOtp(dto.code, normalizedPhone);
      challenge = await this.prisma.passwordRecoveryChallenge.findFirst({
        where: {
          destination: normalizedPhone,
          method: RecoveryMethod.PHONE,
          consumedAt: null,
        },
        orderBy: { createdAt: 'desc' },
        include: { user: true },
      });

      if (challenge) {
        // Constant-time compare
        const isMatch = this.constantTimeCompare(challenge.tokenHash, otpHash);
        if (!isMatch) {
          challenge = null;
        }
      }
    }

    if (!challenge) {
      throw new BadRequestException(
        'Invalid or expired recovery credentials. Please start a new recovery request.',
      );
    }

    if (challenge.consumedAt) {
      throw new BadRequestException(
        'This recovery code or link has already been used. Please request a new one.',
      );
    }

    if (challenge.expiresAt < new Date()) {
      throw new BadRequestException(
        'This recovery request has expired. Please request a new one.',
      );
    }

    if (challenge.failedAttempts >= challenge.maxAttempts) {
      throw new BadRequestException(
        'Too many failed attempts. This recovery challenge is locked. Please request a new one.',
      );
    }

    const userId = challenge.userId;
    const newPasswordHash = await this.passwordService.hash(dto.password);

    // Atomically execute password update, challenge consumption, and session invalidation
    await this.prisma.$transaction(async (tx) => {
      // 1. Mark current challenge consumed
      await tx.passwordRecoveryChallenge.update({
        where: { id: challenge.id },
        data: {
          consumedAt: new Date(),
        },
      });

      // 2. Invalidate all other active recovery challenges for this user
      await tx.passwordRecoveryChallenge.updateMany({
        where: {
          userId,
          consumedAt: null,
        },
        data: {
          consumedAt: new Date(),
        },
      });

      // 3. Update user password and reset failed login attempts
      await tx.user.update({
        where: { id: userId },
        data: {
          passwordHash: newPasswordHash,
          failedLoginAttempts: 0,
          lockedUntil: null,
        },
      });
    });

    // 4. Securely revoke all active refresh tokens & sessions
    await this.usersService.revokeRefreshTokens(userId);
    await this.usersService.revokeSessions(userId);

    this.logger.log(
      `Password successfully reset for user ${userId.substring(0, 8)}... via ${challenge.method}. Sessions revoked.`,
    );

    // 5. Send notification email if user has email
    if (challenge.user?.email) {
      this.emailDeliveryService
        .sendPasswordChangedNotificationEmail(
          challenge.user.email,
          (challenge.user as any).profile?.firstName || challenge.user.username || undefined,
        )
        .catch((err) =>
          this.logger.error(
            `Failed to send password-changed email notification: ${err.message}`,
          ),
        );
    }

    return {
      success: true,
      message:
        'Your password has been successfully reset. Please sign in with your new password.',
    };
  }

  // ── PRIVATE HELPERS ────────────────────────────────────────────────────────

  private async handleEmailRecoveryRequest(
    rawEmail: string,
    reqIp?: string,
    userAgent?: string,
  ): Promise<RecoveryRequestResult> {
    const normalizedEmail = rawEmail.toLowerCase().trim();
    const masked = this.maskEmail(normalizedEmail);

    const genericResponse: RecoveryRequestResult = {
      success: true,
      message:
        'If an account associated with this email exists, recovery instructions have been sent.',
      method: RecoveryMethodType.EMAIL,
      destinationMasked: masked,
      resendCooldownSeconds: this.resendCooldownSeconds,
    };

    // Check hourly destination rate limit
    await this.checkRateLimit(normalizedEmail, RecoveryMethod.EMAIL);

    const user = await this.usersService.findByEmail(normalizedEmail);

    if (!user || user.status === UserStatus.BANNED || user.status === UserStatus.SUSPENDED) {
      // Simulate delay to prevent timing analysis
      await this.constantDelay();
      return genericResponse;
    }

    // Check cooldown from latest challenge
    const latestChallenge = await this.prisma.passwordRecoveryChallenge.findFirst({
      where: {
        destination: normalizedEmail,
        method: RecoveryMethod.EMAIL,
        consumedAt: null,
      },
      orderBy: { createdAt: 'desc' },
    });

    if (
      latestChallenge?.resendAvailableAt &&
      latestChallenge.resendAvailableAt > new Date()
    ) {
      const waitSeconds = Math.ceil(
        (latestChallenge.resendAvailableAt.getTime() - Date.now()) / 1000,
      );
      throw new BadRequestException(
        `Please wait ${waitSeconds} seconds before requesting another recovery email.`,
      );
    }

    // Generate cryptographically secure random token (256 bits)
    const rawToken = crypto.randomBytes(32).toString('hex');
    const tokenHash = this.hashEmailToken(rawToken);

    const expiresAt = new Date(Date.now() + this.emailTokenTtlMinutes * 60 * 1000);
    const resendAvailableAt = new Date(Date.now() + this.resendCooldownSeconds * 1000);

    // Invalidate earlier unconsumed challenges
    await this.prisma.passwordRecoveryChallenge.updateMany({
      where: {
        userId: user.id,
        method: RecoveryMethod.EMAIL,
        consumedAt: null,
      },
      data: {
        consumedAt: new Date(),
      },
    });

    // Create new challenge
    await this.prisma.passwordRecoveryChallenge.create({
      data: {
        userId: user.id,
        method: RecoveryMethod.EMAIL,
        tokenHash,
        destination: normalizedEmail,
        expiresAt,
        resendAvailableAt,
        requestIp: reqIp,
        userAgent: userAgent ? userAgent.substring(0, 255) : null,
      },
    });

    // Asynchronously dispatch email
    this.emailDeliveryService
      .sendPasswordResetEmail(
        normalizedEmail,
        rawToken,
        user.profile?.firstName || user.username || undefined,
      )
      .catch((err) => {
        this.logger.error(`Error sending password reset email: ${err.message}`);
      });

    return genericResponse;
  }

  private async handlePhoneRecoveryRequest(
    rawPhone: string,
    reqIp?: string,
    userAgent?: string,
  ): Promise<RecoveryRequestResult> {
    const phoneDetails: EthiopianPhoneDetails = parseEthiopianPhoneNumber(rawPhone);

    const genericResponse: RecoveryRequestResult = {
      success: true,
      message:
        'If an account associated with this phone number exists, an SMS recovery code has been sent.',
      method: RecoveryMethodType.PHONE,
      destinationMasked: phoneDetails.e164
        ? this.maskPhone(phoneDetails.e164)
        : undefined,
      resendCooldownSeconds: this.resendCooldownSeconds,
    };

    if (!phoneDetails.isValid || !phoneDetails.e164) {
      // Return clear error if phone format is completely invalid Ethiopian number
      throw new BadRequestException(
        'Please provide a valid Ethiopian mobile phone number (+2519... or +2517...).',
      );
    }

    const normalizedPhone = phoneDetails.e164;
    const nationalPhone = phoneDetails.national!;

    // Check hourly destination rate limit
    await this.checkRateLimit(normalizedPhone, RecoveryMethod.PHONE);

    // Look up user by both E.164 and national formats to support legacy records
    let user = await this.usersService.findByPhoneNumber(normalizedPhone);
    if (!user) {
      user = await this.usersService.findByPhoneNumber(nationalPhone);
    }

    if (!user || user.status === UserStatus.BANNED || user.status === UserStatus.SUSPENDED) {
      await this.constantDelay();
      return genericResponse;
    }

    // Check cooldown
    const latestChallenge = await this.prisma.passwordRecoveryChallenge.findFirst({
      where: {
        destination: normalizedPhone,
        method: RecoveryMethod.PHONE,
        consumedAt: null,
      },
      orderBy: { createdAt: 'desc' },
    });

    if (
      latestChallenge?.resendAvailableAt &&
      latestChallenge.resendAvailableAt > new Date()
    ) {
      const waitSeconds = Math.ceil(
        (latestChallenge.resendAvailableAt.getTime() - Date.now()) / 1000,
      );
      throw new BadRequestException(
        `Please wait ${waitSeconds} seconds before requesting a new SMS verification code.`,
      );
    }

    // Generate 6-digit OTP
    const rawOtp = crypto.randomInt(100000, 1000000).toString();
    const tokenHash = this.hashPhoneOtp(rawOtp, normalizedPhone);

    const expiresAt = new Date(Date.now() + this.otpTtlMinutes * 60 * 1000);
    const resendAvailableAt = new Date(Date.now() + this.resendCooldownSeconds * 1000);

    // Invalidate earlier unconsumed challenges
    await this.prisma.passwordRecoveryChallenge.updateMany({
      where: {
        userId: user.id,
        method: RecoveryMethod.PHONE,
        consumedAt: null,
      },
      data: {
        consumedAt: new Date(),
      },
    });

    // Create challenge
    await this.prisma.passwordRecoveryChallenge.create({
      data: {
        userId: user.id,
        method: RecoveryMethod.PHONE,
        tokenHash,
        destination: normalizedPhone,
        expiresAt,
        resendAvailableAt,
        requestIp: reqIp,
        userAgent: userAgent ? userAgent.substring(0, 255) : null,
      },
    });

    // Dispatch SMS via provider abstraction
    this.smsDeliveryService
      .sendRecoveryOtp(normalizedPhone, rawOtp)
      .then((res) => {
        if (!res.success) {
          this.logger.warn(`SMS dispatch warning: ${res.error}`);
        }
      })
      .catch((err) => {
        this.logger.error(`SMS dispatch threw unexpectedly: ${err.message}`);
      });

    return genericResponse;
  }

  private async verifyPhoneOtp(
    rawPhone: string,
    code: string,
  ): Promise<RecoveryVerifyResult> {
    const normalizedPhone = normalizeEthiopianPhoneNumber(rawPhone);
    if (!normalizedPhone) {
      throw new BadRequestException('Invalid Ethiopian phone number format.');
    }

    const challenge = await this.prisma.passwordRecoveryChallenge.findFirst({
      where: {
        destination: normalizedPhone,
        method: RecoveryMethod.PHONE,
        consumedAt: null,
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!challenge) {
      throw new BadRequestException(
        'No active recovery request found for this phone number. Please request a new code.',
      );
    }

    if (challenge.expiresAt < new Date()) {
      throw new BadRequestException(
        'Recovery code has expired. Please request a new code.',
      );
    }

    if (challenge.failedAttempts >= challenge.maxAttempts) {
      throw new BadRequestException(
        'Too many invalid attempts. For your security, this code has been deactivated. Please request a new one.',
      );
    }

    const expectedHash = this.hashPhoneOtp(code.trim(), normalizedPhone);
    const isMatch = this.constantTimeCompare(challenge.tokenHash, expectedHash);

    if (!isMatch) {
      const attempts = challenge.failedAttempts + 1;
      await this.prisma.passwordRecoveryChallenge.update({
        where: { id: challenge.id },
        data: { failedAttempts: attempts },
      });

      const remaining = challenge.maxAttempts - attempts;
      if (remaining <= 0) {
        throw new BadRequestException(
          'Too many invalid attempts. This code is now deactivated. Please request a new code.',
        );
      }
      throw new BadRequestException(
        `Invalid recovery code. ${remaining} attempt(s) remaining.`,
      );
    }

    return {
      valid: true,
      message: 'Code verified successfully.',
      resetToken: challenge.id,
      method: RecoveryMethodType.PHONE,
    };
  }

  private async verifyEmailToken(token: string): Promise<RecoveryVerifyResult> {
    const tokenHash = this.hashEmailToken(token);
    const challenge = await this.prisma.passwordRecoveryChallenge.findFirst({
      where: {
        tokenHash,
        method: RecoveryMethod.EMAIL,
        consumedAt: null,
      },
    });

    if (!challenge) {
      throw new BadRequestException(
        'Invalid or already used recovery link. Please request a new recovery email.',
      );
    }

    if (challenge.expiresAt < new Date()) {
      throw new BadRequestException(
        'Recovery link has expired. Please request a new recovery email.',
      );
    }

    return {
      valid: true,
      message: 'Recovery link verified successfully.',
      resetToken: challenge.id,
      method: RecoveryMethodType.EMAIL,
    };
  }

  private resolveMethodAndIdentifier(dto: RecoveryRequestDto): {
    method: RecoveryMethodType;
    rawIdentifier: string;
  } {
    const raw = (dto.identifier || dto.email || dto.phoneNumber || '').trim();
    if (!raw) {
      throw new BadRequestException('Please provide an email or phone number.');
    }

    if (dto.method) {
      return { method: dto.method, rawIdentifier: raw };
    }

    // Auto-detect: if contains @ -> EMAIL, otherwise if digits/+ -> PHONE
    if (raw.includes('@')) {
      return { method: RecoveryMethodType.EMAIL, rawIdentifier: raw };
    }

    return { method: RecoveryMethodType.PHONE, rawIdentifier: raw };
  }

  private async checkRateLimit(destination: string, method: RecoveryMethod): Promise<void> {
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const count = await this.prisma.passwordRecoveryChallenge.count({
      where: {
        destination,
        method,
        createdAt: { gte: oneHourAgo },
      },
    });

    if (count >= this.hourlyRequestLimit) {
      throw new BadRequestException(
        'Too many recovery requests. Please try again in an hour.',
      );
    }
  }

  private hashEmailToken(token: string): string {
    return crypto.createHash('sha256').update(token.trim()).digest('hex');
  }

  private hashPhoneOtp(otp: string, phone: string): string {
    return crypto
      .createHmac('sha256', this.hmacSecret)
      .update(`${otp.trim()}:${phone}`)
      .digest('hex');
  }

  private constantTimeCompare(a: string, b: string): boolean {
    try {
      const bufA = Buffer.from(a, 'hex');
      const bufB = Buffer.from(b, 'hex');
      if (bufA.length !== bufB.length) return false;
      return crypto.timingSafeEqual(bufA, bufB);
    } catch {
      return false;
    }
  }

  private maskEmail(email: string): string {
    const [user, domain] = email.split('@');
    if (!domain) return email;
    const maskedUser =
      user.length <= 2 ? user[0] + '***' : user[0] + '***' + user[user.length - 1];
    return `${maskedUser}@${domain}`;
  }

  private maskPhone(phone: string): string {
    if (phone.length < 8) return phone;
    return `${phone.substring(0, 6)}****${phone.substring(phone.length - 2)}`;
  }

  private async constantDelay(): Promise<void> {
    const ms = 200 + Math.floor(Math.random() * 100);
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}
