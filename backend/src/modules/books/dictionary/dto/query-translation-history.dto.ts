// src/modules/books/dictionary/dto/query-translation-history.dto.ts
import { IsString, IsOptional, IsInt, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class QueryTranslationHistoryDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  sourceLanguage?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  targetLanguage?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  dictionaryBookId?: string;

  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page: number = 1;

  @ApiPropertyOptional({ default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit: number = 20;

  @ApiPropertyOptional({ enum: ['newest', 'oldest'], default: 'newest' })
  @IsOptional()
  @IsString()
  sort: 'newest' | 'oldest' = 'newest';
}

