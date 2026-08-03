// src/modules/stories/stories.controller.ts
import { Body, Controller, Delete, Get, Param, Post } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { StoriesService } from './stories.service.js';
import { CreateStoryDto } from './dto/create-story.dto.js';
import { StoryResponseDto } from './dto/story-response.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { Public } from '../../common/decorators/public.decorator.js';

@ApiTags('Stories (24h Expiration)')
@Controller('stories')
export class StoriesController {
  constructor(private readonly storiesService: StoriesService) {}

  @Post()
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a 24-hour story (image, video, text)' })
  @ApiResponse({ status: 201, type: StoryResponseDto })
  async createStory(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateStoryDto,
  ): Promise<StoryResponseDto> {
    return this.storiesService.createStory(userId, dto);
  }

  @Public()
  @Get()
  @ApiOperation({ summary: 'Get active non-expired stories' })
  @ApiResponse({ status: 200, type: [StoryResponseDto] })
  async getActiveStories(): Promise<StoryResponseDto[]> {
    return this.storiesService.getActiveStories();
  }

  @Post(':id/view')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Record a story view' })
  @ApiResponse({ status: 200, type: StoryResponseDto })
  async viewStory(
    @Param('id') storyId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<StoryResponseDto> {
    return this.storiesService.viewStory(storyId, userId);
  }

  @Delete(':id')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete story (author only)' })
  @ApiResponse({ status: 200, description: 'Story deleted' })
  async deleteStory(
    @Param('id') storyId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.storiesService.deleteStory(storyId, userId);
  }
}
