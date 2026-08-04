// src/modules/posts/dto/create-post.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsEnum, IsOptional, IsString, IsUUID } from 'class-validator';
import { PostType, PostVisibility } from '@prisma/client';

export class CreatePostDto {
  @ApiProperty({ enum: PostType, example: PostType.TEXT })
  @IsEnum(PostType)
  type!: PostType;

  @ApiPropertyOptional({ enum: PostVisibility, example: PostVisibility.PUBLIC })
  @IsOptional()
  @IsEnum(PostVisibility)
  visibility?: PostVisibility;

  @ApiPropertyOptional({
    example: 'This is a sample post content with #hashtags',
  })
  @IsOptional()
  @IsString()
  content?: string;

  @ApiPropertyOptional({ example: ['#tech', '#news'], type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  hashtags?: string[];

  @ApiPropertyOptional({
    example: ['123e4567-e89b-12d3-a456-426614174000'],
    type: [String],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  mentions?: string[];

  @ApiPropertyOptional({
    example: '123e4567-e89b-12d3-a456-426614174000',
    description: 'Associated group ID if posting to a group',
  })
  @IsOptional()
  @IsUUID()
  groupId?: string;

  @ApiPropertyOptional({
    example: ['file-id-1', 'file-id-2'],
    type: [String],
    description: 'Media file IDs attached to the post',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  mediaFileIds?: string[];
}
