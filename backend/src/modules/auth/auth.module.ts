// src/modules/auth/auth.module.ts
import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { UsersModule } from '../users/users.module.js';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';
import { GoogleAuthService } from './google-auth.service.js';
import { JwtStrategy } from './strategies/jwt.strategy.js';
import { RefreshStrategy } from './strategies/refresh.strategy.js';
import { AuthPolicyModule } from '../auth-policy/auth-policy.module.js';
import { EmailDeliveryService } from './services/email-delivery.service.js';
import { SmsDeliveryService } from './services/sms-delivery.service.js';
import { PasswordRecoveryService } from './services/password-recovery.service.js';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        secret: configService.getOrThrow<string>('JWT_ACCESS_SECRET'),
        signOptions: {
          expiresIn: (configService.get<string>('JWT_ACCESS_EXPIRES') ??
            '15m') as any,
        },
      }),
      inject: [ConfigService],
    }),
    UsersModule,
    AuthPolicyModule,
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    GoogleAuthService,
    JwtStrategy,
    RefreshStrategy,
    EmailDeliveryService,
    SmsDeliveryService,
    PasswordRecoveryService,
  ],
  exports: [
    AuthService,
    GoogleAuthService,
    JwtModule,
    EmailDeliveryService,
    SmsDeliveryService,
    PasswordRecoveryService,
  ],
})
export class AuthModule {}
