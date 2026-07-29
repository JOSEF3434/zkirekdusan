// src/modules/video-channels/dto/video-channel-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { VideoChannelStatus, DownloadPermission, GroupRole } from '@prisma/client';

export class VideoChannelResponseDto {
  @ApiProperty() id: string;
  @ApiProperty() groupId: string;
  @ApiProperty() name: string;
  @ApiProperty() slug: string;
  @ApiProperty() handle: string;
  @ApiPropertyOptional() description?: string | null;
  @ApiProperty({ enum: VideoChannelStatus }) status: VideoChannelStatus;
  @ApiProperty() isVerified: boolean;
  @ApiProperty({ enum: GroupRole }) uploadPermission: GroupRole;
  @ApiProperty({ enum: DownloadPermission }) downloadPermission: DownloadPermission;
  @ApiProperty() subscribersCount: number;
  @ApiProperty() videosCount: number;
  @ApiProperty() totalViewsCount: string;
  @ApiPropertyOptional() categories?: string[];
  @ApiPropertyOptional() tags?: string[];
  @ApiPropertyOptional() country?: string | null;
  @ApiPropertyOptional() language?: string | null;
  @ApiPropertyOptional() avatarFileId?: string | null;
  @ApiPropertyOptional() bannerFileId?: string | null;
  @ApiProperty() createdAt: Date;
  @ApiProperty() updatedAt: Date;
}

export class VideoChannelListResponseDto {
  @ApiProperty({ type: [VideoChannelResponseDto] }) data: VideoChannelResponseDto[];
  @ApiProperty() total: number;
  @ApiProperty() page: number;
  @ApiProperty() limit: number;
}
