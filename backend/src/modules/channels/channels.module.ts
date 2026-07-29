// src/modules/channels/channels.module.ts
import { Module } from '@nestjs/common';
import { ChannelsController } from './channels.controller.js';
import { ChannelsService } from './channels.service.js';
import { ChannelsRepository } from './channels.repository.js';
import { GroupsModule } from '../groups/groups.module.js';

@Module({
  imports: [GroupsModule],
  controllers: [ChannelsController],
  providers: [ChannelsService, ChannelsRepository],
  exports: [ChannelsService, ChannelsRepository],
})
export class ChannelsModule {}
