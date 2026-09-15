import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module.js';

// Controllers
import { AdminDashboardController } from './admin-dashboard.controller.js';
import { AdminUsersController } from './admin-users.controller.js';
import { AdminReportsController } from './admin-reports.controller.js';
import { AdminModerationController } from './admin-moderation.controller.js';
import { AdminAnalyticsController } from './admin-analytics.controller.js';
import { AdminAuditController } from './admin-audit.controller.js';
import { AdminGroupsController } from './admin-groups.controller.js';
import { AdminChannelsController } from './admin-channels.controller.js';
import { AdminContentController } from './admin-content.controller.js';
import { AdminLiveController } from './admin-live.controller.js';
import { AdminChatController } from './admin-chat.controller.js';
import { AdminNotificationsController } from './admin-notifications.controller.js';
import { AdminStorageController } from './admin-storage.controller.js';
import { AdminRbacController } from './admin-rbac.controller.js';

// Services
import { AdminAuditService } from './services/admin-audit.service.js';
import { AdminDashboardService } from './services/admin-dashboard.service.js';
import { AdminUsersService } from './services/admin-users.service.js';
import { AdminGroupsService } from './services/admin-groups.service.js';
import { AdminContentService } from './services/admin-content.service.js';
import { AdminModerationService } from './services/admin-moderation.service.js';
import { AdminLiveService } from './services/admin-live.service.js';
import { AdminChatService } from './services/admin-chat.service.js';
import { AdminNotificationsService } from './services/admin-notifications.service.js';
import { AdminStorageService } from './services/admin-storage.service.js';
import { AdminRbacService } from './services/admin-rbac.service.js';

@Module({
  imports: [PrismaModule],
  controllers: [
    AdminDashboardController,
    AdminUsersController,
    AdminReportsController,
    AdminModerationController,
    AdminAnalyticsController,
    AdminAuditController,
    AdminGroupsController,
    AdminChannelsController,
    AdminContentController,
    AdminLiveController,
    AdminChatController,
    AdminNotificationsController,
    AdminStorageController,
    AdminRbacController,
  ],
  providers: [
    AdminAuditService,
    AdminDashboardService,
    AdminUsersService,
    AdminGroupsService,
    AdminContentService,
    AdminModerationService,
    AdminLiveService,
    AdminChatService,
    AdminNotificationsService,
    AdminStorageService,
    AdminRbacService,
  ],
  exports: [
    AdminAuditService,
    AdminDashboardService,
    AdminUsersService,
    AdminGroupsService,
    AdminContentService,
    AdminModerationService,
    AdminLiveService,
    AdminChatService,
    AdminNotificationsService,
    AdminStorageService,
    AdminRbacService,
  ],
})
export class AdminModule {}
