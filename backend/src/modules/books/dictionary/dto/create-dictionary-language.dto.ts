// src/modules/books/dictionary/dto/create-dictionary-language.dto.ts
import { IsString, IsOptional, IsBoolean, IsInt, MinLength, MaxLength, Matches, IsIn } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateDictionaryLanguageDto {
  @ApiProperty({ example: 'en', description: 'ISO language code' })
  @IsString()
  @MinLength(2)
  @MaxLength(10)
  @Matches(/^[a-z]{2,3}(-[A-Za-z0-9]+)?$/, { message: 'Language code must be lowercase (e.g. en, am, gez, ti, om)' })
  code!: string;

  @ApiProperty({ example: 'English' })
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  name!: string;

  @ApiProperty({ example: 'English' })
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  nativeName!: string;

  @ApiPropertyOptional({ enum: ['ltr', 'rtl'], default: 'ltr' })
  @IsOptional()
  @IsIn(['ltr', 'rtl'])
  direction?: string;

  @ApiPropertyOptional()
  @IsOptional()
  localizedNames?: Record<string, string>;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isEnabled?: boolean;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsInt()
  sortOrder?: number;
}

