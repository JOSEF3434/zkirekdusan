// src/modules/video-comments/video-comments.module.ts
import { Module } from '@nestjs/common';
import { VideoCommentsController } from './video-comments.controller.js';
import { VideoCommentsService } from './video-comments.service.js';
import { VideoCommentsRepository } from './video-comments.repository.js';

@Module({
  controllers: [VideoCommentsController],
  providers: [VideoCommentsService, VideoCommentsRepository],
  exports: [VideoCommentsService],
})
export class VideoCommentsModule {}
