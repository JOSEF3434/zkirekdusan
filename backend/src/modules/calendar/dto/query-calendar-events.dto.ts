import { IsOptional, IsInt, IsEnum, IsBoolean, IsString } from 'class-validator';
import { Type, Transform } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { CalendarEventType, CalendarEventCategory } from '@prisma/client';

export class QueryCalendarEventsDto {
  @ApiPropertyOptional({ description: 'Ethiopian year filter' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  year?: number;

  @ApiPropertyOptional({ description: 'Ethiopian month filter (1-13)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  month?: number;

  @ApiPropertyOptional({ description: 'Ethiopian day filter (1-30)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  day?: number;

  @ApiPropertyOptional({ enum: CalendarEventType, description: 'Filter by event type (FAST or HOLIDAY)' })
  @IsOptional()
  @IsEnum(CalendarEventType)
  type?: CalendarEventType;

  @ApiPropertyOptional({ enum: CalendarEventCategory, description: 'Filter by event category' })
  @IsOptional()
  @IsEnum(CalendarEventCategory)
  category?: CalendarEventCategory;

  @ApiPropertyOptional({ description: 'Filter by major flag' })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  isMajor?: boolean;

  @ApiPropertyOptional({ description: 'Include inactive events (admin view)' })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  includeInactive?: boolean;

  @ApiPropertyOptional({ description: 'Search term for event name or description' })
  @IsOptional()
  @IsString()
  search?: string;
}
