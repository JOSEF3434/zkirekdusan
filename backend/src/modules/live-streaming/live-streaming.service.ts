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
import { CloudinaryStorageProvider } from '../uploads/providers/cloudinary.provider.js';
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
    private readonly cloudinaryProvider: CloudinaryStorageProvider,
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
   * Check if user has at least MODERATOR role in a group, OR is a global admin,
   * OR is the group creator.
   */
  private async hasStreamPermission(
    userId: string,
    groupId: string,
  ): Promise<boolean> {
    if (await this.isGlobalAdmin(userId)) return true;
    // Group creator always has permission to stream
    const group = await this.prisma.group.findUnique({
      where: { id: groupId },
      select: { createdById: true },
    });
    if (group?.createdById === userId) return true;
    return this.authorizationService.hasGroupRole(
      userId,
      groupId,
      GroupRole.MODERATOR,
    );
  }

  /**
   * Check if user has at least GROUP_ADMIN role in a group, OR is a global admin,
   * OR is the group creator.
   */
  private async hasStreamAdminPermission(
    userId: string,
    groupId: string,
  ): Promise<boolean> {
    if (await this.isGlobalAdmin(userId)) return true;
    const group = await this.prisma.group.findUnique({
      where: { id: groupId },
      select: { createdById: true },
    });
    if (group?.createdById === userId) return true;
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
      rtmpIngestUrl: this.getRtmpServerUrl(),
    });

    // Re-fetch with full relations so Flutter can parse the response correctly
    const fullStream = await this.repository.getStreamById(stream.id);
    return fullStream ?? stream;
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

    const hasPermission = await this.hasStreamPermission(
      userId,
      stream.groupId,
    );
    if (!hasPermission) {
      throw new ForbiddenException(
        'You do not have permission to delete this stream',
      );
    }

    if (stream.status === LiveStreamStatus.LIVE) {
      try {
        await this.endStream(userId, streamId);
      } catch {
        await this.repository.endStreamSession(streamId).catch(() => {});
      }
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

  private getRtmpServerUrl(): string {
    const configured = this.configService.get<string>('RTMP_SERVER_URL');
    if (
      configured &&
      !configured.includes('localhost') &&
      !configured.includes('127.0.0.1') &&
      !configured.includes('10.0.2.2') &&
      !configured.includes('onrender.com') &&
      !configured.includes('render.com')
    ) {
      return configured;
    }
    return 'rtmp://live.cloudinary.com/streams';
  }

  async startStream(userId: string, streamId: string) {
    const stream = await this.repository.getStreamById(streamId);
    if (!stream || stream.deletedAt)
      throw new NotFoundException('Stream not found');

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
    let streamKey = await this.repository.getStreamKeyByChannelId(
      stream.videoChannelId,
    );
    let rtmpBaseUrl = this.getRtmpServerUrl();
    let rtmpIngestUrl = stream.rtmpIngestUrl || rtmpBaseUrl;
    let activeStreamKey: string | null = null;

    // If Cloudinary is configured, provision / activate Cloudinary live stream
    if (this.cloudinaryProvider?.configured) {
      try {
        let cldStreamId = stream.webrtcUrl?.replace('cloudinary:', '');
        let hlsUrl = stream.hlsUrl;
        let archivePublicId = stream.dashUrl;

        // Check if the channel already has a Cloudinary live stream provisioned via its stream key
        const cldIdFromKey = streamKey?.keyPrefix?.startsWith('cld_')
          ? streamKey.keyPrefix.replace('cld_', '')
          : null;

        if (cldIdFromKey && (!cldStreamId || cldStreamId === cldIdFromKey)) {
          cldStreamId = cldIdFromKey;
          hlsUrl = `https://res.cloudinary.com/${this.cloudinaryProvider.currentCloudName || 'v6zdpkoh'}/video/live/live_stream_${cldStreamId}_hls.m3u8`;
          archivePublicId = `live_stream_${cldStreamId}_archive`;
          rtmpBaseUrl = 'rtmp://live.cloudinary.com/streams';
          rtmpIngestUrl = 'rtmp://live.cloudinary.com/streams';

          // Fetch active stream key from Cloudinary to pass to the broadcaster
          try {
            const cldData = await this.cloudinaryProvider.getLiveStream(cldStreamId);
            if (cldData?.input?.stream_key) {
              activeStreamKey = cldData.input.stream_key;
            }
          } catch (_) {}
        } else if (!cldStreamId || !hlsUrl || !streamKey?.keyPrefix?.startsWith('cld_')) {
          // If not already provisioned on Cloudinary, create it now
          const safeSlug = (stream.slug || stream.id).replace(/[^a-zA-Z0-9_-]/g, '_');
          const cld = await this.cloudinaryProvider.createLiveStream(
            `stream_${safeSlug}`,
          );
          cldStreamId = cld.id;
          hlsUrl = cld.hlsUrl;
          archivePublicId = cld.archivePublicId;
          rtmpBaseUrl = cld.rtmpIngestUrl;
          rtmpIngestUrl = cld.rtmpIngestUrl;
          activeStreamKey = cld.streamKey;

          // Upsert channel's stream key to match Cloudinary
          const keyHash = createHash('sha256').update(cld.streamKey).digest('hex');
          const keyPrefix = `cld_${cld.id}`;
          streamKey = await this.repository.upsertStreamKey(
            stream.videoChannelId,
            keyHash,
            keyPrefix,
          );
        } else {
          rtmpBaseUrl = 'rtmp://live.cloudinary.com/streams';
          rtmpIngestUrl = 'rtmp://live.cloudinary.com/streams';
        }

        // Activate Cloudinary live stream
        if (cldStreamId) {
          await this.cloudinaryProvider.activateLiveStream(cldStreamId);
        }

        // Update stream with Cloudinary playback & ingest URLs
        await this.prisma.liveStream.update({
          where: { id: streamId },
          data: {
            hlsUrl,
            rtmpIngestUrl,
            webrtcUrl: `cloudinary:${cldStreamId}`,
            dashUrl: archivePublicId,
          },
        });
      } catch (err: any) {
        this.logger.error(`Error provisioning Cloudinary live stream: ${err.message}`, err.stack);
      }
    }

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

    // Broadcast stream started event via WebSocket
    this.liveGateway.broadcastStreamStarted(streamId, {
      id: streamId,
      title: stream.title,
      status: LiveStreamStatus.LIVE,
      startedAt: updatedStream.startedAt ?? new Date(),
      hlsUrl: updatedStream.hlsUrl,
      dashUrl: updatedStream.dashUrl,
      webrtcUrl: updatedStream.webrtcUrl,
    });

    return {
      ...updatedStream,
      streamKey: activeStreamKey || undefined,
    };

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

    // Cloudinary Live Stream idle
    if (this.cloudinaryProvider?.configured) {
      const cldStreamId = stream.webrtcUrl?.replace('cloudinary:', '');
      if (cldStreamId) {
        await this.cloudinaryProvider.idleLiveStream(cldStreamId);
      }
    }

    // If recording was enabled, create a recording record for processing & storage
    if (stream.isRecordingEnabled) {
      const recording = await this.repository.createRecording(streamId);
      const appUrl =
        this.configService.get<string>('APP_URL') ??
        this.configService.get<string>('RENDER_EXTERNAL_URL') ??
        'https://zikrekidusan.onrender.com';
      const vodHlsUrl =
        this.cloudinaryProvider?.configured && stream.dashUrl
          ? `https://res.cloudinary.com/${this.cloudinaryProvider.currentCloudName || 'v6zdpkoh'}/video/upload/sp_hd/${stream.dashUrl}.m3u8`
          : (stream.hlsUrl ?? `${appUrl}/uploads/streams/${streamId}/index.m3u8`);

      // Mark recording ready so user can immediately view/publish VOD
      await this.prisma.streamRecording.update({
        where: { id: recording.id },
        data: {
          status: 'READY',
          duration: Math.round(duration ?? 0),
          hlsUrl: vodHlsUrl,
          fileSize: BigInt(0),
        },
      });

      try {
        await this.streamProcessingService.enqueueRecording({
          liveStreamId: streamId,
          recordingId: recording.id,
          recordingPath: `streams/${streamId}/recording.mp4`,
        });
      } catch (err) {
        this.logger.warn(`Could not enqueue recording job for stream ${streamId}: ${err}`);
      }
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

    let recording = await this.prisma.streamRecording.findFirst({
      where: { liveStreamId: streamId },
      orderBy: { startedAt: 'desc' },
    });

    if (!recording) {
      // Create fallback recording record
      recording = await this.repository.createRecording(streamId);
      const appUrl =
        this.configService.get<string>('APP_URL') ??
        this.configService.get<string>('RENDER_EXTERNAL_URL') ??
        'https://zikrekidusan.onrender.com';
      const fallbackHlsUrl = stream.hlsUrl ?? `${appUrl}/uploads/streams/${streamId}/index.m3u8`;
      recording = await this.prisma.streamRecording.update({
        where: { id: recording.id },
        data: {
          status: 'READY',
          duration: Math.round(stream.duration ?? 0),
          hlsUrl: fallbackHlsUrl,
        },
      });
    }

    const cldArchivePublicId = stream.dashUrl;
    let playbackUrl = recording.hlsUrl;
    if ((!playbackUrl || playbackUrl.includes('/uploads/')) && cldArchivePublicId && this.cloudinaryProvider?.configured) {
      playbackUrl = `https://res.cloudinary.com/${this.cloudinaryProvider.currentCloudName || 'v6zdpkoh'}/video/upload/sp_hd/${cldArchivePublicId}.m3u8`;
    }
    if (!playbackUrl) {
      playbackUrl = stream.hlsUrl || '';
    }

    const existingVideo = await this.prisma.video.findFirst({
      where: {
        OR: [
          ...(playbackUrl ? [{ hlsUrl: playbackUrl }] : []),
          { title: stream.title, videoChannelId: stream.videoChannelId },
        ],
      },
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
        description: stream.description ?? `Recorded live stream: ${stream.title}`,
        slug: `vod-${stream.id}-${nanoid(8)}`,
        status: 'READY',
        visibility: stream.visibility as any,
        duration: recording.duration || Math.round(stream.duration ?? 0),
        hlsUrl: playbackUrl,
        thumbnailUrl: stream.thumbnailUrl,
        categories: stream.categories,
        tags: stream.tags,
        hashtags: stream.hashtags,
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
      return { channelId, keyPrefix: null, rtmpUrl: null, hasKey: false };
    }

    let rawKey: string | undefined;
    if (key.keyPrefix?.startsWith('cld_') && this.cloudinaryProvider?.configured) {
      const cldId = key.keyPrefix.replace('cld_', '');
      try {
        const cld = await this.cloudinaryProvider.getLiveStream(cldId);
        if (cld?.input?.stream_key) {
          rawKey = cld.input.stream_key;
        }
      } catch (_) {}
    }

    return {
      channelId,
      keyPrefix: key.keyPrefix,
      rawKey,
      streamKey: rawKey,
      rtmpUrl: this.getRtmpServerUrl(),
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

    let rawKey: string;
    let rtmpUrl: string;

    if (this.cloudinaryProvider?.configured) {
      try {
        const safeName = `channel_${(channel.handle || channel.id).replace(/[^a-zA-Z0-9_-]/g, '_')}`;
        const cld = await this.cloudinaryProvider.createLiveStream(safeName);
        rawKey = cld.streamKey;
        rtmpUrl = cld.rtmpIngestUrl || this.getRtmpServerUrl();
        const keyPrefix = `cld_${cld.id}`;
        const keyHash = createHash('sha256').update(rawKey).digest('hex');
        await this.repository.upsertStreamKey(channelId, keyHash, keyPrefix);
      } catch (err: any) {
        this.logger.warn(
          `Cloudinary live stream creation failed: ${err?.message || err}. Falling back to internal RTMP server.`,
        );
        rawKey = randomBytes(24).toString('hex');
        const keyPrefix = `sk_live_${rawKey.substring(0, 8)}`;
        const keyHash = createHash('sha256').update(rawKey).digest('hex');
        rtmpUrl = this.getRtmpServerUrl();
        await this.repository.upsertStreamKey(channelId, keyHash, keyPrefix);
      }
    } else {
      rawKey = randomBytes(24).toString('hex');
      const keyPrefix = `sk_live_${rawKey.substring(0, 8)}`;
      const keyHash = createHash('sha256').update(rawKey).digest('hex');
      rtmpUrl = this.getRtmpServerUrl();
      await this.repository.upsertStreamKey(channelId, keyHash, keyPrefix);
    }

    // Return raw key ONCE — not stored in plaintext
    return {
      channelId,
      rawKey,
      streamKey: rawKey,
      rtmpUrl,
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

  /** Cloudinary live stream archive / upload webhook handler */
  async handleCloudinaryWebhook(payload: any): Promise<void> {
    this.logger.log(`Received Cloudinary webhook: ${JSON.stringify(payload)}`);
    const publicId = payload.public_id || payload.asset_id;
    if (!publicId || typeof publicId !== 'string') {
      this.logger.warn('Cloudinary webhook missing public_id');
      return;
    }

    // Match live stream archive pattern: live_stream_<cldId>_archive
    let stream = await this.prisma.liveStream.findFirst({
      where: {
        OR: [
          { dashUrl: publicId },
          { webrtcUrl: { contains: publicId.replace('live_stream_', '').replace('_archive', '') } },
        ],
      },
    });

    if (!stream && publicId.includes('live_stream_')) {
      const match = publicId.match(/live_stream_([a-zA-Z0-9]+)_/);
      if (match) {
        const cldId = match[1];
        stream = await this.prisma.liveStream.findFirst({
          where: {
            webrtcUrl: `cloudinary:${cldId}`,
          },
        });
      }
    }

    if (!stream) {
      this.logger.warn(`No matching live stream found for Cloudinary asset: ${publicId}`);
      return;
    }

    this.logger.log(`Correlated Cloudinary webhook to stream ${stream.id}`);

    // If stream is still marked live, transition to ended
    if (stream.status === LiveStreamStatus.LIVE) {
      const duration = payload.duration ? Number(payload.duration) : undefined;
      await this.repository.endStream(stream.id, duration);
      await this.repository.endStreamSession(stream.id);
    }

    // Update or create recording with the Cloudinary VOD URL
    const vodHlsUrl = `https://res.cloudinary.com/${this.cloudinaryProvider.currentCloudName || 'v6zdpkoh'}/video/upload/sp_hd/${publicId}.m3u8`;
    const recording = await this.prisma.streamRecording.findFirst({
      where: { liveStreamId: stream.id },
      orderBy: { startedAt: 'desc' },
    });

    if (recording) {
      await this.prisma.streamRecording.update({
        where: { id: recording.id },
        data: {
          status: 'READY',
          duration: payload.duration ? Math.round(Number(payload.duration)) : recording.duration,
          hlsUrl: vodHlsUrl,
          fileSize: payload.bytes ? BigInt(payload.bytes) : recording.fileSize,
        },
      });
    } else {
      const rec = await this.repository.createRecording(stream.id);
      await this.prisma.streamRecording.update({
        where: { id: rec.id },
        data: {
          status: 'READY',
          duration: payload.duration ? Math.round(Number(payload.duration)) : 0,
          hlsUrl: vodHlsUrl,
          fileSize: payload.bytes ? BigInt(payload.bytes) : BigInt(0),
        },
      });
    }

    this.logger.log(`Cloudinary live stream ${stream.id} archive recorded as VOD: ${vodHlsUrl}`);
  }
}
