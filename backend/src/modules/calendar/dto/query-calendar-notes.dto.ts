import { IsInt, IsOptional, Min, Max } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';

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
}
