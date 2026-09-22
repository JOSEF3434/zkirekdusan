// src/modules/live-streaming/dto/create-stream.dto.ts
import {
  IsString,
  IsOptional,
  IsArray,
  IsEnum,
  IsBoolean,
  IsInt,
  IsDateString,
  MaxLength,
  MinLength,
  Min,
  Max,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { LiveStreamVisibility, StreamProtocol } from '@prisma/client';
import { Transform } from 'class-transformer';

export class CreateStreamDto {
  @ApiProperty({
    example: 'Building a NestJS App Live',
    description: 'Stream title',
  })
  @IsString()
  @MinLength(3)
  @MaxLength(300)
  title!: string;

  @ApiPropertyOptional({
    example: 'Join us as we build a production-grade NestJS app live!',
  })
  @IsOptional()
  @IsString()
  @MaxLength(5000)
  description?: string;

  @ApiPropertyOptional({
    enum: LiveStreamVisibility,
    default: LiveStreamVisibility.PUBLIC,
    description: 'Stream visibility — PUBLIC, PRIVATE, GROUP_ONLY, or UNLISTED',
  })
  @IsOptional()
  @IsEnum(LiveStreamVisibility)
  visibility?: LiveStreamVisibility;

  @ApiPropertyOptional({
    enum: StreamProtocol,
    default: StreamProtocol.RTMP,
    description: 'Ingest protocol — RTMP (default), WEBRTC, or HLS_PULL',
  })
  @IsOptional()
  @IsEnum(StreamProtocol)
  protocol?: StreamProtocol;

  @ApiPropertyOptional({
    example: ['2026-08-01T18:00:00Z'],
    description: 'ISO scheduled start time',
  })
  @IsOptional()
  @IsDateString()
  scheduledAt?: string;

  @ApiPropertyOptional({
    example: ['technology', 'programming'],
    type: [String],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  categories?: string[];

  @ApiPropertyOptional({ example: ['nestjs', 'typescript'], type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];

  @ApiPropertyOptional({ example: ['#nestjs', '#live'], type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  hashtags?: string[];

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === 'true' || value === true)
  isRecordingEnabled?: boolean;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === 'true' || value === true)
  isDvrEnabled?: boolean;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === 'true' || value === true)
  isReplayEnabled?: boolean;

  @ApiPropertyOptional({ default: true, description: 'Enable live chat' })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === 'true' || value === true)
  isChatEnabled?: boolean;

  @ApiPropertyOptional({
    default: false,
    description: 'Enable slow mode for chat',
  })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === 'true' || value === true)
  isChatSlowMode?: boolean;

  @ApiPropertyOptional({
    default: 0,
    description: 'Slow mode interval in seconds (0 = off)',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(600)
  chatSlowModeSeconds?: number;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === 'true' || value === true)
  isMembersOnlyChat?: boolean;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === 'true' || value === true)
  isSubscribersOnlyChat?: boolean;

  @ApiPropertyOptional({
    default: false,
    description: 'Send broadcast notification to all database users (if false, only followers)',
  })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === 'true' || value === true)
  notifyAllUsers?: boolean;
}

