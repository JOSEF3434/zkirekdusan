// src/modules/stories/dto/story-viewer.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { StoryAuthorDto } from './story-response.dto.js';

export class StoryViewerResponseDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  storyId!: string;

  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  viewerId!: string;

  @ApiProperty({ type: StoryAuthorDto })
  viewer!: StoryAuthorDto;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  viewedAt!: Date;
}
