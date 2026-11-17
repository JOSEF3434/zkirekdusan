// src/modules/downloads/dto/request-download.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsEnum, IsUUID } from 'class-validator';
import { VideoResolution } from '@prisma/client';

export class RequestVideoDownloadDto {
  @ApiProperty({ description: 'Video ID to download' })
  @IsString()
  videoId!: string;

  @ApiPropertyOptional({
    enum: VideoResolution,
    default: VideoResolution.R_720P,
    description:
      'Desired resolution quality (240p, 360p, 480p, 720p, 1080p, 4K)',
  })
  @IsOptional()
  @IsEnum(VideoResolution)
  resolution?: VideoResolution;
}

export class RequestFileDownloadDto {
  @ApiProperty({
    description: 'File ID to download (for images, audio, docs, etc.)',
  })
  @IsString()
  fileId!: string;
}

export class RequestPostDownloadDto {
  @ApiProperty({ description: 'Post ID to download media from' })
  @IsString()
  postId!: string;

  @ApiPropertyOptional({ description: 'Specific media file ID if post contains multiple items' })
  @IsOptional()
  @IsString()
  mediaFileId?: string;
}

export class MediaAttributionDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  publisherId!: string;

  @ApiProperty({ example: 'yemariyam123' })
  publisherUsername!: string;

  @ApiProperty({ example: 'የማርያም ልጅ' })
  publisherDisplayName!: string;

  @ApiPropertyOptional({ example: 'https://cdn.example.com/avatar.jpg', nullable: true })
  publisherAvatarUrl?: string | null;

  @ApiProperty({ example: 'POST', enum: ['POST', 'VIDEO', 'FILE', 'CHANNEL', 'GROUP'] })
  sourceType!: string;

  @ApiProperty({ example: 'post-uuid-123' })
  sourceId!: string;

  @ApiPropertyOptional({ example: 'Sample Post Title', nullable: true })
  sourceTitle?: string | null;

  @ApiProperty({ example: 'https://zikrekidusan.org/post/post-uuid-123' })
  canonicalUrl!: string;

  @ApiProperty({ example: '@yemariyam123' })
  watermarkText!: string;

  @ApiProperty({ example: 'Zikire Kdusan' })
  brandName!: string;

  @ApiPropertyOptional({ example: 'Orthodox Channel', nullable: true })
  channelName?: string | null;

  @ApiPropertyOptional({ example: 'Saint George Group', nullable: true })
  groupName?: string | null;
}

export class DownloadTokenResponseDto {
  @ApiProperty({ description: 'Download authorization record ID' })
  downloadId!: string;

  @ApiProperty({ description: 'Signed URL or streaming link valid for 1 hour' })
  downloadUrl!: string;

  @ApiProperty({ description: 'ISO expiration timestamp' })
  expiresAt!: Date;

  @ApiPropertyOptional({ enum: VideoResolution })
  resolution?: VideoResolution;

  @ApiProperty({
    description: 'Target filename for Content-Disposition header',
  })
  filename!: string;

  @ApiPropertyOptional({ example: 'IMAGE' })
  fileType?: string;

  @ApiPropertyOptional({ example: 'image/jpeg' })
  mimeType?: string;

  @ApiProperty({ default: true })
  isWatermarked!: boolean;

  @ApiPropertyOptional({ description: 'Direct pre-watermarked CDN URL if processed on server' })
  watermarkedMediaUrl?: string | null;

  @ApiProperty({ type: MediaAttributionDto })
  attribution!: MediaAttributionDto;
}
