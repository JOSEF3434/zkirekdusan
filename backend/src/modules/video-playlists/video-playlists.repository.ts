// src/modules/video-playlists/video-playlists.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { PlaylistVisibility } from '@prisma/client';

const PLAYLIST_INCLUDE = {
  owner: {
    select: {
      id: true,
      username: true,
      profile: { select: { displayName: true } },
    },
  },
  videoChannel: {
    select: { id: true, name: true, handle: true },
  },
  items: {
    include: {
      video: {
        select: {
          id: true,
          title: true,
          slug: true,
          duration: true,
          thumbnailUrl: true,
          viewsCount: true,
          videoChannel: { select: { name: true, handle: true } },
        },
      },
    },
    orderBy: { order: 'asc' as const },
  },
} as const;

@Injectable()
export class VideoPlaylistsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    ownerId: string,
    data: {
      title: string;
      description?: string;
      visibility?: PlaylistVisibility;
      videoChannelId?: string;
    },
  ) {
    return this.prisma.videoPlaylist.create({
      data: {
        ownerId,
        title: data.title,
        description: data.description,
        visibility: data.visibility ?? PlaylistVisibility.PUBLIC,
        videoChannelId: data.videoChannelId,
      },
      include: PLAYLIST_INCLUDE,
    });
  }

  async findById(id: string) {
    return this.prisma.videoPlaylist.findUnique({
      where: { id },
      include: PLAYLIST_INCLUDE,
    });
  }

  async findByUser(ownerId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [data, total] = await this.prisma.$transaction([
      this.prisma.videoPlaylist.findMany({
        where: { ownerId },
        include: PLAYLIST_INCLUDE,
        skip,
        take: limit,
        orderBy: { updatedAt: 'desc' },
      }),
      this.prisma.videoPlaylist.count({ where: { ownerId } }),
    ]);
    return { data, total, page, limit };
  }

  async update(
    id: string,
    data: {
      title?: string;
      description?: string;
      visibility?: PlaylistVisibility;
    },
  ) {
    return this.prisma.videoPlaylist.update({
      where: { id },
      data,
      include: PLAYLIST_INCLUDE,
    });
  }

  async delete(id: string) {
    return this.prisma.videoPlaylist.delete({ where: { id } });
  }

  async addItem(playlistId: string, videoId: string) {
    const count = await this.prisma.videoPlaylistItem.count({
      where: { playlistId },
    });
    const item = await this.prisma.videoPlaylistItem.create({
      data: { playlistId, videoId, order: count + 1 },
    });
    await this.prisma.videoPlaylist.update({
      where: { id: playlistId },
      data: { videosCount: { increment: 1 } },
    });
    return item;
  }

  async removeItem(playlistId: string, videoId: string) {
    await this.prisma.videoPlaylistItem.delete({
      where: { playlistId_videoId: { playlistId, videoId } },
    });
    return this.prisma.videoPlaylist.update({
      where: { id: playlistId },
      data: { videosCount: { decrement: 1 } },
    });
  }
}
