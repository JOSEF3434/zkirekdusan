// src/modules/posts/dto/post-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PostType, PostVisibility } from '@prisma/client';

export class PostAuthorDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ example: 'johndoe' })
  username!: string;

  @ApiPropertyOptional({ example: 'John Doe', nullable: true })
  displayName?: string | null;

  @ApiPropertyOptional({ example: 'https://cdn.example.com/avatar.jpg', nullable: true })
  avatarUrl?: string | null;
}

export class PostMediaItemDto {
  @ApiProperty({ example: 'file-uuid' })
  id!: string;

  @ApiProperty({ example: 'https://cdn.example.com/image.jpg' })
  url!: string;

  @ApiProperty({ example: 'IMAGE' })
  fileType!: string;

  @ApiProperty({ example: 0 })
  order!: number;
}

export class PostResponseDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ enum: PostType })
  type!: PostType;

  @ApiProperty({ enum: PostVisibility })
  visibility!: PostVisibility;

  @ApiPropertyOptional({ example: 'Post content...' })
  content?: string | null;

  @ApiProperty({ example: ['#tech'] })
  hashtags!: string[];

  @ApiProperty({ example: 5 })
  likesCount!: number;

  @ApiProperty({ example: 2 })
  commentsCount!: number;

  @ApiProperty({ example: 10 })
  viewsCount!: number;

  @ApiProperty({ type: PostAuthorDto })
  author!: PostAuthorDto;

  @ApiPropertyOptional({ example: 'group-uuid', nullable: true })
  groupId?: string | null;

  @ApiProperty({ type: [PostMediaItemDto] })
  media!: PostMediaItemDto[];

  @ApiPropertyOptional({ example: true, description: 'True if current user liked this post' })
  isLiked?: boolean;

  @ApiPropertyOptional({ example: false, description: 'True if current user saved this post' })
  isSaved?: boolean;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  createdAt!: Date;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  updatedAt!: Date;
}
