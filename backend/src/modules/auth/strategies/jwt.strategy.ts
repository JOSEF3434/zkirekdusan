// src/modules/auth/strategies/jwt.strategy.ts
import {
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ConfigService } from '@nestjs/config';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PrismaService } from '../../../prisma/prisma.service.js';
import { JwtPayload } from '../../../common/interfaces/jwt-payload.interface.js';

/**
 * JWT Access Token strategy.
 *
 * FIXES applied:
 * 1. validate() throws UnauthorizedException instead of returning null
 *    → prevents PrismaClientValidationError when user is missing
 * 2. Validates payload.sub is present before DB query
 * 3. Checks user.status === ACTIVE — suspended/banned users get 401
 * 4. Secret reads from JWT_ACCESS_SECRET (matches .env)
 */
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey:
        configService.getOrThrow<string>('JWT_ACCESS_SECRET'),
    });
  }

  async validate(payload: JwtPayload): Promise<JwtPayload> {
    // Guard against malformed payload (sub must be a non-empty string)
    if (!payload?.sub || typeof payload.sub !== 'string') {
      throw new UnauthorizedException('Invalid token payload');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        status: true,
        role: { select: { name: true } },
      },
    });

    if (!user) {
      throw new UnauthorizedException('User account not found');
    }

    if (user.status !== 'ACTIVE') {
      throw new UnauthorizedException(
        `Account is ${user.status.toLowerCase()}. Contact support.`,
      );
    }

    // Return the payload shape — this becomes request.user
    // We re-embed the role name in case it changed since last token issuance
    return {
      sub: user.id,
      email: payload.email,
      role: user.role.name,
    };
  }
}
