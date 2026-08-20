// src/modules/stories/stories.module.ts
import { Module } from '@nestjs/common';
import { StoriesController } from './stories.controller.js';
import { StoriesService } from './stories.service.js';
import { StoriesRepository } from './stories.repository.js';
import { UploadsModule } from '../uploads/uploads.module.js';

@Module({
  imports: [UploadsModule],
  controllers: [StoriesController],
  providers: [StoriesService, StoriesRepository],
  exports: [StoriesService, StoriesRepository],
})
export class StoriesModule {}
