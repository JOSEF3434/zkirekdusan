// src/modules/videos/dto/video-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  VideoStatus,
  VideoVisibility,
  DownloadPermission,
} from '@prisma/client';

export class VideoRenditionDto {
  @ApiProperty() id!: string;
  @ApiProperty() resolution!: string;
  @ApiProperty() height!: number;
  @ApiProperty() width!: number;
  @ApiProperty() bitrate!: number;
  @ApiProperty() url!: string;
  @ApiProperty() isReady!: boolean;
}

export class VideoChapterDto {
  @ApiProperty() id!: string;
  @ApiProperty() title!: string;
  @ApiProperty() startTimeMs!: number;
  @ApiProperty() order!: number;
}

export class VideoResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() videoChannelId!: string;
  @ApiProperty() uploadedById!: string;
  @ApiProperty() title!: string;
  @ApiPropertyOptional() description?: string | null;
  @ApiProperty() slug!: string;
  @ApiProperty({ enum: VideoStatus }) status!: VideoStatus;
  @ApiProperty({ enum: VideoVisibility }) visibility!: VideoVisibility;
  @ApiPropertyOptional() duration?: number | null;
  @ApiPropertyOptional() width?: number | null;
  @ApiPropertyOptional() height?: number | null;
  @ApiPropertyOptional() bitrate?: number | null;
  @ApiPropertyOptional() videoCodec?: string | null;
  @ApiPropertyOptional() audioCodec?: string | null;
  @ApiPropertyOptional() thumbnailUrl?: string | null;
  @ApiPropertyOptional() previewUrl?: string | null;
  @ApiPropertyOptional() hlsUrl?: string | null;
  @ApiPropertyOptional() dashUrl?: string | null;
  @ApiProperty({ type: [String] }) categories!: string[];
  @ApiProperty({ type: [String] }) tags!: string[];
  @ApiProperty({ type: [String] }) hashtags!: string[];
  @ApiProperty({ enum: DownloadPermission })
  downloadPermission!: DownloadPermission;
  @ApiProperty() isDownloadable!: boolean;
  @ApiProperty() viewsCount!: string;
  @ApiProperty() likesCount!: number;
  @ApiProperty() dislikesCount!: number;
  @ApiProperty() commentsCount!: number;
  @ApiProperty() sharesCount!: number;
  @ApiProperty() bookmarksCount!: number;
  @ApiProperty() downloadsCount!: number;
  @ApiPropertyOptional() publishedAt?: Date | null;
  @ApiPropertyOptional() scheduledAt?: Date | null;
  @ApiProperty() createdAt!: Date;
  @ApiProperty() updatedAt!: Date;
  @ApiPropertyOptional({ type: [VideoRenditionDto] })
  renditions?: VideoRenditionDto[];
  @ApiPropertyOptional({ type: [VideoChapterDto] })
  chapters?: VideoChapterDto[];
}

export class VideoListResponseDto {
  @ApiProperty({ type: [VideoResponseDto] }) data!: VideoResponseDto[];
  @ApiProperty() total!: number;
  @ApiProperty() page!: number;
  @ApiProperty() limit!: number;
  @ApiPropertyOptional() nextCursor?: string;
}

export class VideoQueryDto {
  @ApiPropertyOptional({ example: 1 }) page?: number;
  @ApiPropertyOptional({ example: 20 }) limit?: number;
  @ApiPropertyOptional({ enum: VideoStatus }) status?: VideoStatus;
  @ApiPropertyOptional({ enum: VideoVisibility }) visibility?: VideoVisibility;
  @ApiPropertyOptional({ description: 'Cursor-based pagination cursor' })
  cursor?: string;
  @ApiPropertyOptional({ description: 'Search query' }) search?: string;
  @ApiPropertyOptional({ description: 'Filter by category' }) category?: string;
}

export class WatchProgressDto {
  @ApiProperty() videoId!: string;
  @ApiProperty({ description: 'Current position in seconds' })
  watchedSeconds!: number;
  @ApiProperty({ description: 'Percentage (0-100)' }) watchedPercent!: number;
  @ApiProperty() isCompleted!: boolean;
}
