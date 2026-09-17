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
  ADD_REACTION: 'reaction:add',
  REMOVE_REACTION: 'reaction:remove',
  MARK_READ: 'message:read',
  PRESENCE_UPDATE: 'presence:update',

  // Call signaling – Client → Server
  CALL_INITIATE: 'call:initiate',
  CALL_ACCEPT: 'call:accept',
  CALL_REJECT: 'call:reject',
  CALL_HANGUP: 'call:hangup',
  CALL_ICE_CANDIDATE: 'call:ice-candidate',

  // Server → Client
  MESSAGE_NEW: 'message:new',
  MESSAGE_UPDATED: 'message:updated',
  MESSAGE_DELETED: 'message:deleted',
  REACTION_NEW: 'reaction:new',
  REACTION_REMOVED: 'reaction:removed',
  TYPING_INDICATOR: 'typing:indicator',
  READ_RECEIPT: 'message:receipt',
  PRESENCE_CHANGED: 'presence:changed',
  ERROR: 'error',

  // Call signaling – Server → Client
  CALL_INCOMING: 'call:incoming',
  CALL_ANSWERED: 'call:answered',
  CALL_REJECTED: 'call:rejected',
  CALL_ENDED: 'call:ended',
  CALL_ICE: 'call:ice',
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

      this.logger.log(`Client connected: ${client.id} (user: ${userId})`);

      // Update DB presence
      await this.presenceService.setStatus(userId, PresenceStatus.ONLINE);

      // Notify others of online presence
      this.server.emit(WS_EVENTS.PRESENCE_CHANGED, {
        userId,
        status: PresenceStatus.ONLINE,
      });
    } catch {
      client.disconnect(true);
    }
  }

  async handleDisconnect(client: Socket) {
    const userId = this.socketUserMap.get(client.id);
    if (userId) {
      client.leave(`user:${userId}`);
      const sockets = this.userSocketMap.get(userId);
      sockets?.delete(client.id);
      if (!sockets?.size) {
        this.userSocketMap.delete(userId);

        // Update DB presence
        await this.presenceService.setOffline(userId).catch(() => {});

        this.server.emit(WS_EVENTS.PRESENCE_CHANGED, {
          userId,
          status: PresenceStatus.OFFLINE,
          lastSeenAt: new Date(),
        });
      }
      this.socketUserMap.delete(client.id);
    }
    this.logger.log(`Client disconnected: ${client.id}`);
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

  // ── Typing Indicators ─────────────────────────────────────────────────────

  @SubscribeMessage(WS_EVENTS.TYPING_START)
  handleTypingStart(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const userId = (client as any).userId as string;
    const payload = {
      userId,
      conversationId: data.conversationId,
      isTyping: true,
    };
    client
      .to(`conversation:${data.conversationId}`)
      .emit(WS_EVENTS.TYPING_INDICATOR, payload);
    client
      .to(`conversation:${data.conversationId}`)
      .emit('typing:start', payload);
    client
      .to(`conversation:${data.conversationId}`)
      .emit('typing:indicator', payload);
  }

  @SubscribeMessage(WS_EVENTS.TYPING_STOP)
  handleTypingStop(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const userId = (client as any).userId as string;
    const payload = {
      userId,
      conversationId: data.conversationId,
      isTyping: false,
    };
    client
      .to(`conversation:${data.conversationId}`)
      .emit(WS_EVENTS.TYPING_INDICATOR, payload);
    client
      .to(`conversation:${data.conversationId}`)
      .emit('typing:stop', payload);
    client
      .to(`conversation:${data.conversationId}`)
      .emit('typing:indicator', payload);
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
      await this.messagesService.addReaction(data.messageId, userId, {
        emoji: data.emoji,
      });
      const payload = {
        messageId: data.messageId,
        conversationId: data.conversationId,
        userId,
        emoji: data.emoji,
        action: 'add',
      };
      const conversation = await this.conversationsRepository.findById(
        data.conversationId,
      );
      const memberIds = conversation?.members?.map((m: any) => m.userId) ?? [];
      this.emitReaction(data.conversationId, payload, memberIds);
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
      await this.messagesService.removeReaction(
        data.messageId,
        userId,
        data.emoji,
      );
      const payload = {
        messageId: data.messageId,
        conversationId: data.conversationId,
        userId,
        emoji: data.emoji,
        action: 'remove',
      };
      const conversation = await this.conversationsRepository.findById(
        data.conversationId,
      );
      const memberIds = conversation?.members?.map((m: any) => m.userId) ?? [];
      this.emitReactionRemoved(data.conversationId, payload, memberIds);
    } catch (err: any) {
      client.emit(WS_EVENTS.ERROR, { message: err.message });
    }
  }

  // ── Mark as Read ──────────────────────────────────────────────────────────

  @SubscribeMessage(WS_EVENTS.MARK_READ)
  async handleMarkRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { messageId: string; conversationId: string },
  ) {
    const userId = (client as any).userId as string;
    try {
      await this.messagesService.markAsRead(data.messageId, userId);
      const payload = {
        messageId: data.messageId,
        conversationId: data.conversationId,
        userId,
        readAt: new Date(),
      };
      this.server
        .to(`conversation:${data.conversationId}`)
        .emit(WS_EVENTS.READ_RECEIPT, payload);
      this.server
        .to(`conversation:${data.conversationId}`)
        .emit('message:read', payload);

      // Broadcast directly to members so read state updates live anywhere
      const conversation = await this.conversationsRepository.findById(
        data.conversationId,
      );
      if (conversation?.members) {
        for (const m of conversation.members) {
          this.server.to(`user:${(m as any).userId}`).emit(WS_EVENTS.READ_RECEIPT, payload);
          this.server.to(`user:${(m as any).userId}`).emit('message:read', payload);
        }
      }
    } catch (err: any) {
      client.emit(WS_EVENTS.ERROR, { message: err.message });
    }
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  private authenticateSocket(client: Socket): string | null {
    try {
      const token =
        client.handshake.auth?.token ||
        client.handshake.headers.authorization?.replace('Bearer ', '');

      if (!token) return null;

      const payload = this.jwtService.verify(token, {
        secret: this.configService.get<string>('JWT_SECRET'),
      });

      return payload.sub as string;
    } catch {
      return null;
    }
  }

  /** Broadcast a new message to conversation room and to members directly */
  emitNewMessage(conversationId: string, message: any, memberUserIds?: string[]) {
    this.server
      .to(`conversation:${conversationId}`)
      .emit(WS_EVENTS.MESSAGE_NEW, message);

    if (memberUserIds && memberUserIds.length > 0) {
      for (const userId of memberUserIds) {
        this.server.to(`user:${userId}`).emit(WS_EVENTS.MESSAGE_NEW, message);
      }
    }
  }

  /** Broadcast a read receipt to conversation room and to members */
  emitReadReceipt(conversationId: string, payload: any, memberUserIds?: string[]) {
    this.server
      .to(`conversation:${conversationId}`)
      .emit(WS_EVENTS.READ_RECEIPT, payload);
    this.server
      .to(`conversation:${conversationId}`)
      .emit('message:read', payload);

    if (memberUserIds && memberUserIds.length > 0) {
      for (const userId of memberUserIds) {
        this.server.to(`user:${userId}`).emit(WS_EVENTS.READ_RECEIPT, payload);
        this.server.to(`user:${userId}`).emit('message:read', payload);
      }
    }
  }

  /** Broadcast a message update to a conversation room (used by MessagesService internally) */
  emitMessageUpdated(conversationId: string, message: any, memberUserIds?: string[]) {
    this.server
      .to(`conversation:${conversationId}`)
      .emit(WS_EVENTS.MESSAGE_UPDATED, message);

    if (memberUserIds && memberUserIds.length > 0) {
      for (const userId of memberUserIds) {
        this.server.to(`user:${userId}`).emit(WS_EVENTS.MESSAGE_UPDATED, message);
      }
    }
  }

  emitMessageDeleted(conversationId: string, messageId: string, memberUserIds?: string[]) {
    const payload = { conversationId, messageId };
    this.server
      .to(`conversation:${conversationId}`)
      .emit(WS_EVENTS.MESSAGE_DELETED, payload);

    if (memberUserIds && memberUserIds.length > 0) {
      for (const userId of memberUserIds) {
        this.server.to(`user:${userId}`).emit(WS_EVENTS.MESSAGE_DELETED, payload);
      }
    }
  }

  /** Broadcast reaction added to conversation room and to members directly */
  emitReaction(conversationId: string, payload: any, memberUserIds?: string[]) {
    this.server.to(`conversation:${conversationId}`).emit(WS_EVENTS.REACTION_NEW, payload);
    this.server.to(`conversation:${conversationId}`).emit('reaction:added', payload);
    this.server.to(`conversation:${conversationId}`).emit('reaction:updated', payload);

    if (memberUserIds && memberUserIds.length > 0) {
      for (const userId of memberUserIds) {
        this.server.to(`user:${userId}`).emit(WS_EVENTS.REACTION_NEW, payload);
        this.server.to(`user:${userId}`).emit('reaction:added', payload);
        this.server.to(`user:${userId}`).emit('reaction:updated', payload);
      }
    }
  }

  /** Broadcast reaction removed to conversation room and to members directly */
  emitReactionRemoved(conversationId: string, payload: any, memberUserIds?: string[]) {
    this.server.to(`conversation:${conversationId}`).emit(WS_EVENTS.REACTION_REMOVED, payload);
    this.server.to(`conversation:${conversationId}`).emit('reaction:removed', payload);
    this.server.to(`conversation:${conversationId}`).emit('reaction:updated', payload);

    if (memberUserIds && memberUserIds.length > 0) {
      for (const userId of memberUserIds) {
        this.server.to(`user:${userId}`).emit(WS_EVENTS.REACTION_REMOVED, payload);
        this.server.to(`user:${userId}`).emit('reaction:removed', payload);
        this.server.to(`user:${userId}`).emit('reaction:updated', payload);
      }
    }
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
