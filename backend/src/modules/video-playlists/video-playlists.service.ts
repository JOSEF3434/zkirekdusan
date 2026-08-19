// src/modules/video-playlists/video-playlists.service.ts
import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { VideoPlaylistsRepository } from './video-playlists.repository.js';
import {
  CreatePlaylistDto,
  AddPlaylistItemDto,
} from './dto/create-playlist.dto.js';
import { PrismaService } from '../../prisma/prisma.service.js';
import { AppRole } from '../../common/constants/roles.js';

@Injectable()
export class VideoPlaylistsService {
  constructor(
    private readonly repo: VideoPlaylistsRepository,
    private readonly prisma: PrismaService,
  ) {}

  async create(ownerId: string, dto: CreatePlaylistDto) {
    return this.repo.create(ownerId, dto);
  }

  async findById(id: string) {
    const playlist = await this.repo.findById(id);
    if (!playlist) throw new NotFoundException('Playlist not found');
    return playlist;
  }

  async findByUser(ownerId: string, page = 1, limit = 20) {
    return this.repo.findByUser(ownerId, page, limit);
  }

  async update(id: string, userId: string, dto: Partial<CreatePlaylistDto>) {
    await this.verifyOwnership(id, userId);
    return this.repo.update(id, dto);
  }

  async delete(id: string, userId: string) {
    await this.verifyOwnership(id, userId);
    await this.repo.delete(id);
    return { message: 'Playlist deleted' };
  }

  async addItem(playlistId: string, userId: string, dto: AddPlaylistItemDto) {
    await this.verifyOwnership(playlistId, userId);
    return this.repo.addItem(playlistId, dto.videoId);
  }

  async removeItem(playlistId: string, videoId: string, userId: string) {
    await this.verifyOwnership(playlistId, userId);
    await this.repo.removeItem(playlistId, videoId);
    return { message: 'Item removed from playlist' };
  }

  async findByChannel(videoChannelId: string, page = 1, limit = 20) {
    return this.repo.findByChannel(videoChannelId, page, limit);
  }

  private async verifyOwnership(playlistId: string, userId: string) {
    const playlist = await this.repo.findById(playlistId);
    if (!playlist) throw new NotFoundException('Playlist not found');

    if (playlist.ownerId !== userId) {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        include: { role: true },
      });
      if (
        user?.role.name !== AppRole.SUPER_ADMIN &&
        user?.role.name !== AppRole.ADMIN
      ) {
        throw new ForbiddenException('You do not own this playlist');
      }
    }
  }
}
