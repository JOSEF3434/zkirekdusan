import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { LiveStreamingRepository } from './live-streaming.repository.js';
import { VideoChannelsRepository } from '../video-channels/video-channels.repository.js';
import { AuthorizationService } from '../authorization/authorization.service.js';
import { CreateStreamDto } from './dto/create-stream.dto.js';
import { UpdateStreamDto } from './dto/update-stream.dto.js';
import { GroupRole } from '../../common/constants/group-roles.js';
import { LiveStreamStatus, Prisma } from '@prisma/client';
import { randomBytes, createHash } from 'crypto';
import slugify from 'slugify';
import { nanoid } from 'nanoid';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class LiveStreamingService {
  private readonly logger = new Logger(LiveStreamingService.name);

  constructor(
    private readonly repository: LiveStreamingRepository,
    private readonly videoChannelsRepository: VideoChannelsRepository,
    private readonly authorizationService: AuthorizationService,
    private readonly configService: ConfigService,
  ) {}

  private generateSlug(title: string): string {
    return `${slugify(title, { lower: true, strict: true })}-${nanoid(6)}`;
  }

  async createStream(userId: string, channelId: string, dto: CreateStreamDto) {
    const channel = await this.videoChannelsRepository.findById(channelId);
    if (!channel) throw new NotFoundException('Video channel not found');

    // Verify stream start permission / group admin
    const hasPermission = await this.authorizationService.hasGroupRole(
      userId,
      channel.groupId,
      GroupRole.MODERATOR,
    );
    if (!hasPermission) {
      throw new ForbiddenException('You do not have permission to create streams in this channel');
    }

    const slug = this.generateSlug(dto.title);
    
    // Determine initial status based on scheduledAt
    const initialStatus = dto.scheduledAt ? LiveStreamStatus.SCHEDULED : LiveStreamStatus.DRAFT;

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
    if (!stream) throw new NotFoundException('Stream not found');

    if (stream.visibility !== 'PUBLIC') {
      if (!userId) throw new ForbiddenException('Authentication required');
      const hasPermission = await this.authorizationService.hasGroupRole(
        userId,
        stream.groupId,
        GroupRole.MEMBER, // Allow group members to see private/group-only streams
      );
      if (!hasPermission) throw new ForbiddenException('Stream is private');
    }

    return stream;
  }

  async updateStream(userId: string, streamId: string, dto: UpdateStreamDto) {
    const stream = await this.repository.getStreamById(streamId);
    if (!stream) throw new NotFoundException('Stream not found');

    const hasPermission = await this.authorizationService.hasGroupRole(
      userId,
      stream.groupId,
      GroupRole.MODERATOR,
    );
    if (!hasPermission) {
      throw new ForbiddenException('You do not have permission to update this stream');
    }

    return this.repository.updateStream(streamId, dto);
  }

  async deleteStream(userId: string, streamId: string) {
    const stream = await this.repository.getStreamById(streamId);
    if (!stream) throw new NotFoundException('Stream not found');

    const hasPermission = await this.authorizationService.hasGroupRole(
      userId,
      stream.groupId,
      GroupRole.MODERATOR,
    );
    if (!hasPermission) {
      throw new ForbiddenException('You do not have permission to delete this stream');
    }

    return this.repository.deleteStream(streamId);
  }

  async getChannelStreams(userId: string | undefined, channelId: string, page = 1, limit = 20) {
    const channel = await this.videoChannelsRepository.findById(channelId);
    if (!channel) throw new NotFoundException('Channel not found');

    const skip = (page - 1) * limit;
    const where: Prisma.LiveStreamWhereInput = { videoChannelId: channelId, deletedAt: null };

    // Basic visibility filter
    if (!userId) {
      where.visibility = 'PUBLIC';
    } else {
      const hasMemberRole = await this.authorizationService.hasGroupRole(
        userId,
        channel.groupId,
        GroupRole.MEMBER,
      );
      if (!hasMemberRole) {
         where.visibility = 'PUBLIC';
      }
    }

    const streams = await this.repository.findStreams({
      where,
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    });

    const total = await this.repository.countStreams(where);

    return { data: streams, total, page, limit };
  }

  // ─── Stream Key Management ──────────────────────────────────────────────

  async generateStreamKey(userId: string, channelId: string) {
    const channel = await this.videoChannelsRepository.findById(channelId);
    if (!channel) throw new NotFoundException('Channel not found');

    const hasPermission = await this.authorizationService.hasGroupRole(
      userId,
      channel.groupId,
      GroupRole.MODERATOR,
    );
    if (!hasPermission) {
      throw new ForbiddenException('You do not have permission to manage stream keys');
    }

    // Generate secure key
    const rawKey = randomBytes(24).toString('hex');
    const keyPrefix = `sk_live_${rawKey.substring(0, 8)}`;
    
    // Hash key for storage
    const keyHash = createHash('sha256').update(rawKey).digest('hex');

    await this.repository.upsertStreamKey(channelId, keyHash, keyPrefix);

    // Only return raw key ONCE upon generation
    return {
      streamKey: rawKey,
      rtmpUrl: this.configService.get<string>('RTMP_SERVER_URL', 'rtmp://localhost:1935/live'),
    };
  }

  // Internal method for RTMP server webhook to validate keys
  async validateStreamKey(key: string): Promise<string | null> {
    const keyHash = createHash('sha256').update(key).digest('hex');
    const streamKey = await this.repository.getStreamKeyByHash(keyHash);
    
    if (!streamKey || !streamKey.isActive) return null;

    // A valid key is active. It maps to the video channel.
    // The RTMP server might want the active LiveStream ID
    const activeStream = streamKey.videoChannel.liveStreams[0]; // Assuming taking the first LIVE one
    if (!activeStream) return null; // Or return channel ID depending on the architecture

    await this.repository.updateStreamKeyUsedAt(streamKey.id);
    return activeStream.id;
  }
}
