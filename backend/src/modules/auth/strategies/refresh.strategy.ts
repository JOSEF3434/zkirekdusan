import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ConfigService } from '@nestjs/config';
import { ExtractJwt, Strategy } from 'passport-jwt'; // Extend the base passport Strategy

interface JwtRefreshPayload {
  sub: string;
  email?: string;
  iat?: number;
  exp?: number;
  [key: string]: unknown;
}

@Injectable()
export class RefreshStrategy extends PassportStrategy(Strategy, 'jwt-refresh') {
  constructor(configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromBodyField('refreshToken'),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_REFRESH_SECRET') || '',
    });
  }

  validate(payload: JwtRefreshPayload): JwtRefreshPayload {
    return payload;
  }
}
