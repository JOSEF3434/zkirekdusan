// src/modules/auth/google-auth.service.ts
import {
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client, TokenPayload } from 'google-auth-library';

export interface VerifiedGoogleUser {
  sub: string;
  email: string;
  emailVerified: boolean;
  name?: string;
  givenName?: string;
  familyName?: string;
  picture?: string;
}

@Injectable()
export class GoogleAuthService {
  private readonly logger = new Logger(GoogleAuthService.name);
  private readonly client: OAuth2Client;

  constructor(private readonly configService: ConfigService) {
    this.client = new OAuth2Client();
  }

  /**
   * Retrieves all trusted Google OAuth Client IDs (Android, iOS, Web).
   */
  getAllowedAudiences(): string[] {
    const webClientId = this.configService.get<string>('GOOGLE_CLIENT_ID_WEB');
    const androidClientId = this.configService.get<string>(
      'GOOGLE_CLIENT_ID_ANDROID',
    );
    const iosClientId = this.configService.get<string>('GOOGLE_CLIENT_ID_IOS');
    const additionalIds = this.configService.get<string>(
      'GOOGLE_ALLOWED_CLIENT_IDS',
    );

    const audiences = new Set<string>();

    if (webClientId?.trim()) audiences.add(webClientId.trim());
    if (androidClientId?.trim()) audiences.add(androidClientId.trim());
    if (iosClientId?.trim()) audiences.add(iosClientId.trim());

    if (additionalIds?.trim()) {
      additionalIds
        .split(',')
        .map((s) => s.trim())
        .filter((s) => s.length > 0)
        .forEach((id) => audiences.add(id));
    }

    return Array.from(audiences);
  }

  /**
   * Cryptographically verifies a Google ID token and returns trusted profile claims.
   *
   * Validates:
   *  - Token format & signature against Google's public certificates
   *  - Expiration time
   *  - Issuer (`accounts.google.com` or `https://accounts.google.com`)
   *  - Audience matching explicit allowlist of registered client IDs
   *  - Verified email status (`email_verified === true`)
   *  - Presence of stable `sub` and `email`
   */
  async verifyIdToken(idToken: string): Promise<VerifiedGoogleUser> {
    if (!idToken || typeof idToken !== 'string' || idToken.trim() === '') {
      throw new UnauthorizedException('Google ID token is required');
    }

    const allowedAudiences = this.getAllowedAudiences();

    let payload: TokenPayload | undefined;

    try {
      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: allowedAudiences.length > 0 ? allowedAudiences : undefined,
      });

      payload = ticket.getPayload();
    } catch (err: any) {
      this.logger.warn(
        `Google token verification failed: ${err?.message || 'Invalid token'}`,
      );
      throw new UnauthorizedException('Invalid or expired Google token');
    }

    if (!payload) {
      throw new UnauthorizedException('Invalid Google token payload');
    }

    // ── Claim validation ──────────────────────────────────────────

    // 1. Verify Issuer
    const validIssuers = ['accounts.google.com', 'https://accounts.google.com'];
    if (!payload.iss || !validIssuers.includes(payload.iss)) {
      this.logger.warn(`Invalid Google token issuer: ${payload.iss}`);
      throw new UnauthorizedException('Invalid Google token issuer');
    }

    // 2. Verify Expiration
    const nowInSeconds = Math.floor(Date.now() / 1000);
    if (!payload.exp || payload.exp < nowInSeconds) {
      this.logger.warn('Google token is expired');
      throw new UnauthorizedException('Google token has expired');
    }

    // 3. Verify Audience against explicit allowlist (defense-in-depth)
    if (allowedAudiences.length > 0) {
      const tokenAud = payload.aud;
      const isAllowed = allowedAudiences.includes(tokenAud);
      if (!isAllowed) {
        this.logger.warn(
          `Google token audience mismatch. Rejected client ID: ${tokenAud}`,
        );
        throw new UnauthorizedException('Unauthorized Google client application');
      }
    }

    // 4. Verify Email & Email Verification status
    if (!payload.email) {
      throw new UnauthorizedException('Google account does not provide an email');
    }

    const isEmailVerified =
      payload.email_verified === true ||
      (payload.email_verified as unknown) === 'true';

    if (!isEmailVerified) {
      this.logger.warn(
        `Google account email is not verified: ${payload.email}`,
      );
      throw new UnauthorizedException(
        'Google account email is not verified. Please verify your email with Google.',
      );
    }

    // 5. Verify Stable Subject Identifier
    if (!payload.sub || payload.sub.trim() === '') {
      throw new UnauthorizedException(
        'Google token does not contain a valid subject identifier',
      );
    }

    return {
      sub: payload.sub,
      email: payload.email.toLowerCase().trim(),
      emailVerified: true,
      name: payload.name,
      givenName: payload.given_name,
      familyName: payload.family_name,
      picture: payload.picture,
    };
  }
}
