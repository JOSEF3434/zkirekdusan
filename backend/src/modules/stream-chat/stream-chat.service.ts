import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { StreamChatRepository } from './stream-chat.repository.js';
import { LiveStreamingRepository } from '../live-streaming/live-streaming.repository.js';
import { AuthorizationService } from '../authorization/authorization.service.js';
import { SendChatMessageDto } from './dto/send-chat-message.dto.js';
import { GroupRole } from '../../common/constants/group-roles.js';

@Injectable()
export class StreamChatService {
  constructor(
    private readonly repository: StreamChatRepository,
    private readonly liveStreamingRepository: LiveStreamingRepository,
    private readonly authorizationService: AuthorizationService,
  ) {}

  async getChatHistory(
    userId: string | undefined,
    streamId: string,
    limit = 50,
    cursor?: string,
  ) {
    const stream = await this.liveStreamingRepository.getStreamById(streamId);
    if (!stream) throw new NotFoundException('Stream not found');

    if (stream.visibility !== 'PUBLIC') {
      if (!userId) throw new ForbiddenException('Authentication required');
      const hasMemberRole = await this.authorizationService.hasGroupRole(
        userId,
        stream.groupId,
        GroupRole.MEMBER,
      );
      if (!hasMemberRole)
        throw new ForbiddenException('You cannot access this stream chat');
    }

    const chatRoom = await this.repository.getChatRoomByStreamId(streamId);
    if (!chatRoom) return [];

    return this.repository.getMessages(chatRoom.id, limit, cursor);
  }

  async deleteMessage(userId: string, streamId: string, messageId: string) {
    const stream = await this.liveStreamingRepository.getStreamById(streamId);
    if (!stream) throw new NotFoundException('Stream not found');

    const hasPermission = await this.authorizationService.hasGroupRole(
      userId,
      stream.groupId,
      GroupRole.MODERATOR,
    );
    if (!hasPermission) throw new ForbiddenException('Not a moderator');

    const message = await this.repository.getMessageById(messageId);
    const chatRoom = await this.repository.getChatRoomByStreamId(streamId);
    if (!message || message.chatRoomId !== chatRoom?.id) {
      throw new NotFoundException('Message not found');
    }

    return this.repository.deleteMessage(messageId);
  }

  async pinMessage(
    userId: string,
    streamId: string,
    messageId: string,
    isPinned: boolean,
  ) {
    const stream = await this.liveStreamingRepository.getStreamById(streamId);
    if (!stream) throw new NotFoundException('Stream not found');

    const hasPermission = await this.authorizationService.hasGroupRole(
      userId,
      stream.groupId,
      GroupRole.MODERATOR,
    );
    if (!hasPermission) throw new ForbiddenException('Not a moderator');

    const message = await this.repository.getMessageById(messageId);
    const chatRoom = await this.repository.getChatRoomByStreamId(streamId);
    if (!message || message.chatRoomId !== chatRoom?.id) {
      throw new NotFoundException('Message not found');
    }

    return this.repository.pinMessage(messageId, isPinned);
  }
}
