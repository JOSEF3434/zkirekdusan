// src/modules/books/dictionary/dto/translate-word.dto.ts
import { IsString, IsOptional, IsUUID, MinLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class TranslateWordDto {
  @ApiProperty({ description: 'Word or phrase to translate', example: 'Love' })
  @IsString()
  @MinLength(1)
  word!: string;

  @ApiPropertyOptional({ description: 'Specific dictionary book ID to search within' })
  @IsOptional()
  @IsUUID()
  bookId?: string;

  @ApiPropertyOptional({ description: 'Source language code', example: 'en' })
  @IsOptional()
  @IsString()
  sourceLanguage?: string;

  @ApiPropertyOptional({ description: 'Target language code', example: 'am' })
  @IsOptional()
  @IsString()
  targetLanguage?: string;
}

