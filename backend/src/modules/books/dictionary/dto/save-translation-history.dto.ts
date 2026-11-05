// src/modules/books/dictionary/dto/save-translation-history.dto.ts
import { IsString, IsOptional, IsUUID, IsInt, MinLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class SaveTranslationHistoryDto {
  @ApiProperty({ example: 'Love' })
  @IsString()
  @MinLength(1)
  word!: string;

  @ApiProperty({ example: 'en' })
  @IsString()
  sourceLanguage!: string;

  @ApiProperty({ example: 'am' })
  @IsString()
  targetLanguage!: string;

  @ApiProperty({ example: 'ፍቅር' })
  @IsString()
  definition!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  dictionaryBookId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  dictionaryEntryId?: string;

  @ApiProperty({ example: 'መዝገበ ቃላት' })
  @IsString()
  dictionaryNameSnapshot!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  pageNumber?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  chapter?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  surroundingSentence?: string;
}

