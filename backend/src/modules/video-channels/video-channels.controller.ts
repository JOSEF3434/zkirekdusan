// src/modules/video-channels/video-channels.controller.ts
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
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { VideoChannelsService } from './video-channels.service.js';
import { CreateVideoChannelDto } from './dto/create-video-channel.dto.js';
import { UpdateVideoChannelDto } from './dto/update-video-channel.dto.js';
import {
  VideoChannelListResponseDto,
  VideoChannelResponseDto,
} from './dto/video-channel-response.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Video Channels')
@ApiBearerAuth()
@Controller('groups/:groupId/video-channels')
export class VideoChannelsController {
  constructor(private readonly service: VideoChannelsService) {}

  @Post()
  @ApiOperation({
    summary: 'Create a video channel in a group',
    description:
      'Creates a new video channel within the specified group. Requires GROUP_ADMIN role. Every video uploaded to the platform must belong to a channel.',
  })
  @ApiParam({ name: 'groupId', description: 'Group ID' })
  @ApiResponse({ status: 201, type: VideoChannelResponseDto })
  @ApiResponse({ status: 403, description: 'Insufficient permissions (requires GROUP_ADMIN)' })
  @ApiResponse({ status: 409, description: 'Slug or handle already taken' })
  async createChannel(
    @Param('groupId') groupId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateVideoChannelDto,
  ): Promise<VideoChannelResponseDto> {
    return this.service.create(groupId, userId, dto) as any;
  }

  @Get()
  @ApiOperation({
    summary: 'List all video channels in a group',
    description: 'Returns paginated list of video channels belonging to the specified group.',
  })
  @ApiParam({ name: 'groupId', description: 'Group ID' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiResponse({ status: 200, type: VideoChannelListResponseDto })
  async listChannels(
    @Param('groupId') groupId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ): Promise<VideoChannelListResponseDto> {
    return this.service.findByGroup(groupId, +page, +limit) as any;
  }

  @Get(':channelId')
  @ApiOperation({ summary: 'Get video channel details by ID' })
  @ApiParam({ name: 'groupId', description: 'Group ID' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiResponse({ status: 200, type: VideoChannelResponseDto })
  async getChannel(
    @Param('channelId') channelId: string,
  ): Promise<VideoChannelResponseDto> {
    return this.service.findById(channelId) as any;
  }

  @Patch(':channelId')
  @ApiOperation({
    summary: 'Update video channel',
    description: 'Update channel details. Requires GROUP_ADMIN role.',
  })
  @ApiParam({ name: 'groupId', description: 'Group ID' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiResponse({ status: 200, type: VideoChannelResponseDto })
  async updateChannel(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: UpdateVideoChannelDto,
  ): Promise<VideoChannelResponseDto> {
    return this.service.update(channelId, userId, dto) as any;
  }

  @Delete(':channelId')
  @ApiOperation({
    summary: 'Delete (archive) a video channel',
    description: 'Soft-deletes the channel. Requires GROUP_ADMIN role.',
  })
  @ApiParam({ name: 'groupId', description: 'Group ID' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiResponse({ status: 200, description: 'Channel deleted' })
  async deleteChannel(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.delete(channelId, userId);
  }

  @Post(':channelId/subscribe')
  @ApiOperation({ summary: 'Subscribe to a video channel' })
  @ApiParam({ name: 'groupId', description: 'Group ID' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiResponse({ status: 201, description: 'Subscribed successfully' })
  async subscribe(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.subscribe(userId, channelId);
  }

  @Delete(':channelId/subscribe')
  @ApiOperation({ summary: 'Unsubscribe from a video channel' })
  @ApiParam({ name: 'groupId', description: 'Group ID' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiResponse({ status: 200, description: 'Unsubscribed successfully' })
  async unsubscribe(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.unsubscribe(userId, channelId);
  }

  @Get(':channelId/subscribers')
  @ApiOperation({ summary: 'List channel subscribers' })
  @ApiParam({ name: 'groupId', description: 'Group ID' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getSubscribers(
    @Param('channelId') channelId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.service.getSubscribers(channelId, +page, +limit);
  }

  @Get(':channelId/analytics')
  @ApiOperation({
    summary: 'Get channel analytics',
    description: 'Requires MODERATOR or higher group role.',
  })
  @ApiParam({ name: 'groupId', description: 'Group ID' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  async getAnalytics(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.getChannelAnalytics(channelId, userId);
  }
}

// ─── Standalone routes (not nested under group) ──────────────────────────────

@ApiTags('Video Channels')
@ApiBearerAuth()
@Controller('video-channels')
export class VideoChannelsPublicController {
  constructor(private readonly service: VideoChannelsService) {}

  @Get('handle/:handle')
  @ApiOperation({ summary: 'Find video channel by @handle' })
  @ApiParam({ name: 'handle', example: '@techtutorials' })
  @ApiResponse({ status: 200, type: VideoChannelResponseDto })
  async findByHandle(@Param('handle') handle: string): Promise<VideoChannelResponseDto> {
    return this.service.findById(handle) as any;
  }
}
