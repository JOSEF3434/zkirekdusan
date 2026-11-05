// src/modules/books/dictionary/dto/update-dictionary-config.dto.ts
import { IsString, IsOptional, IsUUID, MinLength, MaxLength } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateDictionaryConfigDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(200)
  dictionaryName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  sourceLanguageId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  targetLanguageId?: string;
}

