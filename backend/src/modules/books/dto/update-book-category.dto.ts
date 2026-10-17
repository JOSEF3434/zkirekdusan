// src/modules/books/dto/update-book-category.dto.ts
import { PartialType } from '@nestjs/swagger';
import { CreateBookCategoryDto } from './create-book-category.dto.js';
import { IsBoolean, IsOptional } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateBookCategoryDto extends PartialType(CreateBookCategoryDto) {
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isArchived?: boolean;
}
