import { Module, forwardRef } from '@nestjs/common';
import { ConversationsController } from './conversations.controller.js';
import { ConversationsService } from './conversations.service.js';
import { ConversationsRepository } from './conversations.repository.js';
import { UsersModule } from '../users/users.module.js';
import { MessagingGatewayModule } from '../messaging-gateway/messaging-gateway.module.js';

@Module({
  imports: [UsersModule, forwardRef(() => MessagingGatewayModule)],
  controllers: [ConversationsController],
  providers: [ConversationsService, ConversationsRepository],
  exports: [ConversationsService, ConversationsRepository],
})
export class ConversationsModule {}
