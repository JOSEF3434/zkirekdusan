import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { CalendarService } from './calendar.service.js';
import { CalendarController } from './calendar.controller.js';
import { CalendarPublicationService } from './calendar-publication.service.js';
import { CalendarSchedulerService } from './calendar-scheduler.service.js';
import { CalendarEventsService } from './calendar-events.service.js';
import { CalendarEventsController } from './calendar-events.controller.js';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { NotificationsModule } from '../notifications/notifications.module.js';

@Module({
  imports: [ConfigModule, PrismaModule, NotificationsModule],
  controllers: [CalendarController, CalendarEventsController],
  providers: [
    CalendarService,
    CalendarPublicationService,
    CalendarSchedulerService,
    CalendarEventsService,
  ],
  exports: [
    CalendarService,
    CalendarPublicationService,
    CalendarSchedulerService,
    CalendarEventsService,
  ],
})
export class CalendarModule {}
