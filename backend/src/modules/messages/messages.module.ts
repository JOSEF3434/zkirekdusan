import { Module, forwardRef } from '@nestjs/common';
import { MessagesController } from './messages.controller.js';
import { MessagesService } from './messages.service.js';
import { MessagesRepository } from './messages.repository.js';
import { ConversationsModule } from '../conversations/conversations.module.js';
import { MessagingGatewayModule } from '../messaging-gateway/messaging-gateway.module.js';
import { NotificationsModule } from '../notifications/notifications.module.js';

@Module({
  imports: [
    forwardRef(() => ConversationsModule),
    forwardRef(() => MessagingGatewayModule),
    forwardRef(() => NotificationsModule),
  ],
  controllers: [MessagesController],
  providers: [MessagesService, MessagesRepository],
  exports: [MessagesService, MessagesRepository],
})
export class MessagesModule {}
