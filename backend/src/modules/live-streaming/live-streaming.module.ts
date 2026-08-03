import { Module } from '@nestjs/common';
import {
  LiveStreamingController,
  StreamsController,
} from './live-streaming.controller.js';
import { LiveStreamingService } from './live-streaming.service.js';
import { LiveStreamingRepository } from './live-streaming.repository.js';
import { VideoChannelsModule } from '../video-channels/video-channels.module.js';
import { AuthorizationModule } from '../authorization/authorization.module.js';
import { PrismaModule } from '../../prisma/prisma.module.js';

@Module({
  imports: [VideoChannelsModule, AuthorizationModule, PrismaModule],
  controllers: [LiveStreamingController, StreamsController],
  providers: [LiveStreamingService, LiveStreamingRepository],
  exports: [LiveStreamingService, LiveStreamingRepository],
})
export class LiveStreamingModule {}
