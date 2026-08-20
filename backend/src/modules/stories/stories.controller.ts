// src/modules/stories/stories.controller.ts
import 'multer';
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { StoriesService } from './stories.service.js';
import { CreateStoryDto } from './dto/create-story.dto.js';
import { StoryResponseDto } from './dto/story-response.dto.js';
import { StoryFeedGroupDto } from './dto/story-feed.dto.js';
import {
  AddStoryReactionDto,
  StoryReactionResponseDto,
} from './dto/story-reaction.dto.js';
import {
  CreateStoryCommentDto,
  StoryCommentResponseDto,
} from './dto/story-comment.dto.js';
import { StoryViewerResponseDto } from './dto/story-viewer.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Stories (24h Expiration)')
@ApiBearerAuth()
@Controller('stories')
export class StoriesController {
  constructor(private readonly storiesService: StoriesService) {}

  @Post()
  @ApiOperation({ summary: 'Create a 24-hour story (JSON payload)' })
  @ApiResponse({ status: 201, type: StoryResponseDto })
  async createStory(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateStoryDto,
  ): Promise<StoryResponseDto> {
    return this.storiesService.createStory(userId, dto);
  }

  @Post('upload')
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload file and create 24-hour story in one step' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
        content: { type: 'string', nullable: true },
        backgroundColor: { type: 'string', nullable: true },
        textColor: { type: 'string', nullable: true },
      },
      required: ['file'],
    },
  })
  @ApiResponse({ status: 201, type: StoryResponseDto })
  async createStoryWithFile(
    @CurrentUser('sub') userId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body('content') content?: string,
    @Body('backgroundColor') backgroundColor?: string,
    @Body('textColor') textColor?: string,
  ): Promise<StoryResponseDto> {
    return this.storiesService.createStoryWithFile(
      userId,
      file,
      content,
      backgroundColor,
      textColor,
    );
  }

  @Get('feed')
  @ApiOperation({
    summary:
      'Get sorted stories feed grouped by user with seen/unseen state (Current user first)',
  })
  @ApiResponse({ status: 200, type: [StoryFeedGroupDto] })
  async getStoryFeed(
    @CurrentUser('sub') userId: string,
  ): Promise<StoryFeedGroupDto[]> {
    return this.storiesService.getStoryFeed(userId);
  }

  @Get('me')
  @ApiOperation({ summary: 'Get current user active stories' })
  @ApiResponse({ status: 200, type: [StoryResponseDto] })
  async getMyStories(
    @CurrentUser('sub') userId: string,
  ): Promise<StoryResponseDto[]> {
    return this.storiesService.getMyStories(userId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get single active story by ID' })
  @ApiResponse({ status: 200, type: StoryResponseDto })
  async getStoryById(
    @Param('id') storyId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<StoryResponseDto> {
    return this.storiesService.getStoryById(storyId, userId);
  }

  @Post(':id/view')
  @ApiOperation({ summary: 'Record an idempotent story view' })
  @ApiResponse({ status: 200, type: StoryResponseDto })
  async viewStory(
    @Param('id') storyId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<StoryResponseDto> {
    return this.storiesService.viewStory(storyId, userId);
  }

  @Post(':id/reactions')
  @ApiOperation({ summary: 'Add or update reaction to a story' })
  @ApiResponse({ status: 200, type: StoryReactionResponseDto })
  async addReaction(
    @Param('id') storyId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: AddStoryReactionDto,
  ): Promise<StoryReactionResponseDto> {
    return this.storiesService.addReaction(storyId, userId, dto.reaction);
  }

  @Delete(':id/reactions/me')
  @ApiOperation({ summary: 'Remove own reaction from a story' })
  @ApiResponse({ status: 200, description: 'Reaction removed' })
  async removeReaction(
    @Param('id') storyId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.storiesService.removeReaction(storyId, userId);
  }

  @Get(':id/views')
  @ApiOperation({ summary: 'Get viewer list sorted by newest first (author only)' })
  @ApiResponse({ status: 200, type: [StoryViewerResponseDto] })
  async getViewers(
    @Param('id') storyId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<StoryViewerResponseDto[]> {
    return this.storiesService.getViewers(storyId, userId);
  }

  @Get(':id/reactions')
  @ApiOperation({ summary: 'Get reaction list sorted by newest first (author only)' })
  @ApiResponse({ status: 200, type: [StoryReactionResponseDto] })
  async getReactions(
    @Param('id') storyId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<StoryReactionResponseDto[]> {
    return this.storiesService.getReactions(storyId, userId);
  }

  @Post(':id/comments')
  @ApiOperation({ summary: 'Add comment to a story' })
  @ApiResponse({ status: 201, type: StoryCommentResponseDto })
  async addComment(
    @Param('id') storyId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateStoryCommentDto,
  ): Promise<StoryCommentResponseDto> {
    return this.storiesService.addComment(storyId, userId, dto.content);
  }

  @Get(':id/comments')
  @ApiOperation({ summary: 'Get comments on a story' })
  @ApiResponse({ status: 200, type: [StoryCommentResponseDto] })
  async getComments(
    @Param('id') storyId: string,
  ): Promise<StoryCommentResponseDto[]> {
    return this.storiesService.getComments(storyId);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete story (author only)' })
  @ApiResponse({ status: 200, description: 'Story deleted' })
  async deleteStory(
    @Param('id') storyId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.storiesService.deleteStory(storyId, userId);
  }
}
