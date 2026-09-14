import {
  Controller,
  Get,
  Post,
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
import { AdminLiveService } from './services/admin-live.service.js';

@ApiTags('Admin Live Streams')
@Controller('admin/live')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN, AppRole.MODERATOR)
@ApiBearerAuth()
export class AdminLiveController {
  constructor(private readonly liveService: AdminLiveService) {}

  @Get()
  @ApiOperation({ summary: 'List platform live streams with filters' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'status', required: false })
  async getStreams(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('search') search?: string,
    @Query('status') status?: string,
  ) {
    return this.liveService.listStreams({ page, limit, search, status });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get live stream detail' })
  async getStreamDetail(@Param('id') id: string) {
    return this.liveService.getStreamDetail(id);
  }

  @Post(':id/terminate')
  @ApiOperation({ summary: 'Immediately terminate a live stream' })
  async terminateStream(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.liveService.terminateStream(id, actorId, body?.reason);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a live stream record' })
  async deleteStream(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.liveService.deleteStream(id, actorId, body?.reason);
  }

  @Get(':id/chat')
  @ApiOperation({ summary: 'List chat messages for a live stream' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 50 })
  async getStreamChat(
    @Param('id') id: string,
    @Query('page') page = 1,
    @Query('limit') limit = 50,
  ) {
    return this.liveService.listStreamChat(id, { page, limit });
  }

  @Delete('chat/:messageId')
  @ApiOperation({ summary: 'Delete a live stream chat message' })
  async deleteChatMessage(
    @Param('messageId') messageId: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.liveService.deleteChatMessage(messageId, actorId, body?.reason);
  }
}
