// src/modules/video-subscriptions/video-subscriptions.module.ts
import { Module } from '@nestjs/common';
import { VideoSubscriptionsController } from './video-subscriptions.controller.js';
import { VideoSubscriptionsService } from './video-subscriptions.service.js';

@Module({
  controllers: [VideoSubscriptionsController],
  providers: [VideoSubscriptionsService],
  exports: [VideoSubscriptionsService],
})
export class VideoSubscriptionsModule {}
