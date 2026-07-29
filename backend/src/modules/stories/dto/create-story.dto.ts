// src/modules/stories/dto/create-story.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, IsUUID } from 'class-validator';
import { StoryType } from '@prisma/client';

export class CreateStoryDto {
  @ApiProperty({ enum: StoryType, example: StoryType.IMAGE })
  @IsEnum(StoryType)
  type!: StoryType;

  @ApiPropertyOptional({ example: 'file-uuid', description: 'File ID for IMAGE or VIDEO story' })
  @IsOptional()
  @IsUUID()
  fileId?: string;

  @ApiPropertyOptional({ example: 'Text caption for story' })
  @IsOptional()
  @IsString()
  content?: string;

  @ApiPropertyOptional({ example: '#ff0055', description: 'Hex background color for text story' })
  @IsOptional()
  @IsString()
  backgroundColor?: string;

  @ApiPropertyOptional({ example: '#ffffff' })
  @IsOptional()
  @IsString()
  textColor?: string;
}
