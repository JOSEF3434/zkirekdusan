// src/modules/stories/dto/story-comment.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';
import { StoryAuthorDto } from './story-response.dto.js';

export class CreateStoryCommentDto {
  @ApiProperty({ example: 'This is great!' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  content!: string;
}

export class StoryCommentResponseDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  storyId!: string;

  @ApiProperty({ example: 'This is great!' })
  content!: string;

  @ApiProperty({ type: StoryAuthorDto })
  author!: StoryAuthorDto;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  createdAt!: Date;
}
