// src/modules/saved-posts/saved-posts.module.ts
import { Module } from '@nestjs/common';
import { SavedPostsController } from './saved-posts.controller.js';
import { SavedPostsService } from './saved-posts.service.js';
import { SavedPostsRepository } from './saved-posts.repository.js';
import { PostsModule } from '../posts/posts.module.js';

@Module({
  imports: [PostsModule],
  controllers: [SavedPostsController],
  providers: [SavedPostsService, SavedPostsRepository],
  exports: [SavedPostsService, SavedPostsRepository],
})
export class SavedPostsModule {}
