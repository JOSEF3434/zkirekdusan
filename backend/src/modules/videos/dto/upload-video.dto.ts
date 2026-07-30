// src/modules/videos/dto/upload-video.dto.ts
import {
  IsString,
  IsOptional,
  IsArray,
  IsEnum,
  MaxLength,
  MinLength,
  IsBoolean,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { VideoVisibility, DownloadPermission } from '@prisma/client';
import { Transform } from 'class-transformer';

export class UploadVideoDto {
  @ApiProperty({ example: 'Introduction to NestJS' })
  @IsString()
  @MinLength(3)
  @MaxLength(300)
  title!: string;

  @ApiPropertyOptional({ example: 'A comprehensive intro to NestJS for beginners' })
  @IsOptional()
  @IsString()
  @MaxLength(10000)
  description?: string;

  @ApiPropertyOptional({
    enum: VideoVisibility,
    default: VideoVisibility.PRIVATE,
    description: 'Initial visibility. Defaults to PRIVATE until explicitly published.',
  })
  @IsOptional()
  @IsEnum(VideoVisibility)
  visibility?: VideoVisibility;

  @ApiPropertyOptional({ enum: DownloadPermission, default: DownloadPermission.MEMBERS_ONLY })
  @IsOptional()
  @IsEnum(DownloadPermission)
  downloadPermission?: DownloadPermission;

  @ApiPropertyOptional({ type: Boolean, default: false })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === 'true' || value === true)
  isDownloadable?: boolean;

  @ApiPropertyOptional({ example: ['technology', 'education'], type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  categories?: string[];

  @ApiPropertyOptional({ example: ['javascript', 'nestjs'], type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];

  @ApiPropertyOptional({ example: ['#nestjs', '#typescript'], type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  hashtags?: string[];

  @ApiPropertyOptional({ description: 'SEO-optimized title' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  seoTitle?: string;

  @ApiPropertyOptional({ description: 'SEO meta description' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  seoDescription?: string;
}
