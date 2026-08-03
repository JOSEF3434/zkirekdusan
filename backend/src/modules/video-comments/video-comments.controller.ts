// src/modules/video-comments/video-comments.controller.ts
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
import { VideoCommentsService } from './video-comments.service.js';
import { CreateVideoCommentDto } from './dto/create-video-comment.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Video Comments')
@ApiBearerAuth()
@Controller('videos/:videoId/comments')
export class VideoCommentsController {
  constructor(private readonly service: VideoCommentsService) {}

  @Post()
  @ApiOperation({ summary: 'Add a comment or nested reply to a video' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async createComment(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateVideoCommentDto,
  ) {
    return this.service.create(videoId, userId, dto);
  }

  @Get()
  @ApiOperation({ summary: 'List comments for a video' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async listComments(
    @Param('videoId') videoId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.service.findByVideo(videoId, +page, +limit);
  }

  @Patch(':commentId')
  @ApiOperation({ summary: 'Edit comment content' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  @ApiParam({ name: 'commentId', description: 'Comment ID' })
  async updateComment(
    @Param('commentId') commentId: string,
    @CurrentUser('sub') userId: string,
    @Body('content') content: string,
  ) {
    return this.service.update(commentId, userId, content);
  }

  @Delete(':commentId')
  @ApiOperation({ summary: 'Delete comment' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  @ApiParam({ name: 'commentId', description: 'Comment ID' })
  async deleteComment(
    @Param('commentId') commentId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.delete(commentId, userId);
  }

  @Post(':commentId/like')
  @ApiOperation({ summary: 'Toggle like on video comment' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  @ApiParam({ name: 'commentId', description: 'Comment ID' })
  async toggleLike(
    @Param('commentId') commentId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.toggleLike(commentId, userId);
  }

  @Post(':commentId/pin')
  @ApiOperation({
    summary: 'Toggle pinned status on video comment (Uploader or Admin)',
  })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  @ApiParam({ name: 'commentId', description: 'Comment ID' })
  async togglePin(
    @Param('commentId') commentId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.togglePin(commentId, userId);
  }
}
