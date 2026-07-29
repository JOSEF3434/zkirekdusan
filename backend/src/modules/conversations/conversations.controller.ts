// src/modules/conversations/conversations.controller.ts
import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { ConversationsService } from './conversations.service.js';
import { ConversationResponseDto } from './dto/conversation-response.dto.js';
import { CreateDirectConversationDto } from './dto/create-direct-conversation.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Conversations')
@ApiBearerAuth()
@Controller('conversations')
export class ConversationsController {
  constructor(private readonly conversationsService: ConversationsService) {}

  @Post('direct')
  @ApiOperation({ summary: 'Start or retrieve a direct conversation with another user' })
  @ApiResponse({ status: 201, type: ConversationResponseDto })
  async createDirect(
    @Body() dto: CreateDirectConversationDto,
    @CurrentUser('sub') userId: string,
  ): Promise<ConversationResponseDto> {
    return this.conversationsService.createDirectConversation(
      userId,
      dto.recipientId,
    );
  }

  @Get()
  @ApiOperation({ summary: 'Get all conversations for the authenticated user' })
  @ApiResponse({ status: 200, type: [ConversationResponseDto] })
  async getMyConversations(
    @CurrentUser('sub') userId: string,
  ): Promise<ConversationResponseDto[]> {
    return this.conversationsService.getUserConversations(userId);
  }

  @Get(':conversationId')
  @ApiOperation({ summary: 'Get a conversation by ID' })
  @ApiResponse({ status: 200, type: ConversationResponseDto })
  async getConversationById(
    @Param('conversationId') conversationId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<ConversationResponseDto> {
    return this.conversationsService.getConversationById(conversationId, userId);
  }
}
