// src/modules/stories/stories.module.ts
import { Module } from '@nestjs/common';
import { StoriesController } from './stories.controller.js';
import { StoriesService } from './stories.service.js';
import { StoriesRepository } from './stories.repository.js';

@Module({
  controllers: [StoriesController],
  providers: [StoriesService, StoriesRepository],
  exports: [StoriesService, StoriesRepository],
})
export class StoriesModule {}
