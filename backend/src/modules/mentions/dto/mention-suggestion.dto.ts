// src/modules/mentions/dto/mention-suggestion.dto.ts
import { IsOptional, IsString, Min, Max, IsInt } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class MentionQueryDto {
  @ApiPropertyOptional({ description: 'Search query (after @)' })
  @IsOptional()
  @IsString()
  q?: string;

  @ApiPropertyOptional({ default: 8 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(20)
  @Type(() => Number)
  limit?: number = 8;
}

export class MentionSuggestionDto {
  id!: string;
  type!: 'user' | 'group' | 'channel';
  username!: string;      // unique handle used in mention token
  displayName!: string;
  avatarUrl?: string;
  isVerified?: boolean;
}
