// src/modules/books/dto/create-book.dto.ts
import {
  IsString,
  IsOptional,
  IsEnum,
  IsInt,
  IsUUID,
  IsArray,
  IsUrl,
  MinLength,
  MaxLength,
  Min,
  Max,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum BookStatusDto {
  DRAFT = 'DRAFT',
  PUBLISHED = 'PUBLISHED',
  ARCHIVED = 'ARCHIVED',
}

export enum BookFormatDto {
  PDF = 'PDF',
  EPUB = 'EPUB',
  TEXT = 'TEXT',
  AUDIO = 'AUDIO',
  EXTERNAL_LINK = 'EXTERNAL_LINK',
}

export enum BookLanguageDto {
  AMHARIC = 'AMHARIC',
  GEEZ = 'GEEZ',
  ENGLISH = 'ENGLISH',
  OTHER = 'OTHER',
}

export class CreateBookDto {
  @ApiProperty()
  @IsString()
  @MinLength(1)
  @MaxLength(300)
  title!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(300)
  titleAm?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(300)
  titleGez?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(300)
  subtitle?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(200)
  author?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(200)
  translator?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(5000)
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @ApiProperty({ enum: BookLanguageDto })
  @IsEnum(BookLanguageDto)
  language!: BookLanguageDto;

  @ApiProperty({ enum: BookFormatDto })
  @IsEnum(BookFormatDto)
  format!: BookFormatDto;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(200)
  publisher?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(1000)
  @Max(2100)
  publishedYear?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(50)
  edition?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(20)
  isbn?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(1)
  pageCount?: number;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];

  @ApiPropertyOptional({ enum: BookStatusDto })
  @IsOptional()
  @IsEnum(BookStatusDto)
  status?: BookStatusDto;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  coverFileId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  contentFileId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  externalUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  sortOrder?: number;
}
