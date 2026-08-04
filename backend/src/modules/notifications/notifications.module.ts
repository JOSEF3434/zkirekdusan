// src/modules/notifications/notifications.module.ts
import { Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller.js';
import { NotificationsService } from './notifications.service.js';
import { NotificationsRepository } from './notifications.repository.js';
import { NotificationsGateway } from './notifications.gateway.js';
import { JwtModule } from '@nestjs/jwt';

@Module({
  imports: [JwtModule.register({})],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    NotificationsRepository,
    NotificationsGateway,
  ],
  exports: [NotificationsService],
})
export class NotificationsModule {}
