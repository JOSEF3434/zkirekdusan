import { Module, forwardRef } from '@nestjs/common';
import {
  LiveStreamingController,
  StreamsController,
} from './live-streaming.controller.js';
import { LiveStreamingService } from './live-streaming.service.js';
import { LiveStreamingRepository } from './live-streaming.repository.js';
import { VideoChannelsModule } from '../video-channels/video-channels.module.js';
import { AuthorizationModule } from '../authorization/authorization.module.js';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { StreamProcessingModule } from '../stream-processing/stream-processing.module.js';
import { LiveGatewayModule } from '../live-gateway/live-gateway.module.js';
import { UploadsModule } from '../uploads/uploads.module.js';

@Module({
  imports: [
    VideoChannelsModule,
    AuthorizationModule,
    PrismaModule,
    StreamProcessingModule,
    forwardRef(() => LiveGatewayModule),
    UploadsModule,
  ],
  controllers: [LiveStreamingController, StreamsController],
  providers: [LiveStreamingService, LiveStreamingRepository],
  exports: [LiveStreamingService, LiveStreamingRepository],
})
export class LiveStreamingModule {}
