import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { Module } from '@nestjs/common';
import { StringValue } from 'ms';
import { CommonModule } from '@/common/common.module.js';
import { UsersModule } from '../users/users.module.js';
import { PrismaModule } from 'prisma/prisma.module.js';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';
import { RolesModule } from '../roles/roles.module.js';
import { JwtStrategy } from './strategies/jwt.strategy.js';
import { RefreshStrategy } from './strategies/refresh.strategy.js';

@Module({
  imports: [
    JwtModule.registerAsync(...),
    UsersModule,
    RolesModule,
    PrismaModule,
    CommonModule,
  ],
  controllers: [AuthController],
  providers: [AuthService,

    JwtStrategy,

    RefreshStrategy ,],
})
export class AuthModule {}
