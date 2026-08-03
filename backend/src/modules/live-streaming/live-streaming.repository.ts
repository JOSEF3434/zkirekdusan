import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { LiveStream, Prisma, LiveStreamStatus } from '@prisma/client';

const streamInclude = {
  createdBy: {
    select: {
      id: true,
      username: true,
      profile: {
        select: {
          displayName: true,
          avatar: { select: { url: true } },
        },
      },
    },
  },
  group: {
    select: { id: true, name: true, slug: true },
  },
  videoChannel: {
    select: {
      id: true,
      name: true,
      handle: true,
      avatarFile: { select: { url: true } },
    },
  },
} satisfies Prisma.LiveStreamInclude;

@Injectable()
export class LiveStreamingRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createStream(
    data: Prisma.LiveStreamUncheckedCreateInput,
  ): Promise<LiveStream> {
    return this.prisma.liveStream.create({ data });
  }

  async getStreamById(streamId: string) {
    return this.prisma.liveStream.findUnique({
      where: { id: streamId },
      include: streamInclude,
    });
  }

  async getStreamBySlug(slug: string) {
    return this.prisma.liveStream.findUnique({
      where: { slug },
      include: streamInclude,
    });
  }

  async updateStream(streamId: string, data: Prisma.LiveStreamUpdateInput) {
    return this.prisma.liveStream.update({
      where: { id: streamId },
      data,
      include: streamInclude,
    });
  }

  async findStreams(params: {
    where?: Prisma.LiveStreamWhereInput;
    orderBy?: Prisma.LiveStreamOrderByWithRelationInput;
    skip?: number;
    take?: number;
  }) {
    return this.prisma.liveStream.findMany({
      where: params.where,
      orderBy: params.orderBy,
      skip: params.skip,
      take: params.take,
      include: streamInclude,
    });
  }

  async countStreams(where?: Prisma.LiveStreamWhereInput): Promise<number> {
    return this.prisma.liveStream.count({ where });
  }

  async deleteStream(streamId: string) {
    return this.prisma.liveStream.update({
      where: { id: streamId },
      data: {
        status: LiveStreamStatus.CANCELLED,
        deletedAt: new Date(),
      },
    });
  }

  async startStream(streamId: string, rtmpIngestUrl?: string) {
    return this.prisma.liveStream.update({
      where: { id: streamId },
      data: {
        status: LiveStreamStatus.LIVE,
        startedAt: new Date(),
        rtmpIngestUrl,
      },
      include: streamInclude,
    });
  }

  async endStream(streamId: string, duration?: number) {
    return this.prisma.liveStream.update({
      where: { id: streamId },
      data: {
        status: LiveStreamStatus.ENDED,
        endedAt: new Date(),
        duration,
      },
      include: streamInclude,
    });
  }

  async createStreamSession(liveStreamId: string, streamKeyId?: string) {
    return this.prisma.streamSession.create({
      data: { liveStreamId, streamKeyId },
    });
  }

  async endStreamSession(liveStreamId: string) {
    // Find the most recent active session
    const session = await this.prisma.streamSession.findFirst({
      where: { liveStreamId, endedAt: null },
      orderBy: { startedAt: 'desc' },
    });
    if (!session) return null;
    return this.prisma.streamSession.update({
      where: { id: session.id },
      data: { endedAt: new Date() },
    });
  }

  async createRecording(liveStreamId: string) {
    return this.prisma.streamRecording.create({
      data: { liveStreamId },
    });
  }

  // ─── Stream Key Methods ──────────────────────────────────────────────

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
              where: { status: LiveStreamStatus.LIVE },
              take: 1,
              orderBy: { startedAt: 'desc' },
            },
          },
        },
      },
    });
  }

  async upsertStreamKey(channelId: string, keyHash: string, keyPrefix: string) {
    return this.prisma.streamKey.upsert({
      where: { videoChannelId: channelId },
      create: { videoChannelId: channelId, keyHash, keyPrefix },
      update: { keyHash, keyPrefix, lastUsedAt: null },
    });
  }

  async updateStreamKeyUsedAt(id: string) {
    return this.prisma.streamKey.update({
      where: { id },
      data: { lastUsedAt: new Date() },
    });
  }

  async getLiveStreams(params: {
    where?: Prisma.LiveStreamWhereInput;
    orderBy?: Prisma.LiveStreamOrderByWithRelationInput;
    skip?: number;
    take?: number;
  }) {
    return this.findStreams(params);
  }
}
