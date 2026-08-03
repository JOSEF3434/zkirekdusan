import { IsOptional, IsString, IsEnum, IsInt, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';

export enum SearchEntityType {
  USERS = 'USERS',
  GROUPS = 'GROUPS',
  CHANNELS = 'CHANNELS',
  POSTS = 'POSTS',
  VIDEOS = 'VIDEOS',
  REELS = 'REELS',
  PLAYLISTS = 'PLAYLISTS',
  STREAMS = 'STREAMS',
}

export class SearchQueryDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  q?: string;

  @ApiPropertyOptional({ enum: SearchEntityType })
  @IsEnum(SearchEntityType)
  @IsOptional()
  type?: SearchEntityType;

  @ApiPropertyOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  @IsOptional()
  page?: number = 1;

  @ApiPropertyOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  @IsOptional()
  limit?: number = 20;
}
