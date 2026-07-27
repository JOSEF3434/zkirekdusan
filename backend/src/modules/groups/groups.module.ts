// src/modules/groups/groups.module.ts
import { Module } from '@nestjs/common';
import { GroupsService } from './groups.service.js';
import { GroupsRepository } from './groups.repository.js';
import { GroupsController } from './groups.controller.js';

@Module({
  controllers: [GroupsController],
  providers: [GroupsService, GroupsRepository],
  exports: [GroupsService, GroupsRepository],
})
export class GroupsModule {}
