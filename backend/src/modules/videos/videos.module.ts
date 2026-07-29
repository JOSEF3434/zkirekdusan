// src/modules/videos/videos.module.ts
import { Module } from '@nestjs/common';
import { VideosController, VideosPublicController } from './videos.controller.js';
import { VideosService } from './videos.service.js';
import { VideosRepository } from './videos.repository.js';
import { UploadsModule } from '../uploads/uploads.module.js';

@Module({
  imports: [UploadsModule],
  controllers: [VideosController, VideosPublicController],
  providers: [VideosService, VideosRepository],
  exports: [VideosService, VideosRepository],
})
export class VideosModule {}
