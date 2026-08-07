import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  Logger,
  ConflictException,
} from '@nestjs/common';
import { LiveStreamingRepository } from './live-streaming.repository.js';
import { VideoChannelsRepository } from '../video-channels/video-channels.repository.js';
import { AuthorizationService } from '../authorization/authorization.service.js';
import { CreateStreamDto } from './dto/create-stream.dto.js';
import { UpdateStreamDto } from './dto/update-stream.dto.js';
import { GroupRole } from '../../common/constants/group-roles.js';
import { LiveStreamStatus, GlobalRole } from '@prisma/client';
import { randomBytes, createHash } from 'crypto';
import slugify from 'slugify';
import { nanoid } from 'nanoid';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service.js';
import { StreamProcessingService } from '../stream-processing/stream-processing.service.js';
import { LiveGateway } from '../live-gateway/live.gateway.js';
import { forwardRef, Inject } from '@nestjs/common';

@Injectable()
export class LiveStreamingService {
  private readonly logger = new Logger(LiveStreamingService.name);

  constructor(
    private readonly repository: LiveStreamingRepository,
    private readonly videoChannelsRepository: VideoChannelsRepository,
    private readonly authorizationService: AuthorizationService,
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
    private readonly streamProcessingService: StreamProcessingService,
    @Inject(forwardRef(() => LiveGateway))
    private readonly liveGateway: LiveGateway,
  ) {}

  private generateSlug(title: string): string {
    return `${slugify(title, { lower: true, strict: true })}-${nanoid(6)}`;
  }

  /**
   * Check if user is a SUPER_ADMIN or ADMIN globally
   */
  private async isGlobalAdmin(userId: string): Promise<boolean> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { role: true },
    });
    return (
      user?.role?.name === GlobalRole.SUPER_ADMIN ||
      user?.role?.name === GlobalRole.ADMIN
    );
  }

  /**
   * Check if user has at least MODERATOR role in a group, OR is a global admin
   */
  private async hasStreamPermission(
    userId: string,
    groupId: string,
  ): Promise<boolean> {
    if (await this.isGlobalAdmin(userId)) return true;
    return this.authorizationService.hasGroupRole(
      userId,
      groupId,
      GroupRole.MODERATOR,
    );
  }

  /**
   * Check if user has at least GROUP_ADMIN role in a group, OR is a global admin
   */
  private async hasStreamAdminPermission(
    userId: string,
    groupId: string,
  ): Promise<boolean> {
    if (await this.isGlobalAdmin(userId)) return true;
    return this.authorizationService.hasGroupRole(
      userId,
      groupId,
      GroupRole.GROUP_ADMIN,
    );
  }

  async createStream(userId: string, channelId: string, dto: CreateStreamDto) {
    const channel = await this.videoChannelsRepository.findById(channelId);
    if (!channel) throw new NotFoundException('Video channel not found');

    const hasPermission = await this.hasStreamPermission(
      userId,
      channel.groupId,
    );
    if (!hasPermission) {
      throw new ForbiddenException(
        'You do not have permission to create streams in this channel',
      );
    }

    const slug = this.generateSlug(dto.title);
    const initialStatus = dto.scheduledAt
      ? LiveStreamStatus.SCHEDULED
      : LiveStreamStatus.DRAFT;

    const stream = await this.repository.createStream({
      videoChannelId: channel.id,
      groupId: channel.groupId,
      createdById: userId,
      title: dto.title,
      description: dto.description,
      slug,
      status: initialStatus,
      visibility: dto.visibility,
      protocol: dto.protocol,
      scheduledAt: dto.scheduledAt,
      categories: dto.categories ?? [],
      tags: dto.tags ?? [],
      hashtags: dto.hashtags ?? [],
      isRecordingEnabled: dto.isRecordingEnabled,
      isDvrEnabled: dto.isDvrEnabled,
      isReplayEnabled: dto.isReplayEnabled,
      isChatEnabled: dto.isChatEnabled,
      isChatSlowMode: dto.isChatSlowMode,
      chatSlowModeSeconds: dto.chatSlowModeSeconds,
      isMembersOnlyChat: dto.isMembersOnlyChat,
      isSubscribersOnlyChat: dto.isSubscribersOnlyChat,
    });

    return stream;
  }

  async getStreamById(userId: string | undefined, streamId: string) {
    const stream = await this.repository.getStreamById(streamId);
    if (!stream || stream.deletedAt)
      throw new NotFoundException('Stream not found');

    if (stream.visibility !== 'PUBLIC') {
      if (!userId)
        throw new ForbiddenException(
          'Authentication required to view this stream',
        );
      const hasPermission = await this.authorizationService.hasGroupRole(
        userId,
        stream.groupId,
        GroupRole.MEMBER,
      );
      if (!hasPermission) throw new ForbiddenException('Stream is private');
    }

    return stream;
  }

  async updateStream(userId: string, streamId: string, dto: UpdateStreamDto) {
    const stream = await this.repository.getStreamById(streamId);
    if (!stream || stream.deletedAt)
      throw new NotFoundException('Stream not found');

    if (stream.status === LiveStreamStatus.LIVE) {
      throw new BadRequestException(
        'Cannot update metadata while stream is live. Use end stream first.',
      );
    }

    const hasPermission = await this.hasStreamPermission(
      userId,
      stream.groupId,
    );
    if (!hasPermission) {
      throw new ForbiddenException(
        'You do not have permission to update this stream',
      );
    }

    return this.repository.updateStream(streamId, dto);
  }

  async deleteStream(userId: string, streamId: string) {
    const stream = await this.repository.getStreamById(streamId);
    if (!stream || stream.deletedAt)
      throw new NotFoundException('Stream not found');

    if (stream.status === LiveStreamStatus.LIVE) {
      throw new BadRequestException(
        'Cannot delete an active live stream. End it first.',
      );
    }

    const hasPermission = await this.hasStreamPermission(
      userId,
      stream.groupId,
    );
    if (!hasPermission) {
      throw new ForbiddenException(
        'You do not have permission to delete this stream',
      );
    }

    return this.repository.deleteStream(streamId);
  }

  async getChannelStreams(
    userId: string | undefined,
    channelId: string,
    page = 1,
    limit = 20,
  ) {
    const channel = await this.videoChannelsRepository.findById(channelId);
    if (!channel) throw new NotFoundException('Channel not found');

    const skip = (page - 1) * limit;
    const where: import('@prisma/client').Prisma.LiveStreamWhereInput = {
      videoChannelId: channelId,
      deletedAt: null,
    };

    if (!userId) {
      where.visibility = 'PUBLIC';
    } else {
      const isAdmin = await this.isGlobalAdmin(userId);
      if (!isAdmin) {
        const hasMemberRole = await this.authorizationService.hasGroupRole(
          userId,
          channel.groupId,
          GroupRole.MEMBER,
        );
        if (!hasMemberRole) {
          where.visibility = 'PUBLIC';
        }
      }
    }

    const [streams, total] = await Promise.all([
      this.repository.findStreams({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.repository.countStreams(where),
    ]);

    return { data: streams, total, page, limit };
  }

  async getLiveStreams(userId: string | undefined, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const where: import('@prisma/client').Prisma.LiveStreamWhereInput = {
      status: LiveStreamStatus.LIVE,
      deletedAt: null,
      visibility: 'PUBLIC',
    };

    const [streams, total] = await Promise.all([
      this.repository.findStreams({
        where,
        orderBy: { currentViewerCount: 'desc' },
        skip,
        take: limit,
      }),
      this.repository.countStreams(where),
    ]);

    return { data: streams, total, page, limit };
  }

  async getScheduledStreams(userId: string | undefined, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const where: import('@prisma/client').Prisma.LiveStreamWhereInput = {
      status: LiveStreamStatus.SCHEDULED,
      deletedAt: null,
      visibility: 'PUBLIC',
      scheduledAt: { gt: new Date() },
    };

    const [streams, total] = await Promise.all([
      this.repository.findStreams({
        where,
        orderBy: { scheduledAt: 'asc' },
        skip,
        take: limit,
      }),
      this.repository.countStreams(where),
    ]);

    return { data: streams, total, page, limit };
  }

  // ─── Stream Lifecycle ──────────────────────────────────────────────

  async startStream(userId: string, streamId: string) {
    const stream = await this.repository.getStreamById(streamId);
    if (!stream || stream.deletedAt)
      throw new NotFoundException('Stream not found');

    if (stream.status === LiveStreamStatus.LIVE) {
      throw new ConflictException('Stream is already live');
    }
    if (
      stream.status === LiveStreamStatus.ENDED ||
      stream.status === LiveStreamStatus.CANCELLED
    ) {
      throw new BadRequestException(
        'Cannot restart an ended or cancelled stream',
      );
    }

    const hasPermission = await this.hasStreamPermission(
      userId,
      stream.groupId,
    );
    if (!hasPermission) {
      throw new ForbiddenException(
        'You do not have permission to start this stream',
      );
    }

    // Get stream key for the channel
    const streamKey = await this.repository.getStreamKeyByChannelId(
      stream.videoChannelId,
    );
    const rtmpBaseUrl = this.configService.get<string>(
      'RTMP_SERVER_URL',
      'rtmp://localhost:1935/live',
    );
    const rtmpIngestUrl = streamKey
      ? `${rtmpBaseUrl}?key=${streamKey.keyPrefix}`
      : undefined;

    const updatedStream = await this.repository.startStream(
      streamId,
      rtmpIngestUrl,
    );

    // Create a stream session for tracking
    await this.repository.createStreamSession(streamId, streamKey?.id);

    // Create chat room if chat is enabled
    if (stream.isChatEnabled) {
      await this.prisma.streamChatRoom.upsert({
        where: { liveStreamId: streamId },
        create: { liveStreamId: streamId },
        update: {},
      });
    }

    this.logger.log(`Stream ${streamId} started by user ${userId}`);

    // Broadcast stream started to LiveGateway
    this.liveGateway.broadcastStreamStarted(streamId, updatedStream);

    return updatedStream;
  }

  async endStream(userId: string, streamId: string) {
    const stream = await this.repository.getStreamById(streamId);
    if (!stream || stream.deletedAt)
      throw new NotFoundException('Stream not found');

    if (stream.status !== LiveStreamStatus.LIVE) {
      throw new BadRequestException('Stream is not currently live');
    }

    const hasPermission = await this.hasStreamPermission(
      userId,
      stream.groupId,
    );
    if (!hasPermission) {
      throw new ForbiddenException(
        'You do not have permission to end this stream',
      );
    }

    // Calculate duration
    const duration = stream.startedAt
      ? (Date.now() - stream.startedAt.getTime()) / 1000
      : undefined;

    const updatedStream = await this.repository.endStream(streamId, duration);
    await this.repository.endStreamSession(streamId);

    // If recording was enabled, create a recording record for processing
    if (stream.isRecordingEnabled) {
      const recording = await this.repository.createRecording(streamId);

      // Enqueue job to process recording
      await this.streamProcessingService.enqueueRecording({
        liveStreamId: streamId,
        recordingId: recording.id,
        recordingPath: `streams/${streamId}/recording.mp4`, // In a real system, this would come from the media server
      });
    }

    this.logger.log(
      `Stream ${streamId} ended by user ${userId}, duration: ${duration?.toFixed(0)}s`,
    );

    // Broadcast stream ended to LiveGateway
    this.liveGateway.broadcastStreamEnded(streamId, undefined, duration);

    return updatedStream;
  }

  async publishVod(userId: string, streamId: string) {
    const stream = await this.repository.getStreamById(streamId);
    if (!stream || stream.deletedAt)
      throw new NotFoundException('Stream not found');

    if (stream.status !== LiveStreamStatus.ENDED) {
      throw new BadRequestException(
        'Stream must be ended before publishing VOD',
      );
    }

    const hasPermission = await this.hasStreamPermission(
      userId,
      stream.groupId,
    );
    if (!hasPermission) {
      throw new ForbiddenException(
        'You do not have permission to publish VOD for this stream',
      );
    }

    const recording = await this.prisma.streamRecording.findFirst({
      where: { liveStreamId: streamId },
      orderBy: { startedAt: 'desc' },
    });

    if (!recording || recording.status !== 'READY') {
      throw new BadRequestException(
        'No ready recording available for this stream',
      );
    }

    const existingVideo = await this.prisma.video.findFirst({
      where: { hlsUrl: recording.hlsUrl },
    });

    if (existingVideo) {
      this.logger.log(`VOD already exists for stream ${streamId}`);
      return {
        message: 'VOD already published',
        recordingId: recording.id,
        videoId: existingVideo.id,
        hlsUrl: existingVideo.hlsUrl,
      };
    }

    // Create a Video entity from the recording
    const video = await this.prisma.video.create({
      data: {
        videoChannelId: stream.videoChannelId,
        uploadedById: userId,
        title: stream.title,
        description: stream.description ?? `VOD for stream ${stream.title}`,
        slug: `vod-${stream.id}-${nanoid(8)}`,
        status: 'READY',
        visibility: 'PUBLIC',
        duration: recording.duration,
        hlsUrl: recording.hlsUrl,
      },
    });

    this.logger.log(`VOD published for stream ${streamId} by user ${userId}. Video ID: ${video.id}`);
    return {
      message: 'VOD published successfully',
      recordingId: recording.id,
      videoId: video.id,
      hlsUrl: video.hlsUrl,
    };
  }

  // ─── Stream Key Management ──────────────────────────────────────────────

  async getStreamKey(userId: string, channelId: string) {
    const channel = await this.videoChannelsRepository.findById(channelId);
    if (!channel) throw new NotFoundException('Channel not found');

    const hasPermission = await this.hasStreamPermission(
      userId,
      channel.groupId,
    );
    if (!hasPermission) {
      throw new ForbiddenException(
        'You do not have permission to view stream keys',
      );
    }

    const key = await this.repository.getStreamKeyByChannelId(channelId);
    if (!key) {
      return { keyPrefix: null, rtmpUrl: null, hasKey: false };
    }

    return {
      keyPrefix: key.keyPrefix,
      rtmpUrl: this.configService.get<string>(
        'RTMP_SERVER_URL',
        'rtmp://localhost:1935/live',
      ),
      hasKey: true,
      lastUsedAt: key.lastUsedAt,
    };
  }

  async generateStreamKey(userId: string, channelId: string) {
    const channel = await this.videoChannelsRepository.findById(channelId);
    if (!channel) throw new NotFoundException('Channel not found');

    const hasPermission = await this.hasStreamPermission(
      userId,
      channel.groupId,
    );
    if (!hasPermission) {
      throw new ForbiddenException(
        'You do not have permission to manage stream keys',
      );
    }

    // Generate secure key: sk_live_<48 hex chars>
    const rawKey = randomBytes(24).toString('hex');
    const keyPrefix = `sk_live_${rawKey.substring(0, 8)}`;
    const keyHash = createHash('sha256').update(rawKey).digest('hex');

    await this.repository.upsertStreamKey(channelId, keyHash, keyPrefix);

    // Return raw key ONCE — not stored in plaintext
    return {
      streamKey: rawKey,
      rtmpUrl: this.configService.get<string>(
        'RTMP_SERVER_URL',
        'rtmp://localhost:1935/live',
      ),
      warning: 'This key will not be shown again. Store it securely.',
    };
  }

  /** Nginx-RTMP on_publish webhook handler */
  async handleRtmpOnPublish(streamKeyName: string): Promise<void> {
    const keyHash = createHash('sha256').update(streamKeyName).digest('hex');
    const streamKey = await this.repository.getStreamKeyByHash(keyHash);

    if (!streamKey || !streamKey.isActive) {
      this.logger.warn(`Invalid or inactive stream key used: ${streamKeyName.substring(0, 8)}...`);
      throw new ForbiddenException('Invalid stream key');
    }

    await this.repository.updateStreamKeyUsedAt(streamKey.id);

    const activeLiveStream = streamKey.videoChannel?.liveStreams?.[0];
    if (activeLiveStream) {
      try {
        // Start the stream
        await this.startStream(activeLiveStream.createdById, activeLiveStream.id);
        
        this.logger.log(`Nginx-RTMP on_publish authorized for stream ${activeLiveStream.id}`);
      } catch (err: any) {
        if (err instanceof ConflictException) {
          this.logger.log(`Stream ${activeLiveStream.id} is already LIVE (Reconnect detected)`);
          // Record a new session for the reconnect
          await this.repository.createStreamSession(activeLiveStream.id, streamKey.id);
        } else {
          throw err;
        }
      }
    } else {
      this.logger.warn(`Valid stream key but no active LIVE stream configured for channel ${streamKey.videoChannelId}`);
      // In a real system you might auto-create a stream, but here we require one to be created first
      throw new ForbiddenException('No active stream configured for this channel');
    }
  }

  /** Nginx-RTMP on_done webhook handler */
  async handleRtmpOnDone(streamKeyName: string): Promise<void> {
    const keyHash = createHash('sha256').update(streamKeyName).digest('hex');
    const streamKey = await this.repository.getStreamKeyByHash(keyHash);

    if (!streamKey) return;

    const activeLiveStream = streamKey.videoChannel?.liveStreams?.[0];
    if (activeLiveStream) {
      // End the stream securely
      await this.endStream(activeLiveStream.createdById, activeLiveStream.id);
      this.logger.log(`Nginx-RTMP on_done handled for stream ${activeLiveStream.id}`);
    }
  }
}
