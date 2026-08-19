// src/modules/groups/groups.module.ts
import { Module } from '@nestjs/common';
import { GroupsService } from './groups.service.js';
import { GroupsRepository } from './groups.repository.js';
import { GroupsController } from './groups.controller.js';
import { AuthorizationModule } from '../authorization/authorization.module.js';

@Module({
  imports: [AuthorizationModule],
  controllers: [GroupsController],
  providers: [GroupsService, GroupsRepository],
  exports: [GroupsService, GroupsRepository],
})
export class GroupsModule {}
