// src/modules/books/dto/upsert-reading-progress.dto.ts
import { IsOptional, IsInt, IsNumber, IsBoolean, Min, Max } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpsertReadingProgressDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  currentPage?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  currentChapter?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  scrollOffset?: number;

  @ApiPropertyOptional({ minimum: 0, maximum: 100 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  percentComplete?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isCompleted?: boolean;
}
