import { Module, forwardRef } from '@nestjs/common';
import { StreamChatController } from './stream-chat.controller.js';
import { StreamChatService } from './stream-chat.service.js';
import { StreamChatRepository } from './stream-chat.repository.js';
import { AuthorizationModule } from '../authorization/authorization.module.js';
import { LiveStreamingModule } from '../live-streaming/live-streaming.module.js';

@Module({
  imports: [AuthorizationModule, forwardRef(() => LiveStreamingModule)],
  controllers: [StreamChatController],
  providers: [StreamChatService, StreamChatRepository],
  exports: [StreamChatService, StreamChatRepository],
})
export class StreamChatModule {}
