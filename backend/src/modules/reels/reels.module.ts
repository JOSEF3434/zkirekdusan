// src/modules/reels/reels.module.ts
import { Module } from '@nestjs/common';
import { ReelsController } from './reels.controller.js';
import { ReelsService } from './reels.service.js';
import { ReelsRepository } from './reels.repository.js';
import { UploadsModule } from '../uploads/uploads.module.js';

@Module({
  imports: [UploadsModule],
  controllers: [ReelsController],
  providers: [ReelsService, ReelsRepository],
  exports: [ReelsService, ReelsRepository],
})
export class ReelsModule {}
