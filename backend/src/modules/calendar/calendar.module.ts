import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { CalendarService } from './calendar.service.js';
import { CalendarController } from './calendar.controller.js';
import { CalendarPublicationService } from './calendar-publication.service.js';
import { CalendarSchedulerService } from './calendar-scheduler.service.js';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { NotificationsModule } from '../notifications/notifications.module.js';

@Module({
  imports: [ConfigModule, PrismaModule, NotificationsModule],
  controllers: [CalendarController],
  providers: [
    CalendarService,
    CalendarPublicationService,
    CalendarSchedulerService,
  ],
  exports: [
    CalendarService,
    CalendarPublicationService,
    CalendarSchedulerService,
  ],
})
export class CalendarModule {}
