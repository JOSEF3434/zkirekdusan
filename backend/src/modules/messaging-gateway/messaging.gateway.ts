// src/modules/messaging-gateway/messaging.gateway.ts
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
import { Logger, Inject, forwardRef } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { MessagesService } from '../messages/messages.service.js';
import { ConversationsRepository } from '../conversations/conversations.repository.js';
import { PresenceService } from '../presence/presence.service.js';
import { SendMessageDto } from '../messages/dto/send-message.dto.js';
import { PresenceStatus } from '@prisma/client';

// ── WS Event Names ────────────────────────────────────────────────────────────
export const WS_EVENTS = {
  // Client → Server
  JOIN_CONVERSATION: 'conversation:join',
  LEAVE_CONVERSATION: 'conversation:leave',
  SEND_MESSAGE: 'message:send',
  TYPING_START: 'typing:start',
  TYPING_STOP: 'typing:stop',
  ACTIVITY_START: 'activity:start',
  ACTIVITY_STOP: 'activity:stop',
  ADD_REACTION: 'reaction:add',
  REMOVE_REACTION: 'reaction:remove',
  MARK_READ: 'message:read',
  CONVERSATION_READ: 'conversation:read',
  MESSAGE_DELIVERED: 'message:delivered',
  PRESENCE_UPDATE: 'presence:update',
  PRESENCE_QUERY: 'presence:query',

  // Call signaling – Client → Server
  CALL_INITIATE: 'call:initiate',
  CALL_ACCEPT: 'call:accept',
  CALL_REJECT: 'call:reject',
  CALL_HANGUP: 'call:hangup',
  CALL_ICE_CANDIDATE: 'call:ice-candidate',
  CALL_REACTION: 'call:reaction',
  CALL_MEDIA_STATE: 'call:media-state',

  // Server → Client
  MESSAGE_NEW: 'message:new',
  MESSAGE_UPDATED: 'message:updated',
  MESSAGE_DELETED: 'message:deleted',
  REACTION_NEW: 'reaction:new',
  REACTION_REMOVED: 'reaction:removed',
  TYPING_INDICATOR: 'typing:indicator',
  ACTIVITY_UPDATE: 'activity:update',
  READ_RECEIPT: 'message:receipt',
  DELIVERY_RECEIPT: 'message:delivered',
  PRESENCE_CHANGED: 'presence:changed',
  ERROR: 'error',

  // Call signaling – Server → Client
  CALL_INCOMING: 'call:incoming',
  CALL_ANSWERED: 'call:answered',
  CALL_REJECTED: 'call:rejected',
  CALL_ENDED: 'call:ended',
  CALL_ICE: 'call:ice',
  CALL_REACTION_RECEIVED: 'call:reaction',
  CALL_MEDIA_STATE_RECEIVED: 'call:media-state',
} as const;

// Interface to avoid circular dependency TDZ in TypeScript emitDecoratorMetadata
interface IMessagesService extends MessagesService {}

@WebSocketGateway({
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
    credentials: true,
  },
  namespace: '/chat',
})
export class MessagingGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer() declare server: Server;

  private readonly logger = new Logger(MessagingGateway.name);
  private readonly userSocketMap = new Map<string, Set<string>>(); // userId → socketIds
  private readonly socketUserMap = new Map<string, string>(); // socketId → userId
  private readonly activityTimers = new Map<string, NodeJS.Timeout>(); // conversationId:userId -> timer
  private readonly disconnectTimers = new Map<string, NodeJS.Timeout>(); // userId -> grace period timer

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @Inject(forwardRef(() => MessagesService))
    private readonly messagesService: IMessagesService,
    private readonly conversationsRepository: ConversationsRepository,
    private readonly presenceService: PresenceService,
  ) {}

  afterInit(_server: Server) {
    this.logger.log('🔌 MessagingGateway initialized');
  }

  // ── Connection / Disconnection ────────────────────────────────────────────

  async handleConnection(client: Socket) {
    try {
      const userId = this.authenticateSocket(client);
      if (!userId) {
        client.emit(WS_EVENTS.ERROR, { message: 'Unauthorized' });
        client.disconnect(true);
        return;
      }

      // If user had a pending disconnect grace timer, cancel it immediately
      if (this.disconnectTimers.has(userId)) {
        clearTimeout(this.disconnectTimers.get(userId));
        this.disconnectTimers.delete(userId);
        this.logger.log(
          `[Presence] Cancelled offline grace timer for user ${userId} on reconnect`,
        );
      }

      // Register socket
      if (!this.userSocketMap.has(userId)) {
        this.userSocketMap.set(userId, new Set());
      }
      this.userSocketMap.get(userId)!.add(client.id);
      this.socketUserMap.set(client.id, userId);

      // Store userId on socket for later use
      (client as any).userId = userId;

      // Join individual user room so server can emit directly to user:${userId}
      await client.join(`user:${userId}`);

      const totalSockets = this.userSocketMap.get(userId)!.size;
      this.logger.log(
        `[Presence] Client connected: ${client.id} (user: ${userId}) - active sockets: ${totalSockets}`,
      );

      // Update DB presence
      await this.presenceService.setStatus(userId, PresenceStatus.ONLINE);

      // Notify all OTHER clients that this user is now online
      this.server.emit(WS_EVENTS.PRESENCE_CHANGED, {
        userId,
        status: PresenceStatus.ONLINE,
      });

      // Send newly connected client an immediate snapshot of who is currently online
      const onlineUserIds = Array.from(this.userSocketMap.keys());
      if (onlineUserIds.length > 0) {
        const snapshot = onlineUserIds.map((uid) => ({
          userId: uid,
          isOnline: true,
          status: PresenceStatus.ONLINE,
        }));
        client.emit('presence:snapshot', { statuses: snapshot });
      }
    } catch (err: any) {
      this.logger.error(
        `[Presence] Connection error for client ${client.id}: ${err.message}`,
      );
      client.disconnect(true);
    }
  }

  async handleDisconnect(client: Socket) {
    const userId = this.socketUserMap.get(client.id);
    if (userId) {
      // Clear any pending activity timers for this user
      for (const [key, timer] of this.activityTimers.entries()) {
        if (key.endsWith(`:${userId}`)) {
          clearTimeout(timer);
          this.activityTimers.delete(key);
          const conversationId = key.split(':')[0];
          this.server
            .to(`conversation:${conversationId}`)
            .emit('activity:update', {
              userId,
              conversationId,
              activity: 'typing',
              isActive: false,
            });
        }
      }

      client.leave(`user:${userId}`);
      const sockets = this.userSocketMap.get(userId);
      sockets?.delete(client.id);
      this.socketUserMap.delete(client.id);

      const remainingSockets = sockets?.size ?? 0;
      this.logger.log(
        `[Presence] Client disconnected: ${client.id} (user: ${userId}) - remaining sockets: ${remainingSockets}`,
      );

      if (remainingSockets === 0) {
        this.userSocketMap.delete(userId);

        // Cancel any existing grace timer
        if (this.disconnectTimers.has(userId)) {
          clearTimeout(this.disconnectTimers.get(userId));
        }

        // Grace period (4 seconds) to prevent transient network/reconnect flickering
        const timer = setTimeout(async () => {
          this.disconnectTimers.delete(userId);
          if (this.isUserOnline(userId)) {
            return;
          }

          this.logger.log(
            `[Presence] Grace period expired for user ${userId} -> broadcasting OFFLINE`,
          );
          await this.presenceService.setOffline(userId).catch(() => {});

          this.server.emit(WS_EVENTS.PRESENCE_CHANGED, {
            userId,
            status: PresenceStatus.OFFLINE,
            lastSeenAt: new Date().toISOString(),
          });
        }, 4000);

        this.disconnectTimers.set(userId, timer);
      }
    } else {
      this.logger.log(`[Presence] Unauthenticated client disconnected: ${client.id}`);
    }
  }

  // ── Join / Leave Conversation Room ────────────────────────────────────────

  @SubscribeMessage(WS_EVENTS.JOIN_CONVERSATION)
  async handleJoinConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const userId = (client as any).userId as string;
    const conversation = await this.conversationsRepository.findById(
      data.conversationId,
    );

    if (!conversation) {
      client.emit(WS_EVENTS.ERROR, { message: 'Conversation not found' });
      return;
    }

    const isMember = conversation.members.some((m: any) => m.userId === userId);
    if (!isMember) {
      client.emit(WS_EVENTS.ERROR, {
        message: 'Not a member of this conversation',
      });
      return;
    }

    await client.join(`conversation:${data.conversationId}`);
    this.logger.log(
      `User ${userId} joined conversation ${data.conversationId}`,
    );
  }

  @SubscribeMessage(WS_EVENTS.LEAVE_CONVERSATION)
  handleLeaveConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    client.leave(`conversation:${data.conversationId}`);
  }

  // ── Send Message ──────────────────────────────────────────────────────────

  @SubscribeMessage(WS_EVENTS.SEND_MESSAGE)
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string } & SendMessageDto,
  ) {
    const userId = (client as any).userId as string;

    try {
      const { conversationId, ...dto } = data;
      const message = await this.messagesService.sendMessage(
        conversationId,
        userId,
        dto,
      );

      // Broadcast to all members of the conversation room
      this.server
        .to(`conversation:${conversationId}`)
        .emit(WS_EVENTS.MESSAGE_NEW, message);

      return { success: true, message };
    } catch (err: any) {
      client.emit(WS_EVENTS.ERROR, { message: err.message });
    }
  }

  // ── Activity & Typing Indicators ─────────────────────────────────────────

  @SubscribeMessage(WS_EVENTS.ACTIVITY_START)
  async handleActivityStart(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string; activity: string },
  ) {
    const userId = (client as any).userId as string;
    if (!userId || !data?.conversationId) return;

    // Verify membership
    const conversation = await this.conversationsRepository.findById(
      data.conversationId,
    );
    if (!conversation) return;
    const isMember = conversation.members?.some((m: any) => m.userId === userId);
    if (!isMember) return;

    const key = `${data.conversationId}:${userId}`;
    if (this.activityTimers.has(key)) {
      clearTimeout(this.activityTimers.get(key)!);
    }

    const payload = {
      userId,
      conversationId: data.conversationId,
      activity: data.activity || 'typing',
      isActive: true,
    };

    const target = client.to(`conversation:${data.conversationId}`);
    for (const member of conversation.members || []) {
      if (member.userId && member.userId !== userId) {
        target.to(`user:${member.userId}`);
      }
    }
    target.emit(WS_EVENTS.ACTIVITY_UPDATE, payload);
    if (payload.activity === 'typing') {
      target.emit(WS_EVENTS.TYPING_INDICATOR, {
        userId,
        conversationId: data.conversationId,
        isTyping: true,
      });
    }

    // Auto-expire after 6s to prevent stuck indicators
    const timer = setTimeout(() => {
      this.activityTimers.delete(key);
      const stopPayload = {
        userId,
        conversationId: data.conversationId,
        activity: data.activity || 'typing',
        isActive: false,
      };
      const stopTarget = this.server.to(`conversation:${data.conversationId}`);
      for (const member of conversation.members || []) {
        if (member.userId && member.userId !== userId) {
          stopTarget.to(`user:${member.userId}`);
        }
      }
      stopTarget.emit(WS_EVENTS.ACTIVITY_UPDATE, stopPayload);
      if (payload.activity === 'typing') {
        stopTarget.emit(WS_EVENTS.TYPING_INDICATOR, {
          userId,
          conversationId: data.conversationId,
          isTyping: false,
        });
      }
    }, 6000);

    this.activityTimers.set(key, timer);
  }

  @SubscribeMessage(WS_EVENTS.ACTIVITY_STOP)
  async handleActivityStop(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string; activity?: string },
  ) {
    const userId = (client as any).userId as string;
    if (!userId || !data?.conversationId) return;

    const key = `${data.conversationId}:${userId}`;
    if (this.activityTimers.has(key)) {
      clearTimeout(this.activityTimers.get(key)!);
      this.activityTimers.delete(key);
    }

    const payload = {
      userId,
      conversationId: data.conversationId,
      activity: data.activity || 'typing',
      isActive: false,
    };

    const conversation = await this.conversationsRepository.findById(
      data.conversationId,
    );
    const target = client.to(`conversation:${data.conversationId}`);
    if (conversation?.members) {
      for (const member of conversation.members) {
        if (member.userId && member.userId !== userId) {
          target.to(`user:${member.userId}`);
        }
      }
    }
    target.emit(WS_EVENTS.ACTIVITY_UPDATE, payload);
    target.emit(WS_EVENTS.TYPING_INDICATOR, {
      userId,
      conversationId: data.conversationId,
      isTyping: false,
    });
  }

  @SubscribeMessage(WS_EVENTS.TYPING_START)
  handleTypingStart(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    return this.handleActivityStart(client, {
      conversationId: data.conversationId,
      activity: 'typing',
    });
  }

  @SubscribeMessage(WS_EVENTS.TYPING_STOP)
  handleTypingStop(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    return this.handleActivityStop(client, {
      conversationId: data.conversationId,
      activity: 'typing',
    });
  }

  // ── Reactions ─────────────────────────────────────────────────────────────

  @SubscribeMessage(WS_EVENTS.ADD_REACTION)
  async handleAddReaction(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: { messageId: string; conversationId: string; emoji: string },
  ) {
    const userId = (client as any).userId as string;
    try {
      const res = await this.messagesService.addReaction(
        data.messageId,
        userId,
        { emoji: data.emoji },
      );
      return res;
    } catch (err: any) {
      client.emit(WS_EVENTS.ERROR, { message: err.message });
    }
  }

  @SubscribeMessage(WS_EVENTS.REMOVE_REACTION)
  async handleRemoveReaction(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: { messageId: string; conversationId: string; emoji: string },
  ) {
    const userId = (client as any).userId as string;
    try {
      const res = await this.messagesService.removeReaction(
        data.messageId,
        userId,
        data.emoji,
      );
      return res;
    } catch (err: any) {
      client.emit(WS_EVENTS.ERROR, { message: err.message });
    }
  }

  // ── Mark as Read & Delivered ──────────────────────────────────────────────

  @SubscribeMessage(WS_EVENTS.MARK_READ)
  async handleMarkRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { messageId: string; conversationId: string },
  ) {
    const userId = (client as any).userId as string;
    try {
      await this.messagesService.markAsRead(data.messageId, userId);
      return { success: true };
    } catch (err: any) {
      client.emit(WS_EVENTS.ERROR, { message: err.message });
    }
  }

  @SubscribeMessage(WS_EVENTS.CONVERSATION_READ)
  async handleConversationRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const userId = (client as any).userId as string;
    if (!userId || !data?.conversationId) return;
    try {
      const newlyReadIds =
        await this.conversationsRepository.markAllMessagesAsRead(
          data.conversationId,
          userId,
        );
      const conversation =
        await this.conversationsRepository.findById(data.conversationId);
      const memberIds =
        conversation?.members?.map((m: any) => m.userId) ?? [];
      for (const msgId of newlyReadIds) {
        const payload = {
          messageId: msgId,
          conversationId: data.conversationId,
          userId,
          readAt: new Date(),
        };
        this.emitReadReceipt(data.conversationId, payload, memberIds);
      }
      return { success: true, count: newlyReadIds.length };
    } catch (err: any) {
      client.emit(WS_EVENTS.ERROR, { message: err.message });
    }
  }

  @SubscribeMessage(WS_EVENTS.MESSAGE_DELIVERED)
  async handleMarkDelivered(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { messageId?: string; conversationId: string },
  ) {
    const userId = (client as any).userId as string;
    if (!userId || !data?.conversationId) return;
    try {
      if (data.messageId) {
        await this.messagesService.markDelivered(data.messageId, userId);
      } else {
        await this.messagesService.markBulkDelivered(
          data.conversationId,
          userId,
        );
      }
      return { success: true };
    } catch (err: any) {
      client.emit(WS_EVENTS.ERROR, { message: err.message });
    }
  }

  @SubscribeMessage(WS_EVENTS.PRESENCE_QUERY)
  handlePresenceQuery(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { userIds: string[] },
  ) {
    if (!Array.isArray(data?.userIds)) return;
    const statuses = data.userIds.map((uid) => {
      const isOnline = this.isUserOnline(uid);
      return {
        userId: uid,
        isOnline,
        status: isOnline ? PresenceStatus.ONLINE : PresenceStatus.OFFLINE,
      };
    });
    client.emit('presence:query_response', { statuses });
  }

  // ── Call Signaling ────────────────────────────────────────────────────────

  /**
   * Caller → Server: initiate a call
   * Payload: { targetUserId, conversationId, callType: 'audio'|'video', offer: RTCSessionDescriptionInit }
   */
  @SubscribeMessage(WS_EVENTS.CALL_INITIATE)
  async handleCallInitiate(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      targetUserId: string;
      conversationId: string;
      callType: 'audio' | 'video';
      offer: object;
      callerName: string;
      callerAvatar?: string;
    },
  ) {
    const callerId = (client as any).userId as string;
    const targetSockets = this.userSocketMap.get(data.targetUserId);

    if (!targetSockets || targetSockets.size === 0) {
      // Target is offline – let caller know immediately
      client.emit(WS_EVENTS.CALL_REJECTED, {
        conversationId: data.conversationId,
        reason: 'offline',
      });
      return;
    }

    // Forward incoming call to all target sockets (multi-device)
    for (const socketId of targetSockets) {
      this.server.to(socketId).emit(WS_EVENTS.CALL_INCOMING, {
        callerId,
        conversationId: data.conversationId,
        callType: data.callType,
        offer: data.offer,
        callerName: data.callerName,
        callerAvatar: data.callerAvatar,
      });
    }
  }

  /**
   * Callee → Server: accept call and send answer SDP back to caller
   * Payload: { callerId, conversationId, answer: RTCSessionDescriptionInit }
   */
  @SubscribeMessage(WS_EVENTS.CALL_ACCEPT)
  handleCallAccept(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: { callerId: string; conversationId: string; answer: object },
  ) {
    const calleeId = (client as any).userId as string;
    const callerSockets = this.userSocketMap.get(data.callerId);
    if (!callerSockets) return;

    for (const socketId of callerSockets) {
      this.server.to(socketId).emit(WS_EVENTS.CALL_ANSWERED, {
        calleeId,
        conversationId: data.conversationId,
        answer: data.answer,
      });
    }
  }

  /**
   * Callee → Server: reject incoming call
   * Payload: { callerId, conversationId, reason?: string }
   */
  @SubscribeMessage(WS_EVENTS.CALL_REJECT)
  handleCallReject(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: { callerId: string; conversationId: string; reason?: string },
  ) {
    const calleeId = (client as any).userId as string;
    const callerSockets = this.userSocketMap.get(data.callerId);
    if (!callerSockets) return;

    for (const socketId of callerSockets) {
      this.server.to(socketId).emit(WS_EVENTS.CALL_REJECTED, {
        calleeId,
        conversationId: data.conversationId,
        reason: data.reason ?? 'declined',
      });
    }
  }

  /**
   * Either party → Server: hang up an active or ringing call
   * Payload: { targetUserId, conversationId }
   */
  @SubscribeMessage(WS_EVENTS.CALL_HANGUP)
  handleCallHangup(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { targetUserId: string; conversationId: string },
  ) {
    const senderId = (client as any).userId as string;
    const targetSockets = this.userSocketMap.get(data.targetUserId);
    if (!targetSockets) return;

    for (const socketId of targetSockets) {
      this.server.to(socketId).emit(WS_EVENTS.CALL_ENDED, {
        senderId,
        conversationId: data.conversationId,
      });
    }
  }

  /**
   * Either party → Server: relay an ICE candidate to the remote peer
   * Payload: { targetUserId, conversationId, candidate: RTCIceCandidateInit }
   */
  @SubscribeMessage(WS_EVENTS.CALL_ICE_CANDIDATE)
  handleCallIceCandidate(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      targetUserId: string;
      conversationId: string;
      candidate: object;
    },
  ) {
    const targetSockets = this.userSocketMap.get(data.targetUserId);
    if (!targetSockets) return;

    for (const socketId of targetSockets) {
      this.server.to(socketId).emit(WS_EVENTS.CALL_ICE, {
        conversationId: data.conversationId,
        candidate: data.candidate,
      });
    }
  }

  /**
   * Either party → Server: send in-call reaction or gesture
   * Payload: { targetUserId, conversationId, emoji, action?: string }
   */
  @SubscribeMessage(WS_EVENTS.CALL_REACTION)
  handleCallReaction(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      targetUserId: string;
      conversationId: string;
      emoji: string;
      action?: string;
    },
  ) {
    const senderId = (client as any).userId as string;
    const targetSockets = this.userSocketMap.get(data.targetUserId);
    if (!targetSockets) return;

    for (const socketId of targetSockets) {
      this.server.to(socketId).emit(WS_EVENTS.CALL_REACTION_RECEIVED, {
        senderId,
        conversationId: data.conversationId,
        emoji: data.emoji,
        action: data.action,
      });
    }
  }

  /**
   * Either party → Server: notify peer of media state changes (mute, video toggle, screen share)
   * Payload: { targetUserId, conversationId, isMuted?: boolean, isVideoEnabled?: boolean, isScreenSharing?: boolean }
   */
  @SubscribeMessage(WS_EVENTS.CALL_MEDIA_STATE)
  handleCallMediaState(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      targetUserId: string;
      conversationId: string;
      isMuted?: boolean;
      isVideoEnabled?: boolean;
      isScreenSharing?: boolean;
    },
  ) {
    const senderId = (client as any).userId as string;
    const targetSockets = this.userSocketMap.get(data.targetUserId);
    if (!targetSockets) return;

    for (const socketId of targetSockets) {
      this.server.to(socketId).emit(WS_EVENTS.CALL_MEDIA_STATE_RECEIVED, {
        senderId,
        conversationId: data.conversationId,
        isMuted: data.isMuted,
        isVideoEnabled: data.isVideoEnabled,
        isScreenSharing: data.isScreenSharing,
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  private authenticateSocket(client: Socket): string | null {
    try {
      const authHeader = client.handshake.headers?.authorization;
      let token: string | undefined;

      if (authHeader && authHeader.startsWith('Bearer ')) {
        token = authHeader.substring(7);
      } else if (authHeader) {
        token = authHeader;
      }

      if (!token) {
        token =
          (client.handshake.auth?.token as string | undefined) ||
          (client.handshake.query?.token as string | undefined);
      }

      if (!token) {
        this.logger.warn(
          `[GatewayAuth] Socket ${client.id} rejected: no token provided in headers, auth, or query`,
        );
        return null;
      }

      const secret =
        this.configService.get<string>('JWT_ACCESS_SECRET') ||
        this.configService.get<string>('JWT_SECRET');

      if (!secret) {
        this.logger.error(
          '[GatewayAuth] Configuration error: Neither JWT_ACCESS_SECRET nor JWT_SECRET is set',
        );
        return null;
      }

      const payload = this.jwtService.verify(token, { secret });
      const userId = payload.sub as string;
      if (!userId) {
        this.logger.warn(
          `[GatewayAuth] Socket ${client.id} token verified but missing sub claim`,
        );
        return null;
      }
      return userId;
    } catch (err: any) {
      this.logger.warn(
        `[GatewayAuth] Socket ${client.id} authentication failed: ${err.message}`,
      );
      return null;
    }
  }

  /** Broadcast a new message to conversation room and to members directly */
  emitNewMessage(
    conversationId: string,
    message: any,
    memberUserIds?: string[],
  ) {
    const target = this.server.to(`conversation:${conversationId}`);
    if (memberUserIds && memberUserIds.length > 0) {
      for (const userId of memberUserIds) {
        target.to(`user:${userId}`);
      }
    }
    target.emit(WS_EVENTS.MESSAGE_NEW, message);
  }

  /** Broadcast a read receipt to conversation room and to members */
  emitReadReceipt(
    conversationId: string,
    payload: any,
    memberUserIds?: string[],
  ) {
    const target = this.server.to(`conversation:${conversationId}`);
    if (memberUserIds && memberUserIds.length > 0) {
      for (const userId of memberUserIds) {
        target.to(`user:${userId}`);
      }
    }
    target.emit(WS_EVENTS.READ_RECEIPT, payload);
    target.emit('message:read', payload);
  }

  /** Broadcast delivery receipt to conversation room and to members */
  emitDeliveryReceipt(
    conversationId: string,
    payload: any,
    memberUserIds?: string[],
  ) {
    const target = this.server.to(`conversation:${conversationId}`);
    if (memberUserIds && memberUserIds.length > 0) {
      for (const userId of memberUserIds) {
        target.to(`user:${userId}`);
      }
    }
    target.emit('message:delivered', payload);
  }

  /** Broadcast a message update to a conversation room (used by MessagesService internally) */
  emitMessageUpdated(
    conversationId: string,
    message: any,
    memberUserIds?: string[],
  ) {
    const target = this.server.to(`conversation:${conversationId}`);
    if (memberUserIds && memberUserIds.length > 0) {
      for (const userId of memberUserIds) {
        target.to(`user:${userId}`);
      }
    }
    target.emit(WS_EVENTS.MESSAGE_UPDATED, message);
  }

  emitMessageDeleted(
    conversationId: string,
    messageId: string,
    memberUserIds?: string[],
  ) {
    const payload = { conversationId, messageId };
    const target = this.server.to(`conversation:${conversationId}`);
    if (memberUserIds && memberUserIds.length > 0) {
      for (const userId of memberUserIds) {
        target.to(`user:${userId}`);
      }
    }
    target.emit(WS_EVENTS.MESSAGE_DELETED, payload);
  }

  /** Broadcast reaction added to conversation room and to members directly */
  emitReaction(conversationId: string, payload: any, memberUserIds?: string[]) {
    const target = this.server.to(`conversation:${conversationId}`);
    if (memberUserIds && memberUserIds.length > 0) {
      for (const userId of memberUserIds) {
        target.to(`user:${userId}`);
      }
    }
    target.emit(WS_EVENTS.REACTION_NEW, payload);
    target.emit('reaction:updated', payload);
  }

  /** Broadcast reaction removed to conversation room and to members directly */
  emitReactionRemoved(
    conversationId: string,
    payload: any,
    memberUserIds?: string[],
  ) {
    const target = this.server.to(`conversation:${conversationId}`);
    if (memberUserIds && memberUserIds.length > 0) {
      for (const userId of memberUserIds) {
        target.to(`user:${userId}`);
      }
    }
    target.emit(WS_EVENTS.REACTION_REMOVED, payload);
    target.emit('reaction:updated', payload);
  }

  /** Check if a user is currently online */
  isUserOnline(userId: string): boolean {
    return (this.userSocketMap.get(userId)?.size ?? 0) > 0;
  }
}

// helper to reduce a type error below
function messageId(data: { messageId: string }) {
  return data.messageId;
}
