import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { AdminModule } from '../admin/admin.module.js';
import { SystemReportService } from './system-report.service.js';
import { AdminSystemReportController } from './admin-system-report.controller.js';
import { SystemReportController } from './system-report.controller.js';

@Module({
  imports: [
    PrismaModule,
    AdminModule,
    JwtModule.register({}),
  ],
  controllers: [
    AdminSystemReportController,
    SystemReportController,
  ],
  providers: [SystemReportService],
  exports: [SystemReportService],
})
export class SystemReportModule {}
