// src/modules/follows/follows.module.ts
import { Module } from '@nestjs/common';
import { FollowsController } from './follows.controller.js';
import { FollowsService } from './follows.service.js';
import { FollowsRepository } from './follows.repository.js';
import { UsersModule } from '../users/users.module.js';

@Module({
  imports: [UsersModule],
  controllers: [FollowsController],
  providers: [FollowsService, FollowsRepository],
  exports: [FollowsService, FollowsRepository],
})
export class FollowsModule {}
