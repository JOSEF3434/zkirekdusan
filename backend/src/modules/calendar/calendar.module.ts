import { Module } from '@nestjs/common';
import { CalendarService } from './calendar.service.js';
import { CalendarController } from './calendar.controller.js';
import { PrismaModule } from '../../prisma/prisma.module.js';

@Module({
  imports: [PrismaModule],
  controllers: [CalendarController],
  providers: [CalendarService],
  exports: [CalendarService],
})
export class CalendarModule {}
