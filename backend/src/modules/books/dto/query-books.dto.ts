// src/modules/books/dto/query-books.dto.ts
import { IsOptional, IsString, IsEnum, IsInt, Min, IsBoolean } from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { BookStatusDto, BookFormatDto, BookLanguageDto } from './create-book.dto.js';

export class QueryBooksDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  categoryId?: string;

  @ApiPropertyOptional({ enum: BookStatusDto })
  @IsOptional()
  @IsEnum(BookStatusDto)
  status?: BookStatusDto;

  @ApiPropertyOptional({ enum: BookFormatDto })
  @IsOptional()
  @IsEnum(BookFormatDto)
  format?: BookFormatDto;

  @ApiPropertyOptional({ enum: BookLanguageDto })
  @IsOptional()
  @IsEnum(BookLanguageDto)
  language?: BookLanguageDto;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  tag?: string;

  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number = 20;

  @ApiPropertyOptional({ enum: ['title', 'author', 'createdAt', 'sortOrder', 'publishedYear'] })
  @IsOptional()
  @IsString()
  sortBy?: string = 'sortOrder';

  @ApiPropertyOptional({ enum: ['asc', 'desc'] })
  @IsOptional()
  @IsString()
  sortDir?: 'asc' | 'desc' = 'asc';
}
