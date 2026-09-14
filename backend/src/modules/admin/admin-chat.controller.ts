import {
  Controller,
  Get,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { AdminChatService } from './services/admin-chat.service.js';

@ApiTags('Admin Chat')
@Controller('admin/chat')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN, AppRole.MODERATOR)
@ApiBearerAuth()
export class AdminChatController {
  constructor(private readonly chatService: AdminChatService) {}

  @Get('conversations')
  @ApiOperation({ summary: 'List chat conversations with pagination and filters' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({ name: 'type', required: false })
  @ApiQuery({ name: 'search', required: false })
  async getConversations(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('type') type?: string,
    @Query('search') search?: string,
  ) {
    return this.chatService.listConversations({ page, limit, type, search });
  }

  @Get('conversations/:id/messages')
  @ApiOperation({ summary: 'List messages in conversation' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 30 })
  @ApiQuery({ name: 'search', required: false })
  async getMessages(
    @Param('id') id: string,
    @Query('page') page = 1,
    @Query('limit') limit = 30,
    @Query('search') search?: string,
  ) {
    return this.chatService.listMessages(id, { page, limit, search });
  }

  @Delete('messages/:id')
  @ApiOperation({ summary: 'Delete individual chat message' })
  async deleteMessage(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.chatService.deleteMessage(id, actorId, body?.reason);
  }

  @Delete('conversations/:id/purge')
  @ApiOperation({ summary: 'Purge messages from conversation' })
  async purgeConversation(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.chatService.purgeConversation(id, actorId, body?.reason);
  }
}
