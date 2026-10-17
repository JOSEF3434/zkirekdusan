// src/modules/books/dto/create-bookmark.dto.ts
import { IsOptional, IsInt, IsString, Min, MaxLength } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class CreateBookBookmarkDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  page?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  chapter?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(200)
  label?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;
}
