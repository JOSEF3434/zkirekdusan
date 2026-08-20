// src/modules/stories/dto/story-feed.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { StoryAuthorDto, StoryResponseDto } from './story-response.dto.js';

export class StoryFeedGroupDto {
  @ApiProperty({ type: StoryAuthorDto })
  owner!: StoryAuthorDto;

  @ApiProperty({ type: [StoryResponseDto] })
  stories!: StoryResponseDto[];

  @ApiProperty({ example: true, description: 'True if there are stories not yet viewed by current user' })
  hasUnseen!: boolean;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  latestStoryAt!: Date;

  @ApiProperty({ example: 3 })
  totalStories!: number;
}
