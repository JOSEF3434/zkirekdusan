// src/modules/profiles/profiles.module.ts
import { Module } from '@nestjs/common';
import { ProfilesService } from './profiles.service.js';
import { ProfilesRepository } from './profiles.repository.js';
import { ProfilesController } from './profiles.controller.js';
import { PostsModule } from '../posts/posts.module.js';

@Module({
  imports: [PostsModule],
  controllers: [ProfilesController],
  providers: [ProfilesService, ProfilesRepository],
  exports: [ProfilesService, ProfilesRepository],
})
export class ProfilesModule {}
