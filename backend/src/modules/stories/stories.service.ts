// src/modules/stories/stories.service.ts
import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { StoriesRepository } from './stories.repository.js';
import { CreateStoryDto } from './dto/create-story.dto.js';
import { StoryResponseDto } from './dto/story-response.dto.js';

@Injectable()
export class StoriesService {
  constructor(private readonly storiesRepository: StoriesRepository) {}

  async createStory(
    authorId: string,
    dto: CreateStoryDto,
  ): Promise<StoryResponseDto> {
    const story = await this.storiesRepository.createStory(authorId, dto);
    return this.mapToDto(story);
  }

  async getActiveStories(): Promise<StoryResponseDto[]> {
    const stories = await this.storiesRepository.findActiveStories();
    return stories.map((s) => this.mapToDto(s));
  }

  async viewStory(
    storyId: string,
    viewerId: string,
  ): Promise<StoryResponseDto> {
    const story = await this.storiesRepository.findById(storyId);
    if (!story) {
      throw new NotFoundException('Story not found');
    }

    if (story.expiresAt < new Date()) {
      throw new NotFoundException('Story has expired');
    }

    await this.storiesRepository.recordView(storyId, viewerId);
    const updated = await this.storiesRepository.findById(storyId);
    return this.mapToDto(updated!);
  }

  async deleteStory(storyId: string, userId: string) {
    const story = await this.storiesRepository.findById(storyId);
    if (!story) {
      throw new NotFoundException('Story not found');
    }

    if (story.authorId !== userId) {
      throw new ForbiddenException('You can only delete your own stories');
    }

    await this.storiesRepository.softDelete(storyId);
    return { message: 'Story deleted successfully' };
  }

  private mapToDto(s: any): StoryResponseDto {
    return {
      id: s.id,
      type: s.type,
      mediaUrl: s.file?.url ?? null,
      content: s.content,
      backgroundColor: s.backgroundColor,
      viewsCount: s.viewsCount ?? 0,
      author: {
        id: s.author.id,
        username: s.author.username,
        displayName: s.author.profile?.displayName ?? s.author.username,
        avatarUrl: s.author.profile?.avatar?.url ?? null,
      },
      expiresAt: s.expiresAt,
      createdAt: s.createdAt,
    };
  }
}
