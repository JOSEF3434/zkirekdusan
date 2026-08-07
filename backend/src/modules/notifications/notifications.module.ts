// src/modules/notifications/notifications.module.ts
import { Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller.js';
import { NotificationsService } from './notifications.service.js';
import { NotificationsRepository } from './notifications.repository.js';
import { NotificationsGateway } from './notifications.gateway.js';
import { FirebaseService } from './firebase.service.js';
import { DeviceTokensController } from './device-tokens.controller.js';
import { JwtModule } from '@nestjs/jwt';
import { PrismaModule } from '../../prisma/prisma.module.js';

@Module({
  imports: [JwtModule.register({}), PrismaModule],
  controllers: [NotificationsController, DeviceTokensController],
  providers: [
    NotificationsService,
    NotificationsRepository,
    NotificationsGateway,
    FirebaseService,
  ],
  exports: [NotificationsService, FirebaseService],
})
export class NotificationsModule {}
