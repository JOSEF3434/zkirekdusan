// src/modules/downloads/dto/request-download.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsEnum } from 'class-validator';
import { VideoResolution } from '@prisma/client';

export class RequestVideoDownloadDto {
  @ApiProperty({ description: 'Video ID to download' })
  @IsString()
  videoId: string;

  @ApiPropertyOptional({
    enum: VideoResolution,
    default: VideoResolution.R_720P,
    description: 'Desired resolution quality (240p, 360p, 480p, 720p, 1080p, 4K)',
  })
  @IsOptional()
  @IsEnum(VideoResolution)
  resolution?: VideoResolution;
}

export class RequestFileDownloadDto {
  @ApiProperty({ description: 'File ID to download (for images, audio, docs, etc.)' })
  @IsString()
  fileId: string;
}

export class DownloadTokenResponseDto {
  @ApiProperty({ description: 'Download authorization record ID' })
  downloadId: string;

  @ApiProperty({ description: 'Signed URL or streaming link valid for 1 hour' })
  downloadUrl: string;

  @ApiProperty({ description: 'ISO expiration timestamp' })
  expiresAt: Date;

  @ApiPropertyOptional({ enum: VideoResolution })
  resolution?: VideoResolution;

  @ApiProperty({ description: 'Target filename for Content-Disposition header' })
  filename: string;
}
