// src/modules/video-playlists/dto/create-playlist.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsEnum, MaxLength, MinLength } from 'class-validator';
import { PlaylistVisibility } from '@prisma/client';

export class CreatePlaylistDto {
  @ApiProperty({ example: 'My Favorite NestJS Tutorials' })
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  title: string;

  @ApiPropertyOptional({ example: 'A collection of the best NestJS tutorials' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  description?: string;

  @ApiPropertyOptional({ enum: PlaylistVisibility, default: PlaylistVisibility.PUBLIC })
  @IsOptional()
  @IsEnum(PlaylistVisibility)
  visibility?: PlaylistVisibility;

  @ApiPropertyOptional({ description: 'Optional Video Channel ID to associate playlist with' })
  @IsOptional()
  @IsString()
  videoChannelId?: string;
}

export class AddPlaylistItemDto {
  @ApiProperty({ description: 'Video ID to add to playlist' })
  @IsString()
  videoId: string;
}
