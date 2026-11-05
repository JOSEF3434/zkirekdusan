// src/modules/books/dto/create-book.dto.ts
import {
  IsString,
  IsOptional,
  IsEnum,
  IsInt,
  IsUUID,
  IsArray,
  IsBoolean,
  MinLength,
  MaxLength,
  Min,
  Max,
  ValidateNested,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { BookAttachmentItemDto } from './book-attachment.dto.js';

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
  @Transform(({ value }) => (value === '' || value === null ? undefined : value))
  @IsString()
  @MaxLength(300)
  titleAm?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (value === '' || value === null ? undefined : value))
  @IsString()
  @MaxLength(300)
  titleGez?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (value === '' || value === null ? undefined : value))
  @IsString()
  @MaxLength(300)
  subtitle?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (value === '' || value === null ? undefined : value))
  @IsString()
  @MaxLength(200)
  author?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (value === '' || value === null ? undefined : value))
  @IsString()
  @MaxLength(200)
  translator?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (value === '' || value === null ? undefined : value))
  @IsString()
  @MaxLength(5000)
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (value === '' || value === null ? undefined : value))
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
  @Transform(({ value }) => (value === '' || value === null ? undefined : value))
  @IsString()
  @MaxLength(200)
  publisher?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => {
    if (value === '' || value === null || value === undefined) return undefined;
    const num = Number(value);
    return isNaN(num) ? value : num;
  })
  @IsInt()
  @Min(1000)
  @Max(2100)
  publishedYear?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (value === '' || value === null ? undefined : value))
  @IsString()
  @MaxLength(50)
  edition?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (value === '' || value === null ? undefined : value))
  @IsString()
  @MaxLength(20)
  isbn?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => {
    if (value === '' || value === null || value === undefined) return undefined;
    const num = Number(value);
    return isNaN(num) ? value : num;
  })
  @IsInt()
  @Min(1)
  pageCount?: number;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @Transform(({ value }) => {
    if (value === '' || value === null || value === undefined) return [];
    if (typeof value === 'string') {
      return value.split(',').map((t: string) => t.trim()).filter(Boolean);
    }
    return value;
  })
  @IsArray()
  @IsString({ each: true })
  tags?: string[];

  @ApiPropertyOptional({ enum: BookStatusDto })
  @IsOptional()
  @Transform(({ value }) => (value === '' || value === null ? undefined : value))
  @IsEnum(BookStatusDto)
  status?: BookStatusDto;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (value === '' || value === null ? undefined : value))
  @IsUUID()
  coverFileId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (value === '' || value === null ? undefined : value))
  @IsUUID()
  contentFileId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (value === '' || value === null ? undefined : value))
  @IsString()
  externalUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => {
    if (value === '' || value === null || value === undefined) return undefined;
    const num = Number(value);
    return isNaN(num) ? value : num;
  })
  @IsInt()
  sortOrder?: number;

  @ApiPropertyOptional({ type: [BookAttachmentItemDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => BookAttachmentItemDto)
  attachments?: BookAttachmentItemDto[];

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  @IsBoolean()
  isDictionary?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(200)
  dictionaryName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  dictionaryDescription?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  sourceLanguageId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  targetLanguageId?: string;
}
