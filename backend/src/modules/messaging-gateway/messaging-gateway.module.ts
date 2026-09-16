// src/modules/messaging-gateway/messaging-gateway.module.ts
import { Module, forwardRef } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MessagingGateway } from './messaging.gateway.js';
import { MessagesModule } from '../messages/messages.module.js';
import { ConversationsModule } from '../conversations/conversations.module.js';
import { PresenceModule } from '../presence/presence.module.js';

@Module({
  imports: [
    forwardRef(() => MessagesModule),
    ConversationsModule,
    PresenceModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_SECRET'),
      }),
    }),
  ],
  providers: [MessagingGateway],
  exports: [MessagingGateway],
})
export class MessagingGatewayModule {}
