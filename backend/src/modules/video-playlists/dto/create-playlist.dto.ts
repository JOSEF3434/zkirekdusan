// src/modules/video-playlists/dto/create-playlist.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsEnum,
  MaxLength,
  MinLength,
  IsArray,
} from 'class-validator';
import { PlaylistVisibility } from '@prisma/client';

export class CreatePlaylistDto {
  @ApiProperty({ example: 'My Favorite NestJS Tutorials' })
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  title!: string;

  @ApiPropertyOptional({ example: 'A collection of the best NestJS tutorials' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  description?: string;

  @ApiPropertyOptional({
    enum: PlaylistVisibility,
    default: PlaylistVisibility.PUBLIC,
  })
  @IsOptional()
  @IsEnum(PlaylistVisibility)
  visibility?: PlaylistVisibility;

  @ApiPropertyOptional({
    description: 'Optional Video Channel ID to associate playlist with',
  })
  @IsOptional()
  @IsString()
  videoChannelId?: string;
}

export class AddPlaylistItemDto {
  @ApiProperty({ description: 'Video ID to add to playlist' })
  @IsString()
  videoId!: string;
}

export class ReorderPlaylistItemsDto {
  @ApiProperty({
    description: 'Ordered list of video IDs in the playlist',
    example: ['video-id-1', 'video-id-2'],
  })
  @IsArray()
  @IsString({ each: true })
  videoIds!: string[];
}
