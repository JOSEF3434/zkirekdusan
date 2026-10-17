// src/modules/books/dto/upsert-reading-prefs.dto.ts
import { IsOptional, IsNumber, IsString, IsBoolean, IsInt, Max, Min } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpsertReadingPrefsDto {
  @ApiPropertyOptional({ minimum: 10, maximum: 36 })
  @IsOptional()
  @IsNumber()
  @Min(10)
  @Max(36)
  fontSize?: number;

  @ApiPropertyOptional({ minimum: 1.0, maximum: 3.0 })
  @IsOptional()
  @IsNumber()
  @Min(1.0)
  @Max(3.0)
  lineSpacing?: number;

  @ApiPropertyOptional({ enum: ['default', 'serif', 'sans-serif', 'monospace'] })
  @IsOptional()
  @IsString()
  fontFamily?: string;

  @ApiPropertyOptional({ enum: ['left', 'justify', 'right'] })
  @IsOptional()
  @IsString()
  textAlign?: string;

  @ApiPropertyOptional({ enum: ['light', 'dark', 'system'] })
  @IsOptional()
  @IsString()
  themeMode?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(8)
  @Max(48)
  pageMargin?: number;

  @ApiPropertyOptional({ enum: ['paginated', 'continuous'] })
  @IsOptional()
  @IsString()
  scrollMode?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  gridView?: boolean;

  @ApiPropertyOptional({ enum: ['title', 'author', 'recent', 'progress'] })
  @IsOptional()
  @IsString()
  sortBy?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  sortAsc?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  defaultCategoryId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  defaultHighlightColor?: string;
}
