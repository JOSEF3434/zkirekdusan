// src/modules/auth/strategies/refresh.strategy.ts
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ConfigService } from '@nestjs/config';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { Request } from 'express';
import { RefreshTokenPayload } from '../../../common/interfaces/jwt-payload.interface.js';

interface RequestWithRefreshBody extends Request {
  body: { refreshToken?: string };
}

@Injectable()
export class RefreshStrategy extends PassportStrategy(Strategy, 'jwt-refresh') {
  constructor(configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromBodyField('refreshToken'),
      ignoreExpiration: false,
      secretOrKey: configService.getOrThrow<string>('JWT_REFRESH_SECRET'),
      passReqToCallback: true,
    });
  }

  validate(
    req: RequestWithRefreshBody,
    payload: RefreshTokenPayload,
  ): { sub: string; refreshToken: string } {
    if (!payload?.sub) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const refreshToken = req.body?.refreshToken;
    if (!refreshToken) {
      throw new UnauthorizedException('Refresh token is required');
    }

    return {
      sub: payload.sub,
      refreshToken,
    };
  }
}
