import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Query,
  UseGuards,
  ParseIntPipe,
  DefaultValuePipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { StreamChatService } from './stream-chat.service.js';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { OptionalJwtAuthGuard } from '../../common/guards/optional-jwt-auth.guard.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Stream Chat')
@Controller('streams/:streamId/chat')
export class StreamChatController {
  constructor(private readonly streamChatService: StreamChatService) {}

  @Get()
  @UseGuards(OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get stream chat history' })
  @ApiParam({ name: 'streamId', description: 'Live Stream ID' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'cursor', required: false, type: String })
  async getChatHistory(
    @CurrentUser('sub') userId: string | undefined,
    @Param('streamId') streamId: string,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number,
    @Query('cursor') cursor?: string,
  ) {
    return this.streamChatService.getChatHistory(
      userId,
      streamId,
      limit,
      cursor,
    );
  }

  @Delete(':messageId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete a chat message (Moderator only)' })
  async deleteMessage(
    @CurrentUser('sub') userId: string,
    @Param('streamId') streamId: string,
    @Param('messageId') messageId: string,
  ) {
    return this.streamChatService.deleteMessage(userId, streamId, messageId);
  }

  @Post(':messageId/pin')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Pin a chat message (Moderator only)' })
  async pinMessage(
    @CurrentUser('sub') userId: string,
    @Param('streamId') streamId: string,
    @Param('messageId') messageId: string,
  ) {
    return this.streamChatService.pinMessage(userId, streamId, messageId, true);
  }

  @Delete(':messageId/pin')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Unpin a chat message (Moderator only)' })
  async unpinMessage(
    @CurrentUser('sub') userId: string,
    @Param('streamId') streamId: string,
    @Param('messageId') messageId: string,
  ) {
    return this.streamChatService.pinMessage(
      userId,
      streamId,
      messageId,
      false,
    );
  }
}
