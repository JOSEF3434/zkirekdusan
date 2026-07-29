// src/modules/group-join-requests/group-join-requests.module.ts
import { Module } from '@nestjs/common';
import { GroupJoinRequestsController } from './group-join-requests.controller.js';
import { GroupJoinRequestsService } from './group-join-requests.service.js';
import { GroupJoinRequestsRepository } from './group-join-requests.repository.js';
import { GroupsModule } from '../groups/groups.module.js';
import { NotificationsModule } from '../notifications/notifications.module.js';

@Module({
  imports: [GroupsModule, NotificationsModule],
  controllers: [GroupJoinRequestsController],
  providers: [GroupJoinRequestsService, GroupJoinRequestsRepository],
  exports: [GroupJoinRequestsService],
})
export class GroupJoinRequestsModule {}
