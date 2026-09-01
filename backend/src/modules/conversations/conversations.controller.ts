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
import { ChatDiscoveryResponseDto } from './dto/chat-discovery-response.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Conversations')
@ApiBearerAuth()
@Controller('conversations')
export class ConversationsController {
  constructor(private readonly conversationsService: ConversationsService) {}

  @Get('discover')
  @ApiOperation({
    summary:
      'Get chat discovery data (all users, all public groups, my private groups, and active conversations)',
  })
  @ApiResponse({ status: 200, type: ChatDiscoveryResponseDto })
  async getDiscovery(
    @CurrentUser('sub') userId: string,
  ): Promise<ChatDiscoveryResponseDto> {
    return this.conversationsService.getChatDiscovery(userId);
  }

  @Post('direct')
  @ApiOperation({
    summary: 'Start or retrieve a direct conversation with another user',
  })
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

  @Post('group/:groupId')
  @ApiOperation({
    summary: 'Get or start group conversation',
  })
  @ApiResponse({ status: 201, type: ConversationResponseDto })
  async createGroupChat(
    @Param('groupId') groupId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<ConversationResponseDto> {
    return this.conversationsService.findOrCreateGroupConversation(
      groupId,
      userId,
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
    return this.conversationsService.getConversationById(
      conversationId,
      userId,
    );
  }

  @Post(':conversationId/mute')
  @ApiOperation({ summary: 'Mute a conversation' })
  @ApiResponse({ status: 200 })
  async muteConversation(
    @Param('conversationId') conversationId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<{ success: boolean }> {
    await this.conversationsService.muteConversation(conversationId, userId);
    return { success: true };
  }

  @Post(':conversationId/unmute')
  @ApiOperation({ summary: 'Unmute a conversation' })
  @ApiResponse({ status: 200 })
  async unmuteConversation(
    @Param('conversationId') conversationId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<{ success: boolean }> {
    await this.conversationsService.unmuteConversation(conversationId, userId);
    return { success: true };
  }

  @Post(':conversationId/pin')
  @ApiOperation({ summary: 'Pin a conversation' })
  @ApiResponse({ status: 200 })
  async pinConversation(
    @Param('conversationId') conversationId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<{ success: boolean }> {
    await this.conversationsService.pinConversation(conversationId, userId);
    return { success: true };
  }

  @Post(':conversationId/unpin')
  @ApiOperation({ summary: 'Unpin a conversation' })
  @ApiResponse({ status: 200 })
  async unpinConversation(
    @Param('conversationId') conversationId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<{ success: boolean }> {
    await this.conversationsService.unpinConversation(conversationId, userId);
    return { success: true };
  }

  @Post(':conversationId/mark-read')
  @ApiOperation({ summary: 'Mark conversation as read' })
  @ApiResponse({ status: 200 })
  async markAsRead(
    @Param('conversationId') conversationId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<{ success: boolean }> {
    await this.conversationsService.markAsRead(conversationId, userId);
    return { success: true };
  }
}
