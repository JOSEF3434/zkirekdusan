// src/modules/messages/messages.controller.ts
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { MessagesService } from './messages.service.js';
import { SendMessageDto } from './dto/send-message.dto.js';
import { EditMessageDto } from './dto/edit-message.dto.js';
import { AddReactionDto } from './dto/add-reaction.dto.js';
import {
  MessageResponseDto,
  PaginatedMessagesDto,
} from './dto/message-response.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Messages')
@ApiBearerAuth()
@Controller()
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  // ── Send a message ─────────────────────────────────────────────────────────

  @Post('conversations/:conversationId/messages')
  @ApiOperation({ summary: 'Send a message to a conversation (DM or Channel)' })
  @ApiResponse({ status: 201, type: MessageResponseDto })
  async sendMessage(
    @Param('conversationId') conversationId: string,
    @Body() dto: SendMessageDto,
    @CurrentUser('sub') userId: string,
  ): Promise<MessageResponseDto> {
    return this.messagesService.sendMessage(conversationId, userId, dto);
  }

  // ── Get paginated messages ─────────────────────────────────────────────────

  @Get('conversations/:conversationId/messages')
  @ApiOperation({ summary: 'Get paginated message history for a conversation' })
  @ApiQuery({ name: 'cursor', required: false })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, type: PaginatedMessagesDto })
  async getMessages(
    @Param('conversationId') conversationId: string,
    @CurrentUser('sub') userId: string,
    @Query('cursor') cursor?: string,
    @Query('limit') limit?: number,
  ): Promise<PaginatedMessagesDto> {
    return this.messagesService.getMessages(
      conversationId,
      userId,
      cursor,
      limit ? Number(limit) : 50,
    );
  }

  @Get('conversations/:conversationId/messages/updates')
  @ApiOperation({
    summary:
      'Delta sync: Get new, updated, and deleted messages since a given timestamp',
  })
  @ApiQuery({
    name: 'since',
    required: false,
    description: 'ISO-8601 timestamp',
  })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getMessageUpdates(
    @Param('conversationId') conversationId: string,
    @CurrentUser('sub') userId: string,
    @Query('since') since?: string,
    @Query('limit') limit?: number,
  ) {
    return this.messagesService.getMessageUpdates(
      conversationId,
      userId,
      since,
      limit ? Number(limit) : 100,
    );
  }

  // ── Pinned messages ────────────────────────────────────────────────────────

  @Get('conversations/:conversationId/messages/pinned')
  @ApiOperation({ summary: 'Get all pinned messages in a conversation' })
  @ApiResponse({ status: 200, type: [MessageResponseDto] })
  async getPinnedMessages(
    @Param('conversationId') conversationId: string,
  ): Promise<MessageResponseDto[]> {
    return this.messagesService.getPinnedMessages(conversationId);
  }

  // ── Edit message ───────────────────────────────────────────────────────────

  @Patch('messages/:messageId')
  @ApiOperation({ summary: 'Edit your own message' })
  @ApiResponse({ status: 200, type: MessageResponseDto })
  async editMessage(
    @Param('messageId') messageId: string,
    @Body() dto: EditMessageDto,
    @CurrentUser('sub') userId: string,
  ): Promise<MessageResponseDto> {
    return this.messagesService.editMessage(messageId, userId, dto);
  }

  // ── Delete message ─────────────────────────────────────────────────────────

  @Delete('messages/:messageId')
  @ApiOperation({ summary: 'Delete a message for everyone (owner or admin)' })
  @ApiResponse({ status: 200 })
  async deleteMessage(
    @Param('messageId') messageId: string,
    @CurrentUser('sub') userId: string,
    @CurrentUser('role') role?: string,
  ): Promise<{ success: boolean }> {
    const isAdmin = role === 'ADMIN' || role === 'SUPER_ADMIN';
    return this.messagesService.deleteMessage(messageId, userId, isAdmin);
  }

  // ── Mark as read ───────────────────────────────────────────────────────────

  @Post('messages/:messageId/read')
  @ApiOperation({ summary: 'Mark a message as read' })
  @ApiResponse({ status: 200 })
  async markAsRead(
    @Param('messageId') messageId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<{ success: boolean }> {
    return this.messagesService.markAsRead(messageId, userId);
  }

  // ── Reactions ──────────────────────────────────────────────────────────────

  @Post('messages/:messageId/reactions')
  @ApiOperation({ summary: 'Add a reaction to a message' })
  @ApiResponse({ status: 201 })
  async addReaction(
    @Param('messageId') messageId: string,
    @Body() dto: AddReactionDto,
    @CurrentUser('sub') userId: string,
  ): Promise<{ success: boolean }> {
    return this.messagesService.addReaction(messageId, userId, dto);
  }

  @Delete('messages/:messageId/reactions/:emoji')
  @ApiOperation({ summary: 'Remove your reaction from a message' })
  @ApiResponse({ status: 200 })
  async removeReaction(
    @Param('messageId') messageId: string,
    @Param('emoji') emoji: string,
    @CurrentUser('sub') userId: string,
  ): Promise<{ success: boolean }> {
    return this.messagesService.removeReaction(messageId, userId, emoji);
  }

  // ── Pin / Unpin ────────────────────────────────────────────────────────────

  @Post('conversations/:conversationId/messages/:messageId/pin')
  @ApiOperation({ summary: 'Pin a message in conversation' })
  @ApiResponse({ status: 201 })
  async pinMessage(
    @Param('conversationId') conversationId: string,
    @Param('messageId') messageId: string,
    @CurrentUser('sub') userId: string,
    @CurrentUser('role') role?: string,
  ): Promise<{ success: boolean }> {
    const isAdmin = role === 'ADMIN' || role === 'SUPER_ADMIN';
    return this.messagesService.pinMessage(
      conversationId,
      messageId,
      userId,
      isAdmin,
    );
  }

  @Delete('conversations/:conversationId/messages/:messageId/pin')
  @ApiOperation({ summary: 'Unpin a message from conversation' })
  @ApiResponse({ status: 200 })
  async unpinMessage(
    @Param('conversationId') conversationId: string,
    @Param('messageId') messageId: string,
    @CurrentUser('sub') userId: string,
    @CurrentUser('role') role?: string,
  ): Promise<{ success: boolean }> {
    const isAdmin = role === 'ADMIN' || role === 'SUPER_ADMIN';
    return this.messagesService.unpinMessage(
      conversationId,
      messageId,
      userId,
      isAdmin,
    );
  }

  // ── Star / Unstar ──────────────────────────────────────────────────────────

  @Post('messages/:messageId/star')
  @ApiOperation({ summary: 'Star a message (saved for you only)' })
  @ApiResponse({ status: 201 })
  async starMessage(
    @Param('messageId') messageId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<{ success: boolean }> {
    return this.messagesService.starMessage(userId, messageId);
  }

  @Delete('messages/:messageId/star')
  @ApiOperation({ summary: 'Unstar a message' })
  @ApiResponse({ status: 200 })
  async unstarMessage(
    @Param('messageId') messageId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<{ success: boolean }> {
    return this.messagesService.unstarMessage(userId, messageId);
  }

  @Get('messages/starred')
  @ApiOperation({ summary: 'Get all your starred messages' })
  @ApiResponse({ status: 200, type: [MessageResponseDto] })
  async getStarredMessages(
    @CurrentUser('sub') userId: string,
  ): Promise<MessageResponseDto[]> {
    return this.messagesService.getStarredMessages(userId);
  }
}
