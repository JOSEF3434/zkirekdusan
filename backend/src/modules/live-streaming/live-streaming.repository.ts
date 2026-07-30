import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { LiveStream, Prisma, LiveStreamStatus } from '@prisma/client';

@Injectable()
export class LiveStreamingRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createStream(data: Prisma.LiveStreamUncheckedCreateInput): Promise<LiveStream> {
    return this.prisma.liveStream.create({
      data,
    });
  }

  async getStreamById(streamId: string): Promise<LiveStream | null> {
    return this.prisma.liveStream.findUnique({
      where: { id: streamId },
      include: {
        createdBy: {
          select: { id: true, username: true, profile: { select: { avatarUrl: true } } },
        },
        group: {
          select: { id: true, name: true },
        },
        videoChannel: {
          select: { id: true, name: true, avatarUrl: true },
        },
      },
    });
  }

  async getStreamBySlug(slug: string): Promise<LiveStream | null> {
    return this.prisma.liveStream.findUnique({
      where: { slug },
      include: {
        createdBy: {
          select: { id: true, username: true, profile: { select: { avatarUrl: true } } },
        },
        videoChannel: {
          select: { id: true, name: true, avatarUrl: true },
        },
      },
    });
  }

  async updateStream(streamId: string, data: Prisma.LiveStreamUpdateInput): Promise<LiveStream> {
    return this.prisma.liveStream.update({
      where: { id: streamId },
      data,
    });
  }

  async findStreams(params: {
    where?: Prisma.LiveStreamWhereInput;
    orderBy?: Prisma.LiveStreamOrderByWithRelationInput;
    skip?: number;
    take?: number;
  }): Promise<LiveStream[]> {
    return this.prisma.liveStream.findMany({
      where: params.where,
      orderBy: params.orderBy,
      skip: params.skip,
      take: params.take,
      include: {
        createdBy: {
          select: { id: true, username: true, profile: { select: { avatarUrl: true } } },
        },
        videoChannel: {
          select: { id: true, name: true, avatarUrl: true },
        },
      },
    });
  }

  async countStreams(where?: Prisma.LiveStreamWhereInput): Promise<number> {
    return this.prisma.liveStream.count({ where });
  }

  async deleteStream(streamId: string): Promise<LiveStream> {
    return this.prisma.liveStream.update({
      where: { id: streamId },
      data: {
        status: LiveStreamStatus.CANCELLED,
        deletedAt: new Date(),
      },
    });
  }

  // Stream Key Methods
  async getStreamKeyByChannelId(channelId: string) {
    return this.prisma.streamKey.findUnique({
      where: { videoChannelId: channelId },
    });
  }

  async getStreamKeyByHash(keyHash: string) {
    return this.prisma.streamKey.findUnique({
      where: { keyHash },
      include: {
        videoChannel: {
          select: {
            id: true,
            groupId: true,
            liveStreams: {
              where: {
                status: LiveStreamStatus.LIVE,
              },
            },
          },
        },
      },
    });
  }

  async upsertStreamKey(channelId: string, keyHash: string, keyPrefix: string) {
    return this.prisma.streamKey.upsert({
      where: { videoChannelId: channelId },
      create: {
        videoChannelId: channelId,
        keyHash,
        keyPrefix,
      },
      update: {
        keyHash,
        keyPrefix,
        lastUsedAt: null,
      },
    });
  }

  async updateStreamKeyUsedAt(id: string) {
    return this.prisma.streamKey.update({
      where: { id },
      data: { lastUsedAt: new Date() },
    });
  }
}
