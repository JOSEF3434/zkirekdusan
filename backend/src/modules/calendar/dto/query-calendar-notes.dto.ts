import { IsInt, IsOptional, Min, Max, IsString, IsBoolean } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type, Transform } from 'class-transformer';

export class QueryCalendarNotesDto {
  @ApiPropertyOptional({ example: 2017, description: 'Ethiopian year' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1900)
  @Max(2200)
  year?: number;

  @ApiPropertyOptional({
    example: 1,
    description: 'Ethiopian month (1-13)',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(13)
  month?: number;

  @ApiPropertyOptional({
    example: 15,
    description: 'Ethiopian day (1-30)',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(30)
  day?: number;

  // Ethiopian date range filters
  @ApiPropertyOptional({ example: 2018, description: 'Range start Ethiopian year' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1900)
  @Max(2200)
  startYear?: number;

  @ApiPropertyOptional({ example: 3, description: 'Range start Ethiopian month (1-13)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(13)
  startMonth?: number;

  @ApiPropertyOptional({ example: 9, description: 'Range start Ethiopian day (1-30)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(30)
  startDay?: number;

  @ApiPropertyOptional({ example: 2019, description: 'Range end Ethiopian year' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1900)
  @Max(2200)
  endYear?: number;

  @ApiPropertyOptional({ example: 3, description: 'Range end Ethiopian month (1-13)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(13)
  endMonth?: number;

  @ApiPropertyOptional({ example: 9, description: 'Range end Ethiopian day (1-30)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(30)
  endDay?: number;

  @ApiPropertyOptional({ example: '2018-03-09', description: 'Range start formatted (YYYY-MM-DD)' })
  @IsOptional()
  @IsString()
  from?: string;

  @ApiPropertyOptional({ example: '2019-03-09', description: 'Range end formatted (YYYY-MM-DD)' })
  @IsOptional()
  @IsString()
  to?: string;

  @ApiPropertyOptional({ example: '2026-11-18T00:00:00.000Z', description: 'Fetch notes updated since timestamp' })
  @IsOptional()
  @IsString()
  since?: string;

  @ApiPropertyOptional({ example: false, description: 'Include deleted records for reconciliation' })
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  @IsBoolean()
  includeDeleted?: boolean;
}
