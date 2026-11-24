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
   * Cryptographically verifies a Google ID token or OAuth access token and returns trusted profile claims.
   * Supports:
   *  - Standard OpenID Connect ID tokens (JWT, 3-part) from Android, iOS, and GIS.
   *  - OAuth2 Access tokens (e.g. ya29...) from Flutter Web signIn() flows.
   */
  async verifyIdToken(token: string): Promise<VerifiedGoogleUser> {
    if (!token || typeof token !== 'string' || token.trim() === '') {
      throw new UnauthorizedException('Google ID token is required');
    }

    const trimmed = token.trim();

    const allowedAudiences = this.getAllowedAudiences();
    let payload: TokenPayload | undefined;

    try {
      const ticket = await this.client.verifyIdToken({
        idToken: trimmed,
        audience: allowedAudiences.length > 0 ? allowedAudiences : undefined,
      });

      payload = ticket.getPayload();
    } catch (err: any) {
      // If verifying as an ID token fails, check if token is an OAuth2 Access Token (e.g. from Flutter Web)
      try {
        return await this.verifyAccessToken(trimmed);
      } catch {
        this.logger.warn(
          `Google token verification failed: ${err?.message || 'Invalid token'}`,
        );
        throw new UnauthorizedException('Invalid or expired Google token');
      }
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

  /**
   * Cryptographically verifies an OAuth2 access token via Google TokenInfo and OIDC userinfo.
   */
  async verifyAccessToken(accessToken: string): Promise<VerifiedGoogleUser> {
    const allowedAudiences = this.getAllowedAudiences();
    let tokenInfo: any;

    try {
      tokenInfo = await this.client.getTokenInfo(accessToken);
    } catch (err: any) {
      this.logger.warn(
        `Google access token verification failed: ${err?.message || 'Invalid token'}`,
      );
      throw new UnauthorizedException('Invalid or expired Google access token');
    }

    if (!tokenInfo) {
      throw new UnauthorizedException('Invalid Google token info');
    }

    // 1. Verify Expiration
    const nowInSeconds = Math.floor(Date.now() / 1000);
    const expSeconds =
      tokenInfo.expiry_date > 10000000000
        ? Math.floor(tokenInfo.expiry_date / 1000)
        : tokenInfo.expiry_date;
    if (expSeconds && expSeconds < nowInSeconds) {
      this.logger.warn('Google access token is expired');
      throw new UnauthorizedException('Google access token has expired');
    }

    // 2. Verify Audience
    if (allowedAudiences.length > 0) {
      const tokenAud = tokenInfo.aud;
      const isAllowed = allowedAudiences.includes(tokenAud);
      if (!isAllowed) {
        this.logger.warn(
          `Google token audience mismatch. Rejected client ID: ${tokenAud}`,
        );
        throw new UnauthorizedException('Unauthorized Google client application');
      }
    }

    // 3. Verify Email & Email Verification status
    if (!tokenInfo.email) {
      throw new UnauthorizedException('Google account does not provide an email');
    }

    const isEmailVerified =
      tokenInfo.email_verified === true ||
      (tokenInfo.email_verified as unknown) === 'true';

    if (!isEmailVerified) {
      throw new UnauthorizedException('Google account email is not verified');
    }

    const sub = tokenInfo.sub || tokenInfo.user_id;
    if (!sub || sub.trim() === '') {
      throw new UnauthorizedException(
        'Google token does not contain a valid subject identifier',
      );
    }

    // 4. Fetch user profile from Google OIDC userinfo endpoint
    let name: string | undefined;
    let givenName: string | undefined;
    let familyName: string | undefined;
    let picture: string | undefined;

    try {
      const res = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      if (res.ok) {
        const userInfo: any = await res.json();
        name = userInfo.name;
        givenName = userInfo.given_name;
        familyName = userInfo.family_name;
        picture = userInfo.picture;
      }
    } catch (err) {
      this.logger.debug(`Could not fetch userinfo from Google: ${err}`);
    }

    return {
      sub,
      email: tokenInfo.email.toLowerCase().trim(),
      emailVerified: true,
      name,
      givenName,
      familyName,
      picture,
    };
  }
}
