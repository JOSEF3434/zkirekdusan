// src/modules/channels/dto/create-channel.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
} from 'class-validator';
import { ChannelType } from '@prisma/client';

export class CreateChannelDto {
  @ApiProperty({ example: 'general', description: 'Channel name' })
  @IsString()
  @IsNotEmpty({ message: 'Channel name is required' })
  name!: string;

  @ApiProperty({
    example: 'general',
    description: 'Channel slug (alphanumeric, -, _)',
  })
  @IsString()
  @IsNotEmpty({ message: 'Channel slug is required' })
  @Matches(/^[a-z0-9_-]+$/, {
    message:
      'Slug must contain only lowercase letters, numbers, hyphens, and underscores',
  })
  slug!: string;

  @ApiPropertyOptional({ enum: ChannelType, example: ChannelType.TEXT })
  @IsOptional()
  @IsEnum(ChannelType)
  type?: ChannelType;

  @ApiPropertyOptional({ example: 'General group chat channel' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    example: false,
    description:
      'Default is false (PUBLIC). Set true for PRIVATE channel requiring invitation/approval',
  })
  @IsOptional()
  @IsBoolean()
  isPrivate?: boolean;
}
