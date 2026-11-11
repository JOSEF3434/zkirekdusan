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
import { LiveStreamStatus, GlobalRole, NotificationType } from '@prisma/client';
import { randomBytes, createHash } from 'crypto';
import slugify from 'slugify';
import { nanoid } from 'nanoid';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service.js';
import { StreamProcessingService } from '../stream-processing/stream-processing.service.js';
import { LiveGateway } from '../live-gateway/live.gateway.js';
import { CloudinaryStorageProvider } from '../uploads/providers/cloudinary.provider.js';
import { NotificationsService } from '../notifications/notifications.service.js';
import { forwardRef, Inject, Optional } from '@nestjs/common';
import { MediaMtxService } from './mediamtx.service.js';
import { LiveDvrService } from './live-dvr.service.js';

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
    private readonly notificationsService: NotificationsService,
    private readonly mediaMtx: MediaMtxService,
    @Optional() private readonly liveDvr?: LiveDvrService,
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
   * OR is the group creator, OR is the channel owner.
   */
  private async hasStreamPermission(
    userId: string,
    groupId?: string | null,
    channelId?: string,
  ): Promise<boolean> {
    if (await this.isGlobalAdmin(userId)) return true;
    if (channelId) {
      const channel = await this.prisma.videoChannel.findUnique({
        where: { id: channelId },
        select: { ownerId: true, moderators: { select: { userId: true } } },
      });
      if (channel?.ownerId === userId) return true;
      if (channel?.moderators.some((m) => m.userId === userId)) return true;
    }
    if (!groupId) return false;
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
   * OR is the group creator, OR is the channel owner.
   */
  private async hasStreamAdminPermission(
    userId: string,
    groupId?: string | null,
    channelId?: string,
  ): Promise<boolean> {
    if (await this.isGlobalAdmin(userId)) return true;
    if (channelId) {
      const channel = await this.prisma.videoChannel.findUnique({
        where: { id: channelId },
        select: { ownerId: true },
      });
      if (channel?.ownerId === userId) return true;
    }
    if (!groupId) return false;
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

    if (channel.status === 'PENDING') {
      throw new ForbiddenException('Channel is pending administrator approval and cannot stream yet.');
    }
    if (channel.status === 'REJECTED' || channel.status === 'SUSPENDED' || channel.status === 'DISABLED') {
      throw new ForbiddenException(`Channel is currently ${channel.status.toLowerCase()} and cannot start live streams.`);
    }

    const hasPermission = await this.hasStreamPermission(
      userId,
      channel.groupId,
      channel.id,
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

    const initialTags = [...(dto.tags ?? [])];
    if (dto.notifyAllUsers && !initialTags.includes('notify_all')) {
      initialTags.push('notify_all');
    }

    const stream = await this.repository.createStream({
      videoChannelId: channel.id,
      groupId: channel.groupId ?? null,
      createdById: userId,
      title: dto.title,
      description: dto.description,
      slug,
      status: initialStatus,
      visibility: dto.visibility,
      protocol: dto.protocol,
      scheduledAt: dto.scheduledAt,
      categories: dto.categories ?? [],
      tags: initialTags,
      hashtags: dto.hashtags ?? [],
      thumbnailUrl: dto.thumbnailUrl,
      thumbnailFileId: dto.thumbnailFileId,
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

    // NOTE: no notification is dispatched here intentionally.
    // At this point the stream is in DRAFT/SCHEDULED status — the streamer
    // has not pressed "Go Live" yet. The `notify_all` tag was persisted above
    // (line ~126) so startStream() and the StreamReminderService poller can
    // read it when the stream actually transitions to LIVE.

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
      let hasPermission = false;
      if (stream.groupId) {
        hasPermission = await this.authorizationService.hasGroupRole(
          userId,
          stream.groupId,
          GroupRole.MEMBER,
        );
      } else {
        const isSubbed = await this.prisma.videoSubscription.findUnique({
          where: {
            userId_videoChannelId: {
              userId,
              videoChannelId: stream.videoChannelId,
            },
          },
        });
        hasPermission = !!isSubbed || stream.createdById === userId;
      }
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

    const hasPermission =
      stream.createdById === userId ||
      (await this.hasStreamPermission(userId, stream.groupId, stream.videoChannelId));
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

    const hasPermission =
      stream.createdById === userId ||
      (await this.hasStreamPermission(userId, stream.groupId, stream.videoChannelId));
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
        let hasMemberRole = false;
        if (channel.groupId) {
          hasMemberRole = await this.authorizationService.hasGroupRole(
            userId,
            channel.groupId,
            GroupRole.MEMBER,
          );
        } else {
          hasMemberRole = channel.ownerId === userId;
        }
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

  async getUserStreams(
    currentUserId: string | undefined,
    targetUserId: string,
    page = 1,
    limit = 50,
  ) {
    const skip = (page - 1) * limit;
    const isOwner = currentUserId === targetUserId;
    const isAdmin = currentUserId
      ? await this.isGlobalAdmin(currentUserId)
      : false;

    const where: import('@prisma/client').Prisma.LiveStreamWhereInput = {
      createdById: targetUserId,
      deletedAt: null,
    };

    if (!isOwner && !isAdmin) {
      where.visibility = 'PUBLIC';
      where.status = {
        in: [
          LiveStreamStatus.LIVE,
          LiveStreamStatus.SCHEDULED,
          LiveStreamStatus.ENDED,
        ],
      };
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

  async getLiveStreams(
    userId: string | undefined,
    page = 1,
    limit = 20,
    category?: string,
  ) {
    const skip = (page - 1) * limit;
    const where: import('@prisma/client').Prisma.LiveStreamWhereInput = {
      status: LiveStreamStatus.LIVE,
      deletedAt: null,
      visibility: 'PUBLIC',
      ...(category && category.trim().toLowerCase() !== 'all' && category.trim() !== ''
        ? { categories: { has: category.trim() } }
        : {}),

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

  async getScheduledStreams(
    userId: string | undefined,
    page = 1,
    limit = 20,
    category?: string,
  ) {
    const skip = (page - 1) * limit;
    const where: import('@prisma/client').Prisma.LiveStreamWhereInput = {
      status: LiveStreamStatus.SCHEDULED,
      deletedAt: null,
      visibility: 'PUBLIC',
      scheduledAt: { gt: new Date() },
      ...(category && category.trim().toLowerCase() !== 'all' && category.trim() !== ''
        ? { categories: { has: category.trim() } }
        : {}),
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

  /**
   * GET /streams/:id/whip-session
   *
   * Returns the WHIP ingest endpoint URL for the given stream.
   *
   * Flow:
   *   1. Validates the user has stream permission.
   *   2. Provisions or retrieves the Cloudinary live stream, resolving the
   *      ACTUAL stream key (not just the hashed/stored version).
   *   3. Activates the Cloudinary stream so it is ready when the browser
   *      publishes its WHIP SDP offer.
   *   4. Registers a per-session path on MediaMTX via its REST API, embedding
   *      the exact Cloudinary RTMP destination in the runOnAvailable FFmpeg cmd.
   *   5. Returns whipUrl, rtmpDestination (for debugging), and streamKey.
   */
  private async assertAuthorizedActiveStream(
    userId: string,
    streamId: string,
    actionVerb: string,
  ) {
    const stream = await this.repository.getStreamById(streamId);
    if (!stream || stream.deletedAt) {
      throw new NotFoundException('Stream not found');
    }

    const hasPermission = await this.hasStreamPermission(
      userId,
      stream.groupId,
      stream.videoChannelId,
    );
    if (!hasPermission) {
      throw new ForbiddenException(
        `You do not have permission to ${actionVerb} this stream`,
      );
    }

    if (
      stream.status === LiveStreamStatus.ENDED ||
      stream.status === LiveStreamStatus.CANCELLED
    ) {
      throw new BadRequestException(
        `Cannot ${actionVerb} an ended or cancelled stream`,
      );
    }

    return stream;
  }

  /**
   * Provision (or reuse), activate, and synchronize Cloudinary live-stream
   * metadata onto the PostgreSQL LiveStream record. Single source of truth for
   * prepareIngest(), getWhipSession(), and startStream().
   */
  private async provisionAndActivateCloudinaryStream(stream: any): Promise<{
    cldStreamId: string;
    streamKey: string;
    rtmpIngestUrl: string;
    hlsUrl: string;
    archivePublicId: string;
    streamKeyRecordId?: string;
  }> {
    let streamKeyRecord = await this.repository.getStreamKeyByChannelId(
      stream.videoChannelId,
    );

    const existingCldId = stream.webrtcUrl?.startsWith('cloudinary:')
      ? stream.webrtcUrl.replace('cloudinary:', '')
      : streamKeyRecord?.keyPrefix?.startsWith('cld_')
        ? streamKeyRecord.keyPrefix.substring(4)
        : null;

    let cldStreamId: string | undefined;
    let activeStreamKey: string | undefined;
    let rtmpIngestUrl = 'rtmp://live.cloudinary.com/streams';
    let hlsUrl: string | undefined;
    let archivePublicId: string | undefined;
    let alreadyActive = false;

    if (existingCldId) {
      const cldData =
        await this.cloudinaryProvider.getLiveStream(existingCldId);
      if (cldData?.input?.stream_key) {
        cldStreamId = existingCldId;
        activeStreamKey = cldData.input.stream_key as string;
        alreadyActive = cldData.status === 'active';
        const existingHlsOutput = cldData.outputs?.find(
          (o: any) => o.type === 'hls',
        );
        hlsUrl =
          existingHlsOutput?.uri ||
          `https://res.cloudinary.com/${this.cloudinaryProvider.currentCloudName}/video/live/live_stream_${cldStreamId}_hls.m3u8`;
        archivePublicId = `live_stream_${cldStreamId}_archive`;
        rtmpIngestUrl = (cldData.input?.uri as string) || rtmpIngestUrl;
      } else {
        this.logger.warn(
          `[Cloudinary] Stream ${existingCldId} unavailable on active cloud=${this.cloudinaryProvider.currentCloudName} — will provision fresh stream.`,
        );
      }
    }

    if (!cldStreamId || !activeStreamKey) {
      const safeSlug = (stream.slug || stream.id).replace(
        /[^a-zA-Z0-9_-]/g,
        '_',
      );
      const archiveEnabled = stream.isRecordingEnabled ?? true;
      this.logger.log(
        `[LiveStreamingService] Provisioning Cloudinary live stream: ` +
          `streamId=${stream.id}, cloud=${this.cloudinaryProvider.currentCloudName}, archiveEnabled=${archiveEnabled}`,
      );
      const cld = await this.cloudinaryProvider.createLiveStream(
        `stream_${safeSlug}_${Date.now()}`,
        { archiveEnabled },
      );
      cldStreamId = cld.id;
      activeStreamKey = cld.streamKey;
      rtmpIngestUrl = cld.rtmpIngestUrl || rtmpIngestUrl;
      hlsUrl = cld.hlsUrl;
      archivePublicId = cld.archivePublicId;
      alreadyActive = false;

      const keyHash = createHash('sha256')
        .update(activeStreamKey)
        .digest('hex');
      streamKeyRecord = await this.repository.upsertStreamKey(
        stream.videoChannelId,
        keyHash,
        `cld_${cldStreamId}`,
      );
    }

    if (!alreadyActive) {
      await this.cloudinaryProvider.activateLiveStream(cldStreamId);
      if (!activeStreamKey) {
        const cldData =
          await this.cloudinaryProvider.getLiveStream(cldStreamId);
        activeStreamKey = cldData?.input?.stream_key;
      }
    }

    if (!activeStreamKey) {
      throw new BadRequestException(
        'Could not obtain Cloudinary stream key. Please retry in a moment.',
      );
    }

    await this.prisma.liveStream.update({
      where: { id: stream.id },
      data: {
        hlsUrl,
        rtmpIngestUrl,
        webrtcUrl: `cloudinary:${cldStreamId}`,
        dashUrl: archivePublicId,
      },
    });

    return {
      cldStreamId,
      streamKey: activeStreamKey,
      rtmpIngestUrl,
      hlsUrl: hlsUrl!,
      archivePublicId: archivePublicId!,
      streamKeyRecordId: streamKeyRecord?.id,
    };
  }

  /**
   * Prepare Cloudinary/RTMP ingest credentials without prematurely setting
   * LiveStream.status = LIVE. Clients can connect RTMP/WHIP first, then invoke
   * go-live once transport media is flowing.
   */
  async prepareIngest(userId: string, streamId: string) {
    const stream = await this.assertAuthorizedActiveStream(
      userId,
      streamId,
      'prepare',
    );

    let activeStreamKey: string | undefined;
    if (this.cloudinaryProvider?.configured) {
      const cld = await this.provisionAndActivateCloudinaryStream(stream);
      activeStreamKey = cld.streamKey;
    } else {
      const rtmpUrl = stream.rtmpIngestUrl || this.getRtmpServerUrl();
      await this.prisma.liveStream.update({
        where: { id: streamId },
        data: { rtmpIngestUrl: rtmpUrl },
      });
    }

    const refreshed = await this.repository.getStreamById(streamId);
    return {
      ...refreshed,
      streamKey: activeStreamKey,
    };
  }

  /**
   * Roll back an aborted or failed broadcast attempt before media started
   * flowing so streams never remain stuck in a ghost LIVE state.
   */
  async abortStart(userId: string, streamId: string, reason?: string) {
    const stream = await this.repository.getStreamById(streamId);
    if (!stream || stream.deletedAt) {
      throw new NotFoundException('Stream not found');
    }

    const hasPermission = await this.hasStreamPermission(
      userId,
      stream.groupId,
      stream.videoChannelId,
    );
    if (!hasPermission) {
      throw new ForbiddenException(
        'You do not have permission to abort this stream',
      );
    }

    if (
      stream.status === LiveStreamStatus.ENDED ||
      stream.status === LiveStreamStatus.CANCELLED
    ) {
      return { aborted: false, status: stream.status };
    }

    const cldStreamId = stream.webrtcUrl?.startsWith('cloudinary:')
      ? stream.webrtcUrl.replace('cloudinary:', '')
      : null;

    if (cldStreamId) {
      if (this.cloudinaryProvider?.configured) {
        await this.cloudinaryProvider.idleLiveStream(cldStreamId);
      }
      await this.mediaMtx.removeBroadcastPath(cldStreamId);
    }

    let nextStatus = stream.status;
    if (stream.status === LiveStreamStatus.LIVE) {
      const revertStatus = stream.scheduledAt
        ? LiveStreamStatus.SCHEDULED
        : LiveStreamStatus.DRAFT;
      await this.prisma.liveStream.update({
        where: { id: streamId },
        data: {
          status: revertStatus,
          startedAt: null,
          endedAt: null,
        },
      });
      await this.repository.endStreamSession(streamId);
      this.liveGateway.clearBroadcasterSession(streamId);
      this.liveGateway.broadcastStreamEnded(streamId, undefined, 0);
      nextStatus = revertStatus;
    }

    await this.liveDvr?.stopAndPurge(streamId);

    this.logger.warn(
      `[LiveStreamingService] Aborted stream start for ${streamId} ` +
        `(previous=${stream.status}, next=${nextStatus}, reason=${reason || 'unspecified'})`,
    );

    return { aborted: true, status: nextStatus };
  }

  /**
   * Inspect real ingest health across PostgreSQL, Cloudinary, and MediaMTX.
   */
  async getIngestStatus(userId: string, streamId: string) {
    const stream = await this.repository.getStreamById(streamId);
    if (!stream || stream.deletedAt) {
      throw new NotFoundException('Stream not found');
    }

    const hasPermission = await this.hasStreamPermission(
      userId,
      stream.groupId,
      stream.videoChannelId,
    );
    if (!hasPermission) {
      throw new ForbiddenException(
        'You do not have permission to inspect this stream',
      );
    }

    const cldStreamId = stream.webrtcUrl?.startsWith('cloudinary:')
      ? stream.webrtcUrl.replace('cloudinary:', '')
      : null;

    const [cldData, mtxStatus] = await Promise.all([
      cldStreamId && this.cloudinaryProvider?.configured
        ? this.cloudinaryProvider.getLiveStream(cldStreamId)
        : Promise.resolve(null),
      cldStreamId ? this.mediaMtx.getPathStatus(cldStreamId) : Promise.resolve(null),
    ]);

    const cldStatus: string | null = cldData?.status ?? null;
    let stage = 'unprovisioned';
    if (cldStreamId) {
      if (mtxStatus?.exists && mtxStatus.ready && mtxStatus.bytesReceived > 0) {
        stage = 'mediamtx_ingesting';
      } else if (cldStatus === 'active' && stream.status === LiveStreamStatus.LIVE) {
        stage = 'cloudinary_active_live';
      } else if (cldStatus === 'active') {
        stage = 'cloudinary_ready';
      } else {
        stage = 'cloudinary_activating';
      }
    }

    return {
      streamId,
      dbStatus: stream.status,
      hlsUrl: stream.hlsUrl,
      stage,
      cloudinary: cldStreamId
        ? {
            streamId: cldStreamId,
            status: cldStatus ?? 'unknown',
            cloudName: this.cloudinaryProvider?.currentCloudName || null,
          }
        : null,
      mediaMtx: mtxStatus,
    };
  }

  // ─── Live DVR Playback Access & Manifests ────────────────────────────────

  async getDvrTimeline(userId: string | undefined, streamId: string) {
    const stream = await this.getStreamById(userId, streamId);
    if (!this.liveDvr) {
      return {
        streamId,
        dvrEnabled: false,
        active: false,
        ended: stream.status === LiveStreamStatus.ENDED,
        hasSegments: false,
        dvrWindowSeconds: 1800,
        retentionMinutes: 30,
        targetDurationSec: 4,
        dvrStartOffsetSec: 0,
        liveEdgeOffsetSec: 0,
        retainedDurationSec: 0,
        segmentCount: 0,
        serverNowIso: new Date().toISOString(),
        streamStartedAtIso: stream.startedAt?.toISOString() ?? null,
        masterPlaylistPath: `/api/streams/${streamId}/dvr/master.m3u8`,
        variants: [],
      };
    }

    if (
      stream.status === LiveStreamStatus.LIVE &&
      stream.isDvrEnabled &&
      stream.hlsUrl
    ) {
      await this.liveDvr.ensureRecording(
        streamId,
        stream.hlsUrl,
        stream.startedAt ?? new Date(),
        true,
      );
    }

    const playbackToken =
      stream.visibility !== 'PUBLIC'
        ? this.liveDvr.createPlaybackToken(streamId)
        : undefined;

    return this.liveDvr.getTimelineMetadata(streamId, { playbackToken });
  }

  async assertDvrPlaybackAuthorized(
    userId: string | undefined,
    streamId: string,
    dvrToken?: string,
  ): Promise<string | undefined> {
    const stream = await this.repository.getStreamById(streamId);
    if (!stream || stream.deletedAt) {
      throw new NotFoundException('Stream not found');
    }
    if (stream.visibility === 'PUBLIC') {
      return undefined;
    }
    if (dvrToken && this.liveDvr?.verifyPlaybackToken(streamId, dvrToken)) {
      return dvrToken;
    }
    await this.getStreamById(userId, streamId);
    return this.liveDvr?.createPlaybackToken(streamId);
  }

  async getDvrMasterPlaylist(
    userId: string | undefined,
    streamId: string,
    dvrToken?: string,
  ): Promise<string | null> {
    const effectiveToken = await this.assertDvrPlaybackAuthorized(
      userId,
      streamId,
      dvrToken,
    );
    return (
      this.liveDvr?.buildMasterPlaylist(streamId, effectiveToken) ?? null
    );
  }

  async getDvrVariantPlaylist(
    userId: string | undefined,
    streamId: string,
    variantId: number,
    dvrToken?: string,
  ): Promise<string | null> {
    const effectiveToken = await this.assertDvrPlaybackAuthorized(
      userId,
      streamId,
      dvrToken,
    );
    return (
      this.liveDvr?.buildVariantPlaylist(streamId, variantId, effectiveToken) ??
      null
    );
  }

  async getDvrSegmentFile(
    userId: string | undefined,
    streamId: string,
    variantId: number,
    filename: string,
    dvrToken?: string,
  ) {
    await this.assertDvrPlaybackAuthorized(userId, streamId, dvrToken);
    if (!this.liveDvr) {
      return { status: 'NOT_FOUND' as const };
    }
    return this.liveDvr.resolveSegmentFile(streamId, variantId, filename);
  }

  async getWhipSession(
    userId: string,
    streamId: string,
  ): Promise<{ whipUrl: string; streamKey: string; rtmpUrl: string; rtmpDestination: string }> {
    const stream = await this.assertAuthorizedActiveStream(
      userId,
      streamId,
      'stream',
    );

    const whipGatewayBase =
      this.configService.get<string>('WHIP_GATEWAY_URL')?.replace(/\/$/, '') ?? '';

    if (!whipGatewayBase) {
      throw new BadRequestException(
        'WHIP_GATEWAY_URL is not configured. ' +
          'Deploy MediaMTX and set WHIP_GATEWAY_URL in the backend environment.',
      );
    }

    const cld = await this.provisionAndActivateCloudinaryStream(stream);
    const whipPath = cld.cldStreamId;
    const whipUrl = `${whipGatewayBase}/${whipPath}/whip`;
    const rtmpDestination = `${cld.rtmpIngestUrl.replace(/\/$/, '')}/${cld.streamKey}`;

    await this.mediaMtx.registerBroadcastPath(whipPath, {
      rtmpDestination,
    });

    this.logger.log(
      `[WHIP] Session ready: stream=${streamId} path=${whipPath} ` +
        `rtmpDest=${cld.rtmpIngestUrl.replace(/\/$/, '')}/<key>`,
    );

    return {
      whipUrl,
      streamKey: cld.streamKey,
      rtmpUrl: cld.rtmpIngestUrl,
      rtmpDestination,
    };
  }

  async startStream(userId: string, streamId: string) {
    const stream = await this.assertAuthorizedActiveStream(
      userId,
      streamId,
      'start',
    );

    const streamKey = await this.repository.getStreamKeyByChannelId(
      stream.videoChannelId,
    );
    let rtmpIngestUrl = stream.rtmpIngestUrl || this.getRtmpServerUrl();
    let activeStreamKey: string | null = null;
    let streamKeyId: string | undefined = streamKey?.id;

    if (this.cloudinaryProvider?.configured) {
      try {
        const cld = await this.provisionAndActivateCloudinaryStream(stream);
        rtmpIngestUrl = cld.rtmpIngestUrl;
        activeStreamKey = cld.streamKey;
        streamKeyId = cld.streamKeyRecordId ?? streamKeyId;
      } catch (err: any) {
        this.logger.error(
          `Error provisioning Cloudinary live stream: ${err.message}`,
          err.stack,
        );
        throw new BadRequestException(
          `Failed to provision live stream: ${err.message}`,
        );
      }
    }

    const updatedStream = await this.repository.startStream(
      streamId,
      rtmpIngestUrl,
    );

    // Begin buffering upstream HLS segments for 30-min live DVR rewind without
    // altering RTMP ingest or blocking the broadcaster.
    if (updatedStream.isDvrEnabled && updatedStream.hlsUrl) {
      void this.liveDvr?.ensureRecording(
        streamId,
        updatedStream.hlsUrl,
        updatedStream.startedAt ?? new Date(),
        true,
      );
    }

    // Create a stream session for tracking
    await this.repository.createStreamSession(streamId, streamKeyId);

    // Create chat room if chat is enabled
    if (stream.isChatEnabled) {
      await this.prisma.streamChatRoom.upsert({
        where: { liveStreamId: streamId },
        create: { liveStreamId: streamId },
        update: {},
      });
    }

    // Clear any pending broadcaster interruption timer (reconnect path)
    this.liveGateway.clearBroadcasterSession(streamId);

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

    // Follower/subscriber notification is intentionally NOT fired here.
    // StreamReminderService polls every 60 s and fires the notification only
    // once the stream has been LIVE for ≥ 2 minutes — preventing notifications
    // for test streams that start and immediately end.
    // Guard column: live_streams.notified_live_at (set once, never reset).

    return {
      ...updatedStream,
      streamKey: activeStreamKey || undefined,
    };
  }


  async endStream(userId: string, streamId: string) {
    const stream = await this.repository.getStreamById(streamId);
    if (!stream || stream.deletedAt)
      throw new NotFoundException('Stream not found');

    if (stream.status !== LiveStreamStatus.LIVE) {
      if (stream.status === LiveStreamStatus.ENDED) {
        return stream;
      }
      throw new BadRequestException('Stream is not currently live');
    }

    const hasPermission = await this.hasStreamPermission(
      userId,
      stream.groupId,
      stream.videoChannelId,
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
    this.liveDvr?.markStreamEnded(streamId);

    // Cloudinary Live Stream idle
    if (this.cloudinaryProvider?.configured) {
      const cldStreamId = stream.webrtcUrl?.replace('cloudinary:', '');
      if (cldStreamId) {
        await this.cloudinaryProvider.idleLiveStream(cldStreamId);

        // Clean up the dynamically-registered MediaMTX broadcast path
        // so stale runOnAvailable hooks don't fire on future sessions.
        await this.mediaMtx.removeBroadcastPath(cldStreamId);
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
          ? `https://res.cloudinary.com/${this.cloudinaryProvider.currentCloudName}/video/upload/sp_hd/${stream.dashUrl}.m3u8`
          : (stream.hlsUrl ??
            `${appUrl}/uploads/streams/${streamId}/index.m3u8`);

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
        this.logger.warn(
          `Could not enqueue recording job for stream ${streamId}: ${err}`,
        );
      }
    }

    this.logger.log(
      `Stream ${streamId} ended by user ${userId}, duration: ${duration?.toFixed(0)}s`,
    );

    // Clear broadcaster session and any pending grace-period timer immediately.
    // This must happen BEFORE broadcastStreamEnded so the timer doesn't race.
    this.liveGateway.clearBroadcasterSession(streamId);

    // Broadcast stream ended to LiveGateway (passes vodUrl once available)
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
      stream.videoChannelId,
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
      const fallbackHlsUrl =
        stream.hlsUrl ?? `${appUrl}/uploads/streams/${streamId}/index.m3u8`;
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
    if (
      (!playbackUrl || playbackUrl.includes('/uploads/')) &&
      cldArchivePublicId &&
      this.cloudinaryProvider?.configured
    ) {
      playbackUrl = `https://res.cloudinary.com/${this.cloudinaryProvider.currentCloudName}/video/upload/sp_hd/${cldArchivePublicId}.m3u8`;
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
        description:
          stream.description ?? `Recorded live stream: ${stream.title}`,
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

    this.logger.log(
      `VOD published for stream ${streamId} by user ${userId}. Video ID: ${video.id}`,
    );
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
      channel.id,
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
    if (
      key.keyPrefix?.startsWith('cld_') &&
      this.cloudinaryProvider?.configured
    ) {
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
      channel.id,
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
        const safeName = `channel_${(channel.handle || channel.id).replace(/[^a-zA-Z0-9_-]/g, '_')}_${Date.now()}`;
        const cld = await this.cloudinaryProvider.createLiveStream(safeName, {
          archiveEnabled: true,
        });
        rawKey = cld.streamKey;
        rtmpUrl = cld.rtmpIngestUrl || this.getRtmpServerUrl();
        const keyPrefix = `cld_${cld.id}`;
        const keyHash = createHash('sha256').update(rawKey).digest('hex');
        await this.repository.upsertStreamKey(channelId, keyHash, keyPrefix);
      } catch (err: any) {
        this.logger.error(
          `Cloudinary live stream creation failed: ${err?.message || err}`,
          err.stack,
        );
        throw new BadRequestException(
          `Failed to generate Cloudinary stream key: ${err?.message || err}`,
        );
      }
    } else {
      throw new BadRequestException(
        'Cloudinary live streaming provider is not configured. Real streaming credentials are required.',
      );
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
      this.logger.warn(
        `Invalid or inactive stream key used: ${streamKeyName.substring(0, 8)}...`,
      );
      throw new ForbiddenException('Invalid stream key');
    }

    await this.repository.updateStreamKeyUsedAt(streamKey.id);

    const activeLiveStream = streamKey.videoChannel?.liveStreams?.[0];
    if (activeLiveStream) {
      try {
        // Start the stream
        await this.startStream(
          activeLiveStream.createdById,
          activeLiveStream.id,
        );

        this.logger.log(
          `Nginx-RTMP on_publish authorized for stream ${activeLiveStream.id}`,
        );
      } catch (err: any) {
        if (err instanceof ConflictException) {
          this.logger.log(
            `Stream ${activeLiveStream.id} is already LIVE (Reconnect detected)`,
          );
          // Record a new session for the reconnect
          await this.repository.createStreamSession(
            activeLiveStream.id,
            streamKey.id,
          );
        } else {
          throw err;
        }
      }
    } else {
      this.logger.warn(
        `Valid stream key but no active LIVE stream configured for channel ${streamKey.videoChannelId}`,
      );
      // In a real system you might auto-create a stream, but here we require one to be created first
      throw new ForbiddenException(
        'No active stream configured for this channel',
      );
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
      this.logger.log(
        `Nginx-RTMP on_done handled for stream ${activeLiveStream.id}`,
      );
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
          {
            webrtcUrl: {
              contains: publicId
                .replace('live_stream_', '')
                .replace('_archive', ''),
            },
          },
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
      this.logger.warn(
        `No matching live stream found for Cloudinary asset: ${publicId}`,
      );
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
    const vodHlsUrl = `https://res.cloudinary.com/${this.cloudinaryProvider.currentCloudName}/video/upload/sp_hd/${publicId}.m3u8`;
    const recording = await this.prisma.streamRecording.findFirst({
      where: { liveStreamId: stream.id },
      orderBy: { startedAt: 'desc' },
    });

    if (recording) {
      await this.prisma.streamRecording.update({
        where: { id: recording.id },
        data: {
          status: 'READY',
          duration: payload.duration
            ? Math.round(Number(payload.duration))
            : recording.duration,
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

    this.logger.log(
      `Cloudinary live stream ${stream.id} archive recorded as VOD: ${vodHlsUrl}`,
    );
  }

  private async sendStreamNotification(params: {
    stream: any;
    channel: any;
    isScheduled: boolean;
    notifyAll: boolean;
  }) {
    const channelName = params.channel?.name ?? 'Live Creator';
    const title = params.isScheduled
      ? `📅 New Scheduled Live: ${params.stream.title}`
      : `🔴 New Live Stream: ${params.stream.title}`;
    const body = params.isScheduled
      ? `${channelName} scheduled a live stream for ${params.stream.scheduledAt ? new Date(params.stream.scheduledAt).toLocaleString() : 'soon'}. Tap to set reminder!`
      : `${channelName} has started a new live broadcast. Tap to watch!`;

    if (params.notifyAll) {
      await this.notificationsService.notifyAllUsers({
        title,
        body,
        type: NotificationType.SYSTEM,
        data: {
          streamId: params.stream.id,
          action: params.isScheduled ? 'LIVE_STREAM_SCHEDULED' : 'LIVE_STREAM_CREATED',
          scheduledAt: params.stream.scheduledAt
            ? new Date(params.stream.scheduledAt).toISOString()
            : undefined,
        },
      });
      this.logger.log(
        `Broadcasted stream notification to ALL users for stream ${params.stream.id}`,
      );
    } else {
      // Scoped only to channel followers & group members
      const subscribers = await this.prisma.videoSubscription.findMany({
        where: { videoChannelId: params.channel.id },
        select: { userId: true },
      });
      const members = await this.prisma.groupMember.findMany({
        where: { groupId: params.channel.groupId },
        select: { userId: true },
      });
      const targetUserIds = Array.from(
        new Set([
          ...subscribers.map((s) => s.userId),
          ...members.map((m) => m.userId),
        ]),
      );

      for (const uid of targetUserIds) {
        await this.notificationsService
          .create({
            userId: uid,
            type: NotificationType.SYSTEM,
            title,
            body,
            data: {
              streamId: params.stream.id,
              action: params.isScheduled ? 'LIVE_STREAM_SCHEDULED' : 'LIVE_STREAM_CREATED',
              scheduledAt: params.stream.scheduledAt
                ? new Date(params.stream.scheduledAt).toISOString()
                : undefined,
            },
          })
          .catch(() => null);
      }
      this.logger.log(
        `Dispatched stream notification to ${targetUserIds.length} followers/members for stream ${params.stream.id}`,
      );
    }
  }

  private async sendStreamStartedNotification(stream: any, isNotifyAll: boolean) {
    const channelName = stream.videoChannel?.name ?? 'Creator';
    const title = `🔴 ${channelName} is LIVE NOW!`;
    const body = `"${stream.title}" is streaming live. Tap to join now!`;

    if (isNotifyAll) {
      await this.notificationsService.notifyAllUsers({
        title,
        body,
        type: NotificationType.SYSTEM,
        data: {
          streamId: stream.id,
          action: 'LIVE_STREAM_STARTED',
        },
      });
      this.logger.log(
        `Dispatched stream started broadcast to ALL users for stream ${stream.id}`,
      );
    } else {
      const subscribers = await this.prisma.videoSubscription.findMany({
        where: { videoChannelId: stream.videoChannelId },
        select: { userId: true },
      });
      const members = await this.prisma.groupMember.findMany({
        where: { groupId: stream.groupId },
        select: { userId: true },
      });
      const targetUserIds = Array.from(
        new Set([
          ...subscribers.map((s) => s.userId),
          ...members.map((m) => m.userId),
        ]),
      );

      for (const uid of targetUserIds) {
        await this.notificationsService
          .create({
            userId: uid,
            type: NotificationType.SYSTEM,
            title,
            body,
            data: {
              streamId: stream.id,
              action: 'LIVE_STREAM_STARTED',
            },
          })
          .catch(() => null);
      }
      this.logger.log(
        `Dispatched stream started notification to ${targetUserIds.length} followers/members for stream ${stream.id}`,
      );
    }
  }
}

