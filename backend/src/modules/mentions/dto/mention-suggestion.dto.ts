// src/modules/mentions/dto/mention-suggestion.dto.ts
import { IsOptional, IsString, Min, Max, IsInt } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class MentionQueryDto {
  @ApiPropertyOptional({ description: 'Search query (after @)' })
  @IsOptional()
  @IsString()
  q?: string;

  @ApiPropertyOptional({ default: 10 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(25)
  @Type(() => Number)
  limit?: number = 10;
}

export class MentionSuggestionDto {
  id!: string;
  type!: 'user' | 'group' | 'channel';
  username!: string; // canonical handle/label used in mention token (without leading @)
  displayName!: string;
  avatarUrl?: string;
  isVerified?: boolean;
  subtitle?: string;
}
