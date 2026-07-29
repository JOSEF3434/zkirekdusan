// src/modules/video-channels/video-channels.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CreateVideoChannelDto } from './dto/create-video-channel.dto.js';
import { UpdateVideoChannelDto } from './dto/update-video-channel.dto.js';
import { VideoChannelStatus } from '@prisma/client';

const VIDEO_CHANNEL_SELECT = {
  id: true,
  groupId: true,
  name: true,
  slug: true,
  handle: true,
  description: true,
  status: true,
  isVerified: true,
  uploadPermission: true,
  downloadPermission: true,
  subscribersCount: true,
  videosCount: true,
  totalViewsCount: true,
  categories: true,
  tags: true,
  country: true,
  language: true,
  avatarFileId: true,
  bannerFileId: true,
  createdAt: true,
  updatedAt: true,
} as const;

@Injectable()
export class VideoChannelsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(groupId: string, dto: CreateVideoChannelDto) {
    return this.prisma.videoChannel.create({
      data: {
        groupId,
        name: dto.name,
        slug: dto.slug,
        handle: dto.handle,
        description: dto.description,
        uploadPermission: dto.uploadPermission,
        downloadPermission: dto.downloadPermission,
        categories: dto.categories ?? [],
        tags: dto.tags ?? [],
        country: dto.country,
        language: dto.language,
      },
      select: VIDEO_CHANNEL_SELECT,
    });
  }

  async findByGroup(groupId: string, page: number, limit: number) {
    const skip = (page - 1) * limit;
    const [data, total] = await this.prisma.$transaction([
      this.prisma.videoChannel.findMany({
        where: { groupId, deletedAt: null, status: { not: VideoChannelStatus.ARCHIVED } },
        select: VIDEO_CHANNEL_SELECT,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.videoChannel.count({
        where: { groupId, deletedAt: null },
      }),
    ]);
    return { data, total };
  }

  async findById(id: string) {
    return this.prisma.videoChannel.findUnique({
      where: { id, deletedAt: null },
      select: VIDEO_CHANNEL_SELECT,
    });
  }

  async findByHandle(handle: string) {
    return this.prisma.videoChannel.findUnique({
      where: { handle },
      select: VIDEO_CHANNEL_SELECT,
    });
  }

  async findBySlugAndGroup(groupId: string, slug: string) {
    return this.prisma.videoChannel.findUnique({
      where: { groupId_slug: { groupId, slug } },
      select: VIDEO_CHANNEL_SELECT,
    });
  }

  async update(id: string, dto: UpdateVideoChannelDto) {
    return this.prisma.videoChannel.update({
      where: { id },
      data: {
        ...dto,
        categories: dto.categories,
        tags: dto.tags,
      },
      select: VIDEO_CHANNEL_SELECT,
    });
  }

  async softDelete(id: string) {
    return this.prisma.videoChannel.update({
      where: { id },
      data: { deletedAt: new Date(), status: VideoChannelStatus.ARCHIVED },
    });
  }

  async incrementSubscribers(id: string, delta: 1 | -1) {
    return this.prisma.videoChannel.update({
      where: { id },
      data: { subscribersCount: { increment: delta } },
    });
  }

  async incrementVideos(id: string, delta: 1 | -1) {
    return this.prisma.videoChannel.update({
      where: { id },
      data: { videosCount: { increment: delta } },
    });
  }

  async isSubscribed(userId: string, videoChannelId: string) {
    const sub = await this.prisma.videoSubscription.findUnique({
      where: { userId_videoChannelId: { userId, videoChannelId } },
    });
    return !!sub;
  }

  async subscribe(userId: string, videoChannelId: string) {
    return this.prisma.videoSubscription.upsert({
      where: { userId_videoChannelId: { userId, videoChannelId } },
      create: { userId, videoChannelId },
      update: {},
    });
  }

  async unsubscribe(userId: string, videoChannelId: string) {
    return this.prisma.videoSubscription.delete({
      where: { userId_videoChannelId: { userId, videoChannelId } },
    });
  }

  async getSubscribers(videoChannelId: string, page: number, limit: number) {
    const skip = (page - 1) * limit;
    const [data, total] = await this.prisma.$transaction([
      this.prisma.videoSubscription.findMany({
        where: { videoChannelId },
        include: {
          user: {
            select: {
              id: true,
              username: true,
              profile: { select: { displayName: true, avatarFileId: true } },
            },
          },
        },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.videoSubscription.count({ where: { videoChannelId } }),
    ]);
    return { data, total };
  }
}
