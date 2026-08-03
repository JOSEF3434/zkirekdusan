import { Module } from '@nestjs/common';
import { AdminDashboardController } from './admin-dashboard.controller.js';
import { AdminModerationController } from './admin-moderation.controller.js';
import { AdminReportsController } from './admin-reports.controller.js';
import { AdminAnalyticsController } from './admin-analytics.controller.js';
import { AdminAuditController } from './admin-audit.controller.js';
import { AdminUsersController } from './admin-users.controller.js';
import { PrismaModule } from '../../prisma/prisma.module.js';

@Module({
  imports: [PrismaModule],
  controllers: [
    AdminDashboardController,
    AdminModerationController,
    AdminReportsController,
    AdminAnalyticsController,
    AdminAuditController,
    AdminUsersController,
  ],
})
export class AdminModule {}
