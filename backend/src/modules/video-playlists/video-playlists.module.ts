// src/modules/video-playlists/video-playlists.module.ts
import { Module } from '@nestjs/common';
import { VideoPlaylistsController } from './video-playlists.controller.js';
import { VideoPlaylistsService } from './video-playlists.service.js';
import { VideoPlaylistsRepository } from './video-playlists.repository.js';

@Module({
  controllers: [VideoPlaylistsController],
  providers: [VideoPlaylistsService, VideoPlaylistsRepository],
  exports: [VideoPlaylistsService],
})
export class VideoPlaylistsModule {}
