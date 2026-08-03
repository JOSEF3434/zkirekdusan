// src/modules/comments/dto/comment-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CommentAuthorDto {
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

export class CommentResponseDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ example: 'post-uuid' })
  postId!: string;

  @ApiPropertyOptional({ example: 'parent-comment-uuid', nullable: true })
  parentId?: string | null;

  @ApiProperty({ example: 'Comment text content' })
  content!: string;

  @ApiProperty({ example: 3 })
  likesCount!: number;

  @ApiProperty({ type: CommentAuthorDto })
  author!: CommentAuthorDto;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  createdAt!: Date;
}
