// src/modules/posts/dto/update-post.dto.ts
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsEnum, IsOptional, IsString } from 'class-validator';
import { PostVisibility } from '@prisma/client';

export class UpdatePostDto {
  @ApiPropertyOptional({ enum: PostVisibility })
  @IsOptional()
  @IsEnum(PostVisibility)
  visibility?: PostVisibility;

  @ApiPropertyOptional({ example: 'Updated post content' })
  @IsOptional()
  @IsString()
  content?: string;

  @ApiPropertyOptional({ example: ['#updated'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  hashtags?: string[];
}
