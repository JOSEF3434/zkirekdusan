// src/modules/notifications/notifications.gateway.ts
import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { NotificationResponseDto } from './dto/notification-response.dto.js';

@WebSocketGateway({
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
    credentials: true,
  },
  namespace: '/notifications',
})
export class NotificationsGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer() declare server: Server;
  private readonly logger = new Logger(NotificationsGateway.name);

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  afterInit(_server: Server) {
    this.logger.log('🔔 NotificationsGateway initialized');
  }

  handleConnection(client: Socket) {
    try {
      const token = this.extractToken(client);
      if (!token) {
        client.disconnect(true);
        return;
      }

      const payload = this.jwtService.verify(token, {
        secret: this.configService.get<string>('JWT_ACCESS_SECRET'),
      });
      const userId = payload.sub;

      // Join a personal room for this user to receive their own notifications
      void client.join(`user:${userId}`);
      this.logger.log(
        `Client ${client.id} joined notifications (user: ${userId})`,
      );
    } catch {
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected from notifications: ${client.id}`);
  }

  private extractToken(client: Socket): string | undefined {
    const authHeader = client.handshake.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7);
    }
    const tokenQuery =
      client.handshake.auth?.token || client.handshake.query?.token;
    if (typeof tokenQuery === 'string') {
      return tokenQuery;
    }
    return undefined;
  }

  public emitNotification(
    userId: string,
    notification: NotificationResponseDto,
  ) {
    this.server.to(`user:${userId}`).emit('notification:new', notification);
  }
}
