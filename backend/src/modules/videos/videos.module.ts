// src/modules/videos/videos.module.ts
import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import {
  VideosController,
  VideosPublicController,
} from './videos.controller.js';
import { VideosService } from './videos.service.js';
import { VideosRepository } from './videos.repository.js';
import { UploadsModule } from '../uploads/uploads.module.js';
import { VIDEO_PROCESSING_QUEUE } from '../video-processing/video-processing.processor.js';

@Module({
  imports: [
    UploadsModule,
    BullModule.registerQueue({ name: VIDEO_PROCESSING_QUEUE }),
  ],
  controllers: [VideosController, VideosPublicController],
  providers: [VideosService, VideosRepository],
  exports: [VideosService, VideosRepository],
})
export class VideosModule {}
