// src/modules/video-processing/video-processing.module.ts
import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { VideoProcessingService } from './video-processing.service.js';
import {
  VideoProcessingProcessor,
  VIDEO_PROCESSING_QUEUE,
} from './video-processing.processor.js';
import { VideoProcessingController } from './video-processing.controller.js';

@Module({
  imports: [
    BullModule.registerQueue({
      name: VIDEO_PROCESSING_QUEUE,
    }),
  ],
  controllers: [VideoProcessingController],
  providers: [VideoProcessingService, VideoProcessingProcessor],
  exports: [VideoProcessingService],
})
export class VideoProcessingModule {}
