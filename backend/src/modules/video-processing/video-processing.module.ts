// src/modules/video-processing/video-processing.module.ts
import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { VideoProcessingService } from './video-processing.service.js';
import {
  VideoProcessingProcessor,
  VIDEO_PROCESSING_QUEUE,
} from './video-processing.processor.js';
import { VideoProcessingController } from './video-processing.controller.js';
import { UploadsModule } from '../uploads/uploads.module.js';

@Module({
  imports: [
    BullModule.registerQueue({
      name: VIDEO_PROCESSING_QUEUE,
    }),
    UploadsModule,
  ],
  controllers: [VideoProcessingController],
  providers: [VideoProcessingService, VideoProcessingProcessor],
  exports: [VideoProcessingService],
})
export class VideoProcessingModule {}
