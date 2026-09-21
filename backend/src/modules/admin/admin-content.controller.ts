import {
  Controller,
  Get,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { AdminContentService } from './services/admin-content.service.js';

@ApiTags('Admin Content')
@Controller('admin/content')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN, AppRole.MODERATOR)
@ApiBearerAuth()
export class AdminContentController {
  constructor(private readonly contentService: AdminContentService) {}

  @Get('posts')
  @ApiOperation({ summary: 'List platform posts with pagination and filters' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'status', required: false })
  @ApiQuery({ name: 'groupId', required: false })
  @ApiQuery({ name: 'authorId', required: false })
  async getPosts(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('search') search?: string,
    @Query('status') status?: string,
    @Query('groupId') groupId?: string,
    @Query('authorId') authorId?: string,
  ) {
    return this.contentService.listPosts({
      page,
      limit,
      search,
      status,
      groupId,
      authorId,
    });
  }

  @Get('posts/:id')
  @ApiOperation({ summary: 'Get detailed post by ID' })
  async getPostDetail(@Param('id') id: string) {
    return this.contentService.getPostDetail(id);
  }

  @Patch('posts/:id/status')
  @ApiOperation({ summary: 'Update post publication status' })
  async updatePostStatus(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body: { status: string; reason?: string },
  ) {
    return this.contentService.updatePostStatus(
      id,
      body.status,
      actorId,
      body.reason,
    );
  }

  @Delete('posts/:id')
  @ApiOperation({ summary: 'Delete post' })
  async deletePost(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.contentService.deletePost(id, actorId, body?.reason);
  }

  @Get('videos')
  @ApiOperation({ summary: 'List videos with pagination and filters' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'status', required: false })
  @ApiQuery({ name: 'channelId', required: false })
  async getVideos(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('search') search?: string,
    @Query('status') status?: string,
    @Query('channelId') channelId?: string,
  ) {
    return this.contentService.listVideos({
      page,
      limit,
      search,
      status,
      channelId,
    });
  }

  @Patch('videos/:id/status')
  @ApiOperation({ summary: 'Update video status' })
  async updateVideoStatus(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body: { status: string; reason?: string },
  ) {
    return this.contentService.updateVideoStatus(
      id,
      body.status,
      actorId,
      body.reason,
    );
  }

  @Delete('videos/:id')
  @ApiOperation({ summary: 'Delete video' })
  async deleteVideo(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.contentService.deleteVideo(id, actorId, body?.reason);
  }

  @Get('reels')
  @ApiOperation({ summary: 'List reels' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'authorId', required: false })
  async getReels(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('search') search?: string,
    @Query('authorId') authorId?: string,
  ) {
    return this.contentService.listReels({ page, limit, search, authorId });
  }

  @Delete('reels/:id')
  @ApiOperation({ summary: 'Delete reel' })
  async deleteReel(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.contentService.deleteReel(id, actorId, body?.reason);
  }

  @Get('comments')
  @ApiOperation({ summary: 'List comments' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'postId', required: false })
  async getComments(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('search') search?: string,
    @Query('postId') postId?: string,
  ) {
    return this.contentService.listComments({ page, limit, search, postId });
  }

  @Delete('comments/:id')
  @ApiOperation({ summary: 'Delete comment' })
  async deleteComment(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.contentService.deleteComment(id, actorId, body?.reason);
  }
}
