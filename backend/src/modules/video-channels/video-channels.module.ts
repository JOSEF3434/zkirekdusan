// src/modules/video-channels/video-channels.module.ts
import { Module } from '@nestjs/common';
import { VideoChannelsController, VideoChannelsPublicController } from './video-channels.controller.js';
import { VideoChannelsService } from './video-channels.service.js';
import { VideoChannelsRepository } from './video-channels.repository.js';

@Module({
  controllers: [VideoChannelsController, VideoChannelsPublicController],
  providers: [VideoChannelsService, VideoChannelsRepository],
  exports: [VideoChannelsService, VideoChannelsRepository],
})
export class VideoChannelsModule {}
