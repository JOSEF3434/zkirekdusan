import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { PrismaModule } from '../prisma/prisma.module.js';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { AuthModule } from './modules/auth/auth.module.js';
import { UsersModule } from './modules/users/users.module';
import { RolesService } from './modules/roles/roles.service';
import { RolesModule } from './modules/roles/roles.module';
import { RefreshTokenService } from './modules/refresh-token/refresh-token.service';
import { SessionsService } from './modules/sessions/sessions.service';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
      expandVariables: true,
    }),
    PrismaModule,
    AuthModule,
    UsersModule,
    RolesModule, // This is a Module, so it stays here.
  ],
  controllers: [AppController], // Controllers go here.
  providers: [AppService, RolesService, RefreshTokenService, SessionsService], // Services/Providers go here.
})
export class AppModule {}
