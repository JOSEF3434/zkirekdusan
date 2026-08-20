// src/modules/stories/dto/story-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ReactionType, StoryType } from '@prisma/client';

export class StoryAuthorDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ example: 'johndoe' })
  username!: string | null;

  @ApiPropertyOptional({ example: 'John Doe', nullable: true })
  displayName?: string | null;

  @ApiPropertyOptional({
    example: 'https://cdn.example.com/avatar.jpg',
    nullable: true,
  })
  avatarUrl?: string | null;
}

export class StoryResponseDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ enum: StoryType })
  type!: StoryType;

  @ApiPropertyOptional({
    example: 'https://cdn.example.com/story.jpg',
    nullable: true,
  })
  mediaUrl?: string | null;

  @ApiPropertyOptional({ example: 'Text caption', nullable: true })
  content?: string | null;

  @ApiPropertyOptional({ example: '#ff0055', nullable: true })
  backgroundColor?: string | null;

  @ApiPropertyOptional({ example: '#ffffff', nullable: true })
  textColor?: string | null;

  @ApiProperty({ example: 12 })
  viewsCount!: number;

  @ApiProperty({ example: 5 })
  reactionsCount!: number;

  @ApiProperty({ example: 2 })
  commentsCount!: number;

  @ApiProperty({ example: false })
  hasViewedByMe?: boolean;

  @ApiPropertyOptional({ enum: ReactionType, nullable: true })
  myReaction?: ReactionType | null;

  @ApiProperty({ type: StoryAuthorDto })
  author!: StoryAuthorDto;

  @ApiProperty({ example: '2024-01-16T10:00:00.000Z' })
  expiresAt!: Date;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  createdAt!: Date;
}
