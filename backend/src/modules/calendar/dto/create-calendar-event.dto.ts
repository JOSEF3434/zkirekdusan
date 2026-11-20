import {
  IsString,
  IsOptional,
  IsBoolean,
  IsEnum,
  IsInt,
  Min,
  Max,
  ValidateIf,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CalendarEventType, CalendarEventCategory } from '@prisma/client';

export class CreateCalendarEventDto {
  @ApiProperty({ description: 'Name of the fasting period or holiday (e.g. ጾመ ነቢያት)' })
  @IsString()
  name!: string;

  @ApiPropertyOptional({ description: 'English translation of the name' })
  @IsOptional()
  @IsString()
  nameEn?: string;

  @ApiProperty({ enum: CalendarEventType, description: 'Event type (FAST or HOLIDAY)' })
  @IsEnum(CalendarEventType)
  type!: CalendarEventType;

  @ApiProperty({ enum: CalendarEventCategory, description: 'Event category' })
  @IsEnum(CalendarEventCategory)
  category!: CalendarEventCategory;

  @ApiPropertyOptional({ default: true, description: 'Whether this event recurs annually on the same Ethiopian dates' })
  @IsOptional()
  @IsBoolean()
  isRecurring?: boolean;

  @ApiPropertyOptional({ description: 'Ethiopian year for non-recurring or movable events' })
  @ValidateIf((o) => o.isRecurring === false)
  @IsInt()
  @Min(1)
  ethiopianYear?: number;

  @ApiProperty({ description: 'Ethiopian starting month (1-13)' })
  @IsInt()
  @Min(1)
  @Max(13)
  startMonth!: number;

  @ApiProperty({ description: 'Ethiopian starting day (1-30)' })
  @IsInt()
  @Min(1)
  @Max(30)
  startDay!: number;

  @ApiPropertyOptional({ description: 'Explicit starting year if multi-year' })
  @IsOptional()
  @IsInt()
  startYear?: number;

  @ApiProperty({ description: 'Ethiopian ending month (1-13)' })
  @IsInt()
  @Min(1)
  @Max(13)
  endMonth!: number;

  @ApiProperty({ description: 'Ethiopian ending day (1-30)' })
  @IsInt()
  @Min(1)
  @Max(30)
  endDay!: number;

  @ApiPropertyOptional({ description: 'Explicit ending year if multi-year' })
  @IsOptional()
  @IsInt()
  endYear?: number;

  @ApiPropertyOptional({ description: 'Detailed description' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ description: 'Spiritual and historical meaning' })
  @IsOptional()
  @IsString()
  spiritualMeaning?: string;

  @ApiPropertyOptional({ description: 'Fasting rules, guidelines, prayer hours' })
  @IsOptional()
  @IsString()
  fastingRules?: string;

  @ApiPropertyOptional({ description: 'Primary hex color for UI badge / indicator' })
  @IsOptional()
  @IsString()
  primaryColor?: string;

  @ApiPropertyOptional({ description: 'Optional icon identifier' })
  @IsOptional()
  @IsString()
  icon?: string;

  @ApiPropertyOptional({ default: false, description: 'Whether this is a major canonical fast or major feast' })
  @IsOptional()
  @IsBoolean()
  isMajor?: boolean;

  @ApiPropertyOptional({ default: true, description: 'Whether the event is active' })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
