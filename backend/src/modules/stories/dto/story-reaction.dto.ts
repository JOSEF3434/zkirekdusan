// src/modules/stories/dto/story-reaction.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';
import { ReactionType } from '@prisma/client';
import { StoryAuthorDto } from './story-response.dto.js';

export class AddStoryReactionDto {
  @ApiProperty({ enum: ReactionType, example: ReactionType.LIKE })
  @IsEnum(ReactionType)
  reaction!: ReactionType;
}

export class StoryReactionResponseDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  storyId!: string;

  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  userId!: string;

  @ApiProperty({ enum: ReactionType, example: ReactionType.LIKE })
  reaction!: ReactionType;

  @ApiProperty({ type: StoryAuthorDto })
  user!: StoryAuthorDto;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  createdAt!: Date;
}
