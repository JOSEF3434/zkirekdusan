// src/modules/books/dto/book-download-setting.dto.ts
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';

export enum BookDownloadDestinationDto {
  IN_APP = 'IN_APP',
  DEVICE_FILE_MANAGER = 'DEVICE_FILE_MANAGER',
  BOTH = 'BOTH',
}

export class UpdateBookDownloadSettingDto {
  @ApiProperty({
    enum: BookDownloadDestinationDto,
    example: BookDownloadDestinationDto.IN_APP,
    description:
      'Target storage destination for downloaded books: IN_APP (default), DEVICE_FILE_MANAGER, or BOTH',
  })
  @IsEnum(BookDownloadDestinationDto)
  destination!: BookDownloadDestinationDto;

  @ApiPropertyOptional({
    example: 'Policy configured for mobile offline library and desktop download',
  })
  @IsOptional()
  @Transform(({ value }) => (value === '' || value === null ? undefined : value))
  @IsString()
  @MaxLength(500)
  description?: string;
}

export class BookDownloadSettingResponseDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ enum: BookDownloadDestinationDto, example: BookDownloadDestinationDto.IN_APP })
  destination!: BookDownloadDestinationDto;

  @ApiPropertyOptional({ example: 'Default in-app library download policy' })
  description?: string | null;

  @ApiPropertyOptional({ example: '123e4567-e89b-12d3-a456-426614174000' })
  updatedById?: string | null;

  @ApiProperty({ example: '2026-10-20T10:00:00.000Z' })
  createdAt!: Date;

  @ApiProperty({ example: '2026-10-20T10:00:00.000Z' })
  updatedAt!: Date;
}
