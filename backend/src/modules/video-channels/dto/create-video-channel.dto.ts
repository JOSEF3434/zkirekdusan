// src/modules/video-channels/dto/create-video-channel.dto.ts
import {
  IsString,
  IsOptional,
  IsArray,
  IsEnum,
  MaxLength,
  MinLength,
  Matches,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { GroupRole } from '../../../common/constants/group-roles.js';
import { DownloadPermission } from '@prisma/client';

export class CreateVideoChannelDto {
  @ApiProperty({ example: 'Tech Tutorials', description: 'Channel display name' })
  @IsString()
  @MinLength(2)
  @MaxLength(100)
  name: string;

  @ApiProperty({ example: 'tech-tutorials', description: 'URL-friendly slug' })
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  @Matches(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, {
    message: 'Slug must be lowercase letters, numbers, and hyphens only',
  })
  slug: string;

  @ApiProperty({ example: '@techtutorials', description: 'Unique @handle for discovery' })
  @IsString()
  @MinLength(3)
  @MaxLength(50)
  @Matches(/^@[a-zA-Z0-9_]+$/, {
    message: 'Handle must start with @ and contain only letters, numbers, and underscores',
  })
  handle: string;

  @ApiPropertyOptional({ example: 'We make tech tutorials for everyone.' })
  @IsOptional()
  @IsString()
  @MaxLength(5000)
  description?: string;

  @ApiPropertyOptional({ enum: GroupRole, default: GroupRole.MEMBER })
  @IsOptional()
  @IsEnum(GroupRole)
  uploadPermission?: GroupRole;

  @ApiPropertyOptional({ enum: DownloadPermission, default: DownloadPermission.MEMBERS_ONLY })
  @IsOptional()
  @IsEnum(DownloadPermission)
  downloadPermission?: DownloadPermission;

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

  @ApiPropertyOptional({ example: 'US' })
  @IsOptional()
  @IsString()
  country?: string;

  @ApiPropertyOptional({ example: 'en' })
  @IsOptional()
  @IsString()
  language?: string;
}
