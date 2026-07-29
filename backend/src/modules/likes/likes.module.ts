// src/modules/likes/likes.module.ts
import { Module } from '@nestjs/common';
import { LikesController } from './likes.controller.js';
import { LikesService } from './likes.service.js';
import { LikesRepository } from './likes.repository.js';

@Module({
  controllers: [LikesController],
  providers: [LikesService, LikesRepository],
  exports: [LikesService, LikesRepository],
})
export class LikesModule {}
