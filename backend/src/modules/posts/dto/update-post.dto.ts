// src/modules/posts/dto/update-post.dto.ts
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsBoolean, IsEnum, IsOptional, IsString } from 'class-validator';
import { PostVisibility, DownloadPermission } from '@prisma/client';

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

  @ApiPropertyOptional({ example: true, description: 'Whether users can download media from this post' })
  @IsOptional()
  @IsBoolean()
  allowDownloads?: boolean;

  @ApiPropertyOptional({ enum: DownloadPermission })
  @IsOptional()
  @IsEnum(DownloadPermission)
  downloadPermission?: DownloadPermission;
}
