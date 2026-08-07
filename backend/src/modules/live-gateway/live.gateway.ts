import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Logger, UsePipes, ValidationPipe, OnModuleDestroy } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { StreamChatService } from '../stream-chat/stream-chat.service.js';
import { StreamAnalyticsService } from '../stream-analytics/stream-analytics.service.js';
import { StreamChatRepository } from '../stream-chat/stream-chat.repository.js';
import { PrismaService } from '../../prisma/prisma.service.js';
import { StreamChatMessageType } from '@prisma/client';

export const LIVE_EVENTS = {
  // Client → Server
  JOIN_STREAM: 'stream:join',
  LEAVE_STREAM: 'stream:leave',
  SEND_CHAT: 'chat:send',
  REACT_CHAT: 'chat:react',
  DELETE_CHAT: 'chat:delete',
  PIN_CHAT: 'chat:pin',
  POLL_VOTE: 'poll:vote',
  SEND_REACTION: 'reaction:send',
  STREAM_REPORT: 'stream:report',
  QUALITY_REPORT: 'quality:report',

  // Server → Client
  STREAM_STARTED: 'stream:started',
  STREAM_ENDED: 'stream:ended',
  STREAM_UPDATED: 'stream:updated',
  STREAM_ERROR: 'stream:error',
  CHAT_MESSAGE: 'chat:message',
  CHAT_DELETED: 'chat:deleted',
  CHAT_PINNED: 'chat:pinned',
  CHAT_REACTION: 'chat:reaction',
  VIEWER_COUNT: 'viewer:count',
  POLL_CREATED: 'poll:created',
  POLL_UPDATED: 'poll:updated',
  POLL_ENDED: 'poll:ended',
  REACTION_BROADCAST: 'reaction:broadcast',
  MOD_MUTED: 'mod:muted',
  MOD_BANNED: 'mod:banned',
  QUALITY_RECOMMEND: 'quality:recommend',
  ERROR: 'error',
} as const;

interface ViewerSession {
  userId: string;
  streamId: string;
  viewerId: string;
  joinedAt: number;
}

interface RateLimit {
  count: number;
  windowStart: number;
}

const CHAT_RATE_LIMIT = { max: 10, windowMs: 10_000 }; // 10 messages per 10 seconds
const REACTION_RATE_LIMIT = { max: 20, windowMs: 5_000 }; // 20 reactions per 5 seconds

@WebSocketGateway({
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true,
  },
  namespace: '/live',
})
export class LiveGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect, OnModuleDestroy
{
  @WebSocketServer() declare server: Server;
  private readonly logger = new Logger(LiveGateway.name);

  // Map of viewer session records: socketId → session
  private readonly viewerSessions = new Map<string, ViewerSession>();
  // Rate limiting: userId:type → RateLimit
  private readonly rateLimits = new Map<string, RateLimit>();
  
  // Quality reports aggregation: streamId -> bandwidth array
  private readonly qualityReports = new Map<string, number[]>();
  private healthBroadcastInterval: NodeJS.Timeout | null = null;

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly streamChatService: StreamChatService,
    private readonly streamAnalyticsService: StreamAnalyticsService,
    private readonly streamChatRepo: StreamChatRepository,
    private readonly prisma: PrismaService,
  ) {}

  afterInit(_server: Server) {
    this.logger.log('📡 LiveGateway initialized on /live namespace');
    
    // Broadcast stream health every 30 seconds
    this.healthBroadcastInterval = setInterval(() => {
      this.broadcastStreamHealth();
    }, 30000);
  }

  onModuleDestroy() {
    if (this.healthBroadcastInterval) {
      clearInterval(this.healthBroadcastInterval);
    }
  }

  private broadcastStreamHealth() {
    for (const [streamId, bandwidths] of this.qualityReports.entries()) {
      if (bandwidths.length === 0) continue;
      
      const avgBandwidth = bandwidths.reduce((a, b) => a + b, 0) / bandwidths.length;
      const sorted = [...bandwidths].sort((a, b) => a - b);
      const p50 = sorted[Math.floor(sorted.length * 0.5)];
      const p95 = sorted[Math.floor(sorted.length * 0.95)];
      
      let health = 'GOOD';
      if (p50 < 1000) health = 'POOR';
      else if (p50 < 2500) health = 'FAIR';

      // Emit to stream room (frontend should restrict this view to mods/broadcaster)
      this.server.to(`stream:${streamId}`).emit('stream:health', {
        streamId,
        health,
        avgBandwidth,
        p50,
        p95,
        reportsCount: bandwidths.length,
        timestamp: Date.now(),
      });
      
      // Clear reports for next window
      this.qualityReports.set(streamId, []);
    }
  }

  handleConnection(client: Socket) {
    try {
      const userId = this.authenticateSocket(client);
      client.data.userId = userId ?? null;
      this.logger.debug(
        `Client connected to /live: ${client.id} (User: ${userId ?? 'guest'})`,
      );
    } catch {
      client.data.userId = null;
      this.logger.debug(`Unauthenticated client connected: ${client.id}`);
    }
  }

  async handleDisconnect(client: Socket) {
    this.logger.debug(`Client disconnected: ${client.id}`);
    const session = this.viewerSessions.get(client.id);

    if (session) {
      const durationSec = Math.floor((Date.now() - session.joinedAt) / 1000);
      try {
        await this.streamAnalyticsService.trackViewerLeave(
          session.viewerId,
          durationSec,
        );
        const count = await this.getRoomViewerCount(session.streamId);
        this.server
          .to(`stream:${session.streamId}`)
          .emit(LIVE_EVENTS.VIEWER_COUNT, {
            streamId: session.streamId,
            count,
          });
      } catch (e) {
        this.logger.error('Error tracking viewer leave on disconnect', e);
      }
      this.viewerSessions.delete(client.id);
    }

    // Clean up rate limits
    this.cleanupRateLimits(client.data.userId as string | null);
  }

  // ─── Auth ────────────────────────────────────────────────────────────────

  private authenticateSocket(client: Socket): string | null {
    const token = this.extractToken(client);
    if (!token) return null;
    try {
      const payload = this.jwtService.verify(token, {
        secret: this.configService.get<string>('JWT_ACCESS_SECRET'),
      });
      return payload.sub as string;
    } catch {
      return null;
    }
  }


  private extractToken(client: Socket): string | null {
    const authHeader = client.handshake.headers.authorization;
    if (authHeader?.startsWith('Bearer ')) return authHeader.substring(7);
    const queryToken = client.handshake.query.token;
    if (typeof queryToken === 'string') return queryToken;
    return null;
  }

  // ─── Rate Limiting ────────────────────────────────────────────────────────

  private checkRateLimit(userId: string, type: 'chat' | 'reaction'): boolean {
    const key = `${userId}:${type}`;
    const limits = type === 'chat' ? CHAT_RATE_LIMIT : REACTION_RATE_LIMIT;
    const now = Date.now();

    const current = this.rateLimits.get(key);
    if (!current || now - current.windowStart > limits.windowMs) {
      this.rateLimits.set(key, { count: 1, windowStart: now });
      return true;
    }
    if (current.count >= limits.max) return false;
    current.count++;
    return true;
  }

  private cleanupRateLimits(userId: string | null) {
    if (!userId) return;
    this.rateLimits.delete(`${userId}:chat`);
    this.rateLimits.delete(`${userId}:reaction`);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  private async getRoomViewerCount(streamId: string): Promise<number> {
    const sockets = await this.server.in(`stream:${streamId}`).fetchSockets();
    return sockets.length;
  }

  /** Broadcast stream started event to all users */
  broadcastStreamStarted(streamId: string, stream: object) {
    this.server
      .to(`stream:${streamId}`)
      .emit(LIVE_EVENTS.STREAM_STARTED, stream);
  }

  /** Broadcast stream ended event to all users */
  broadcastStreamEnded(streamId: string, vodUrl?: string, duration?: number) {
    this.server.to(`stream:${streamId}`).emit(LIVE_EVENTS.STREAM_ENDED, {
      streamId,
      vodUrl,
      duration,
    });
    this.qualityReports.delete(streamId);
  }

  /** Broadcast stream updated metadata */
  broadcastStreamUpdated(streamId: string, stream: object) {
    this.server
      .to(`stream:${streamId}`)
      .emit(LIVE_EVENTS.STREAM_UPDATED, stream);
  }

  /** Send moderation event to specific user */
  sendModerationEvent(streamId: string, event: string, data: object) {
    this.server.to(`stream:${streamId}`).emit(event, data);
  }

  // ─── Client → Server Events ──────────────────────────────────────────────

  @SubscribeMessage(LIVE_EVENTS.JOIN_STREAM)
  async handleJoinStream(
    @ConnectedSocket() client: Socket,
    @MessageBody('streamId') streamId: string,
  ) {
    if (!streamId) return;

    await client.join(`stream:${streamId}`);

    if (client.data.userId) {
      try {
        const viewer = await this.streamAnalyticsService.trackViewerJoin(
          streamId,
          client.data.userId as string,
        );
        this.viewerSessions.set(client.id, {
          userId: client.data.userId as string,
          streamId,
          viewerId: viewer.id,
          joinedAt: Date.now(),
        });
      } catch {
        this.logger.warn(
          `Failed to track viewer join for ${client.data.userId as string}`,
        );
      }
    }

    const count = await this.getRoomViewerCount(streamId);
    if (client.data.userId) {
      this.streamAnalyticsService
        .updateCurrentViewers(streamId, count, count)
        .catch(() => null);
    }

    this.server
      .to(`stream:${streamId}`)
      .emit(LIVE_EVENTS.VIEWER_COUNT, { streamId, count });
  }

  @SubscribeMessage(LIVE_EVENTS.LEAVE_STREAM)
  async handleLeaveStream(
    @ConnectedSocket() client: Socket,
    @MessageBody('streamId') streamId: string,
  ) {
    if (!streamId) return;

    await client.leave(`stream:${streamId}`);

    const session = this.viewerSessions.get(client.id);
    if (session && session.streamId === streamId) {
      const durationSec = Math.floor((Date.now() - session.joinedAt) / 1000);
      try {
        await this.streamAnalyticsService.trackViewerLeave(
          session.viewerId,
          durationSec,
        );
      } catch {
        // Non-critical
      }
      this.viewerSessions.delete(client.id);
    }

    const count = await this.getRoomViewerCount(streamId);
    this.server
      .to(`stream:${streamId}`)
      .emit(LIVE_EVENTS.VIEWER_COUNT, { streamId, count });
  }

  @UsePipes(new ValidationPipe({ transform: true }))
  @SubscribeMessage(LIVE_EVENTS.SEND_CHAT)
  async handleSendChat(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    payload: {
      streamId: string;
      content: string;
      type?: StreamChatMessageType;
    },
  ) {
    const userId = client.data.userId as string | null;
    if (!userId) {
      client.emit(LIVE_EVENTS.ERROR, {
        message: 'Authentication required to send messages',
      });
      return;
    }

    if (!this.checkRateLimit(userId, 'chat')) {
      client.emit(LIVE_EVENTS.ERROR, {
        message: 'Slow down! You are sending messages too fast.',
      });
      return;
    }

    try {
      const chatRoom = await this.streamChatRepo.ensureChatRoomExists(
        payload.streamId,
      );
      const message = await this.streamChatRepo.saveMessage({
        chatRoomId: chatRoom.id,
        senderId: userId,
        content: payload.content,
        type: payload.type ?? StreamChatMessageType.TEXT,
      });

      this.server
        .to(`stream:${payload.streamId}`)
        .emit(LIVE_EVENTS.CHAT_MESSAGE, message);
      this.streamAnalyticsService
        .trackEngagement(payload.streamId, 'chat')
        .catch(() => null);
    } catch {
      client.emit(LIVE_EVENTS.ERROR, { message: 'Failed to send message' });
    }
  }

  @SubscribeMessage(LIVE_EVENTS.REACT_CHAT)
  async handleChatReaction(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    payload: { streamId: string; messageId: string; emoji: string },
  ) {
    const userId = client.data.userId as string | null;
    if (!userId) {
      client.emit(LIVE_EVENTS.ERROR, { message: 'Authentication required' });
      return;
    }

    try {
      const reaction = await this.prisma.streamChatReaction.upsert({
        where: {
          messageId_userId_emoji: {
            messageId: payload.messageId,
            userId,
            emoji: payload.emoji,
          },
        },
        create: { messageId: payload.messageId, userId, emoji: payload.emoji },
        update: {},
      });

      // Count reactions for this emoji on this message
      const count = await this.prisma.streamChatReaction.count({
        where: { messageId: payload.messageId, emoji: payload.emoji },
      });

      this.server
        .to(`stream:${payload.streamId}`)
        .emit(LIVE_EVENTS.CHAT_REACTION, {
          messageId: payload.messageId,
          emoji: payload.emoji,
          count,
          reactionId: reaction.id,
        });
    } catch {
      client.emit(LIVE_EVENTS.ERROR, { message: 'Failed to add reaction' });
    }
  }

  @SubscribeMessage(LIVE_EVENTS.DELETE_CHAT)
  async handleDeleteChat(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { streamId: string; messageId: string },
  ) {
    const userId = client.data.userId as string | null;
    if (!userId) {
      client.emit(LIVE_EVENTS.ERROR, { message: 'Authentication required' });
      return;
    }

    try {
      await this.streamChatService.deleteMessage(
        userId,
        payload.streamId,
        payload.messageId,
      );
      this.server
        .to(`stream:${payload.streamId}`)
        .emit(LIVE_EVENTS.CHAT_DELETED, {
          messageId: payload.messageId,
        });
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to delete message';
      client.emit(LIVE_EVENTS.ERROR, { message: msg });
    }
  }

  @SubscribeMessage(LIVE_EVENTS.PIN_CHAT)
  async handlePinChat(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    payload: { streamId: string; messageId: string; pin: boolean },
  ) {
    const userId = client.data.userId as string | null;
    if (!userId) {
      client.emit(LIVE_EVENTS.ERROR, { message: 'Authentication required' });
      return;
    }

    try {
      const message = await this.streamChatService.pinMessage(
        userId,
        payload.streamId,
        payload.messageId,
        payload.pin !== false,
      );
      this.server
        .to(`stream:${payload.streamId}`)
        .emit(LIVE_EVENTS.CHAT_PINNED, { message });
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to pin message';
      client.emit(LIVE_EVENTS.ERROR, { message: msg });
    }
  }

  @SubscribeMessage(LIVE_EVENTS.POLL_VOTE)
  async handlePollVote(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    payload: { streamId: string; pollId: string; optionId: string },
  ) {
    const userId = client.data.userId as string | null;
    if (!userId) {
      client.emit(LIVE_EVENTS.ERROR, {
        message: 'Authentication required to vote',
      });
      return;
    }

    try {
      // Check if user has already voted on this poll
      const existing = await this.prisma.streamPollVote.findUnique({
        where: { pollId_userId: { pollId: payload.pollId, userId } },
      });
      if (existing) {
        client.emit(LIVE_EVENTS.ERROR, {
          message: 'You have already voted on this poll',
        });
        return;
      }

      // Cast vote
      await this.prisma.$transaction([
        this.prisma.streamPollVote.create({
          data: { pollId: payload.pollId, optionId: payload.optionId, userId },
        }),
        this.prisma.streamPollOption.update({
          where: { id: payload.optionId },
          data: { voteCount: { increment: 1 } },
        }),
      ]);

      // Fetch updated poll for broadcast
      const poll = await this.prisma.streamPoll.findUnique({
        where: { id: payload.pollId },
        include: { options: true },
      });

      this.server
        .to(`stream:${payload.streamId}`)
        .emit(LIVE_EVENTS.POLL_UPDATED, { poll });
    } catch {
      client.emit(LIVE_EVENTS.ERROR, { message: 'Failed to record vote' });
    }
  }

  @SubscribeMessage(LIVE_EVENTS.SEND_REACTION)
  async handleSendReaction(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { streamId: string; emoji: string },
  ) {
    const userId = client.data.userId as string | null;
    if (!userId) return; // Silently ignore unauthenticated reactions

    if (!this.checkRateLimit(userId, 'reaction')) return; // Rate limited - silent

    try {
      await this.prisma.streamReaction.create({
        data: { liveStreamId: payload.streamId, userId, emoji: payload.emoji },
      });

      // Count recent reactions for this emoji (last 5 seconds)
      const cutoff = new Date(Date.now() - 5000);
      const count = await this.prisma.streamReaction.count({
        where: {
          liveStreamId: payload.streamId,
          emoji: payload.emoji,
          createdAt: { gte: cutoff },
        },
      });

      this.server
        .to(`stream:${payload.streamId}`)
        .emit(LIVE_EVENTS.REACTION_BROADCAST, {
          emoji: payload.emoji,
          count,
        });

      this.streamAnalyticsService
        .trackEngagement(payload.streamId, 'reaction')
        .catch(() => null);
    } catch {
      // Non-critical — reactions can fail silently
    }
  }

  @SubscribeMessage(LIVE_EVENTS.QUALITY_REPORT)
  handleQualityReport(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    payload: { streamId: string; quality: string; bandwidth: number },
  ) {
    // ABR quality feedback loop
    if (payload.bandwidth < 500) {
      // Low bandwidth — recommend lower quality
      client.emit(LIVE_EVENTS.QUALITY_RECOMMEND, { quality: '240p' });
    } else if (payload.bandwidth > 4000) {
      client.emit(LIVE_EVENTS.QUALITY_RECOMMEND, { quality: '1080p' });
    }
    
    // Aggregate for health dashboard
    if (!this.qualityReports.has(payload.streamId)) {
      this.qualityReports.set(payload.streamId, []);
    }
    this.qualityReports.get(payload.streamId)!.push(payload.bandwidth);
  }
}
