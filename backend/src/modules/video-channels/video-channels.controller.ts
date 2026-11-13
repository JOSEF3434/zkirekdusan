import 'multer';
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
  ApiConsumes,
  ApiBody,
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
  @ApiResponse({
    status: 403,
    description: 'Insufficient permissions (requires GROUP_ADMIN)',
  })
  @ApiResponse({ status: 409, description: 'Slug or handle already taken' })
  createChannel(
    @Param('groupId') groupId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateVideoChannelDto,
  ): Promise<VideoChannelResponseDto> {
    return this.service.create(groupId, userId, dto) as any;
  }

  @Get()
  @ApiOperation({
    summary: 'List all video channels in a group',
    description:
      'Returns paginated list of video channels belonging to the specified group.',
  })
  @ApiParam({ name: 'groupId', description: 'Group ID' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiResponse({ status: 200, type: VideoChannelListResponseDto })
  listChannels(
    @Param('groupId') groupId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ): Promise<VideoChannelListResponseDto> {
    return this.service.findByGroup(groupId, +page, +limit);
  }

  @Get(':channelId')
  @ApiOperation({ summary: 'Get video channel details by ID' })
  @ApiParam({ name: 'groupId', description: 'Group ID' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiResponse({ status: 200, type: VideoChannelResponseDto })
  getChannel(
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
  updateChannel(
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

  @Post(':channelId/avatar')
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload video channel avatar' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  async uploadAvatar(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.service.uploadAvatar(channelId, userId, file);
  }

  @Delete(':channelId/avatar')
  @ApiOperation({ summary: 'Delete video channel avatar' })
  async deleteAvatar(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.deleteAvatar(channelId, userId);
  }

  @Post(':channelId/banner')
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload video channel banner' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  async uploadBanner(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.service.uploadBanner(channelId, userId, file);
  }

  @Delete(':channelId/banner')
  @ApiOperation({ summary: 'Delete video channel banner' })
  async deleteBanner(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.deleteBanner(channelId, userId);
  }
}

// ─── Standalone routes (not nested under group) ──────────────────────────────

@ApiTags('Video Channels')
@ApiBearerAuth()
@Controller('video-channels')
export class VideoChannelsPublicController {
  constructor(private readonly service: VideoChannelsService) {}

  @Get()
  @ApiOperation({ summary: 'Discover and search approved public channels' })
  async discover(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('search') search?: string,
    @Query('category') category?: string,
    @CurrentUser('sub') userId?: string,
  ) {
    return this.service.discoverChannels(+page, +limit, search, category, userId);
  }

  @Post()
  @ApiOperation({ summary: 'Submit a new channel creation request (starts in PENDING status)' })
  async requestChannel(
    @CurrentUser('sub') userId: string,
    @Body()
    dto: {
      name: string;
      handle: string;
      description?: string;
      category?: string;
      website?: string;
    },
  ) {
    return this.service.requestChannelCreation(userId, dto);
  }

  @Get('my')
  @ApiOperation({ summary: 'List video channels owned or administered by current user' })
  @ApiResponse({ status: 200, type: [VideoChannelResponseDto] })
  async findMyChannels(
    @CurrentUser('sub') userId: string,
  ): Promise<any> {
    return this.service.findUserOwnedChannels(userId);
  }

  @Get('handle/:handle')
  @ApiOperation({ summary: 'Find video channel by @handle' })
  @ApiParam({ name: 'handle', example: '@techtutorials' })
  @ApiResponse({ status: 200, type: VideoChannelResponseDto })
  findByHandle(
    @Param('handle') handle: string,
  ): Promise<VideoChannelResponseDto> {
    return this.service.findById(handle) as any;
  }

  @Get(':channelId')
  @ApiOperation({ summary: 'Get channel details by ID' })
  async getChannelById(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId?: string,
  ) {
    return this.service.findById(channelId, userId);
  }

  @Get(':channelId/subscribe-status')
  @ApiOperation({ summary: 'Get current user subscribe status for channel' })
  async getSubscribeStatus(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
  ) {
    const isSubscribed = await this.service.isSubscribed(userId, channelId);
    return { isSubscribed };
  }

  @Patch(':channelId')
  @ApiOperation({ summary: 'Update channel profile and settings' })
  async updateChannel(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: UpdateVideoChannelDto,
  ) {
    return this.service.update(channelId, userId, dto);
  }

  @Post(':channelId/subscribe')
  @ApiOperation({ summary: 'Subscribe to a channel' })
  async subscribe(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.subscribe(userId, channelId);
  }

  @Post(':channelId/unsubscribe')
  @ApiOperation({ summary: 'Unsubscribe from a channel' })
  async unsubscribe(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.unsubscribe(userId, channelId);
  }

  @Get(':channelId/subscribers')
  @ApiOperation({ summary: 'Get channel subscribers' })
  async getSubscribers(
    @Param('channelId') channelId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.service.getSubscribers(channelId, +page, +limit);
  }

  @Get(':channelId/analytics')
  @ApiOperation({ summary: 'Get channel analytics' })
  async getAnalytics(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.getChannelAnalytics(channelId, userId);
  }

  @Get(':channelId/posts')
  @ApiOperation({ summary: 'Get channel community posts' })
  async getCommunityPosts(
    @Param('channelId') channelId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @CurrentUser('sub') userId?: string,
  ) {
    return this.service.getCommunityPosts(channelId, +page, +limit, userId);
  }

  @Post(':channelId/posts')
  @ApiOperation({ summary: 'Create community post (channel owner or moderator)' })
  async createCommunityPost(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: { title?: string; content: string; mediaUrls?: string[] },
  ) {
    return this.service.createCommunityPost(channelId, userId, dto);
  }

  @Post('posts/:postId/like')
  @ApiOperation({ summary: 'Like or unlike community post' })
  async likePost(
    @Param('postId') postId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.toggleLikeCommunityPost(postId, userId);
  }

  @Post('posts/:postId/comments')
  @ApiOperation({ summary: 'Add comment to community post' })
  async addComment(
    @Param('postId') postId: string,
    @CurrentUser('sub') userId: string,
    @Body() body: { content: string; parentId?: string },
  ) {
    return this.service.addCommunityComment(postId, userId, body.content, body.parentId);
  }

  @Get('posts/:postId/comments')
  @ApiOperation({ summary: 'Get comments for community post' })
  async getComments(
    @Param('postId') postId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 50,
  ) {
    return this.service.getCommunityComments(postId, +page, +limit);
  }

  @Post(':channelId/avatar')
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({ summary: 'Upload channel avatar' })
  async uploadAvatar(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.service.uploadAvatar(channelId, userId, file);
  }

  @Delete(':channelId/avatar')
  @ApiOperation({ summary: 'Delete channel avatar' })
  async deleteAvatar(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.deleteAvatar(channelId, userId);
  }

  @Post(':channelId/banner')
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({ summary: 'Upload channel banner' })
  async uploadBanner(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.service.uploadBanner(channelId, userId, file);
  }

  @Delete(':channelId/banner')
  @ApiOperation({ summary: 'Delete channel banner' })
  async deleteBanner(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.deleteBanner(channelId, userId);
  }
}
