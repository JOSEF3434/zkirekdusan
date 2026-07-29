// src/modules/reels/dto/reel-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ReelAuthorDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ example: 'johndoe' })
  username!: string;

  @ApiPropertyOptional({ example: 'John Doe', nullable: true })
  displayName?: string | null;

  @ApiPropertyOptional({ example: 'https://cdn.example.com/avatar.jpg', nullable: true })
  avatarUrl?: string | null;
}

export class ReelResponseDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ example: 'https://cdn.example.com/video.mp4' })
  videoUrl!: string;

  @ApiPropertyOptional({ example: 'https://cdn.example.com/thumb.jpg', nullable: true })
  thumbnailUrl?: string | null;

  @ApiPropertyOptional({ example: 'Reel caption', nullable: true })
  caption?: string | null;

  @ApiProperty({ example: ['#reels'] })
  hashtags!: string[];

  @ApiProperty({ example: 15.5 })
  duration!: number;

  @ApiProperty({ example: 120 })
  likesCount!: number;

  @ApiProperty({ example: 15 })
  commentsCount!: number;

  @ApiProperty({ example: 1500 })
  viewsCount!: number;

  @ApiProperty({ type: ReelAuthorDto })
  author!: ReelAuthorDto;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  createdAt!: Date;
}
