// backend/src/modules/auth/auth.module.ts
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { Module, forwardRef } from '@nestjs/common';
import { StringValue } from 'ms';
import { PassportModule } from '@nestjs/passport';
import { CommonModule } from '../../common/common.module.js';
import { UsersModule } from '../users/users.module.js';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';
import { RolesModule } from '../roles/roles.module.js';
import { JwtStrategy } from './strategies/jwt.strategy.js';
import { RefreshStrategy } from './strategies/refresh.strategy.js';
import { PrismaModule } from '../../prisma/prisma.module.js';

@Module({
  imports: [
    PassportModule.register({
      defaultStrategy: 'jwt',
    }),

    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => {
        console.log(
          'JWT_ACCESS_SECRET:',
          configService.get('JWT_ACCESS_SECRET'),
        );

        console.log(
          'JWT_ACCESS_EXPIRES:',
          configService.get('JWT_ACCESS_EXPIRES'),
        );

        return {
          secret: configService.get<string>('JWT_SECRET'),

          signOptions: {
            expiresIn: configService.get<string>(
              'JWT_EXPIRES_IN',
            ) as StringValue,
          },
        };
      },
      inject: [ConfigService],
    }),
    forwardRef(() => UsersModule),
    RolesModule,
    PrismaModule,
    CommonModule,
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, RefreshStrategy],
  exports: [AuthService],
})
export class AuthModule {}
