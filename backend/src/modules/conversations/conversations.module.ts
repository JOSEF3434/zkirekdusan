import { Module, forwardRef } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { ConversationsController } from './conversations.controller.js';
import { ConversationsService } from './conversations.service.js';
import { ConversationsRepository } from './conversations.repository.js';
import { UsersModule } from '../users/users.module.js';
import { MessagingGatewayModule } from '../messaging-gateway/messaging-gateway.module.js';

@Module({
  imports: [PrismaModule, UsersModule, forwardRef(() => MessagingGatewayModule)],
  controllers: [ConversationsController],
  providers: [ConversationsService, ConversationsRepository],
  exports: [ConversationsService, ConversationsRepository],
})
export class ConversationsModule {}
