import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  WsException,
} from '@nestjs/websockets';
import { Logger, UseFilters, UsePipes, ValidationPipe } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { StreamChatService } from '../stream-chat/stream-chat.service.js';
import { StreamAnalyticsService } from '../stream-analytics/stream-analytics.service.js';
import { StreamChatRepository } from '../stream-chat/stream-chat.repository.js';

export const LIVE_EVENTS = {
  // Client -> Server
  JOIN_STREAM: 'stream:join',
  LEAVE_STREAM: 'stream:leave',
  SEND_CHAT: 'chat:send',
  SEND_REACTION: 'reaction:send',
  
  // Server -> Client
  CHAT_MESSAGE: 'chat:message',
  REACTION_BROADCAST: 'reaction:broadcast',
  VIEWER_COUNT: 'viewer:count',
  ERROR: 'error',
} as const;

@WebSocketGateway({
  cors: {
    origin: '*',
    credentials: true,
  },
  namespace: '/live',
})
export class LiveGateway implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() declare server: Server;
  private readonly logger = new Logger(LiveGateway.name);

  // Map of viewer session records: socketId -> { userId, streamId, viewerId }
  private readonly viewerSessions = new Map<string, { userId: string; streamId: string; viewerId: string; joinedAt: number }>();

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly streamChatService: StreamChatService,
    private readonly streamAnalyticsService: StreamAnalyticsService,
    private readonly streamChatRepo: StreamChatRepository,
  ) {}

  afterInit(server: Server) {
    this.logger.log('📡 LiveGateway initialized on /live namespace');
  }

  async handleConnection(client: Socket) {
    try {
      const userId = this.authenticateSocket(client);
      if (!userId) {
         return; // Guests might be allowed depending on config, but auth is preferred.
      }
      client.data.userId = userId;
      this.logger.debug(`Client connected to /live: ${client.id} (User: ${userId})`);
    } catch (error) {
       this.logger.debug(`Unauthenticated client connected: ${client.id}`);
       client.data.userId = null;
    }
  }

  async handleDisconnect(client: Socket) {
    this.logger.debug(`Client disconnected: ${client.id}`);
    const session = this.viewerSessions.get(client.id);
    
    if (session) {
      const durationSec = Math.floor((Date.now() - session.joinedAt) / 1000);
      try {
        await this.streamAnalyticsService.trackViewerLeave(session.viewerId, durationSec);
        
        // Decrement room count
        const count = await this.getRoomViewerCount(session.streamId);
        this.server.to(`stream:${session.streamId}`).emit(LIVE_EVENTS.VIEWER_COUNT, { streamId: session.streamId, count });
        
      } catch (e) {
         this.logger.error('Error tracking viewer leave', e);
      }
      this.viewerSessions.delete(client.id);
    }
  }

  private authenticateSocket(client: Socket): string | null {
    const token = this.extractToken(client);
    if (!token) return null;

    try {
      const payload = this.jwtService.verify(token, {
        secret: this.configService.get<string>('JWT_SECRET'),
      });
      return payload.sub; // userId
    } catch (error) {
      return null;
    }
  }

  private extractToken(client: Socket): string | null {
    const authHeader = client.handshake.headers.authorization;
    if (authHeader?.startsWith('Bearer ')) {
      return authHeader.substring(7);
    }
    const queryToken = client.handshake.query.token;
    if (typeof queryToken === 'string') {
      return queryToken;
    }
    return null;
  }
  
  private async getRoomViewerCount(streamId: string): Promise<number> {
      const sockets = await this.server.in(`stream:${streamId}`).fetchSockets();
      return sockets.length;
  }

  @SubscribeMessage(LIVE_EVENTS.JOIN_STREAM)
  async handleJoinStream(
    @ConnectedSocket() client: Socket,
    @MessageBody('streamId') streamId: string,
  ) {
    if (!streamId) return;

    await client.join(`stream:${streamId}`);
    
    if (client.data.userId) {
       try {
         const viewer = await this.streamAnalyticsService.trackViewerJoin(streamId, client.data.userId);
         this.viewerSessions.set(client.id, {
            userId: client.data.userId,
            streamId,
            viewerId: viewer.id,
            joinedAt: Date.now()
         });
       } catch(e) {
          this.logger.warn(`Failed to track viewer join for ${client.data.userId}`);
       }
    }

    const count = await this.getRoomViewerCount(streamId);
    
    // Attempt to update peak
    if (client.data.userId) {
      this.streamAnalyticsService.updateCurrentViewers(streamId, count, count).catch(()=>null);
    }

    this.server.to(`stream:${streamId}`).emit(LIVE_EVENTS.VIEWER_COUNT, { streamId, count });
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
         await this.streamAnalyticsService.trackViewerLeave(session.viewerId, durationSec);
      } catch(e) {}
      this.viewerSessions.delete(client.id);
    }
    
    const count = await this.getRoomViewerCount(streamId);
    this.server.to(`stream:${streamId}`).emit(LIVE_EVENTS.VIEWER_COUNT, { streamId, count });
  }

  @UsePipes(new ValidationPipe())
  @SubscribeMessage(LIVE_EVENTS.SEND_CHAT)
  async handleSendChat(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { streamId: string; content: string; type?: any },
  ) {
    const userId = client.data.userId;
    if (!userId) {
      client.emit(LIVE_EVENTS.ERROR, { message: 'Unauthorized to send chat' });
      return;
    }

    try {
       const chatRoom = await this.streamChatRepo.ensureChatRoomExists(payload.streamId);
       const message = await this.streamChatRepo.saveMessage({
          chatRoomId: chatRoom.id,
          senderId: userId,
          content: payload.content,
          type: payload.type || 'TEXT',
       });
       
       this.server.to(`stream:${payload.streamId}`).emit(LIVE_EVENTS.CHAT_MESSAGE, message);
       
       this.streamAnalyticsService.trackEngagement(payload.streamId, 'chat').catch(()=>null);
    } catch (e) {
       client.emit(LIVE_EVENTS.ERROR, { message: 'Failed to send message' });
    }
  }
}
