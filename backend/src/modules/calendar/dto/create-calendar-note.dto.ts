import {
  IsInt,
  IsString,
  IsOptional,
  Min,
  Max,
  IsDateString,
  IsBoolean,
  IsEnum,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum CalendarReminderRepeat {
  NONE = 'NONE',
  MONTHLY = 'MONTHLY',
  YEARLY = 'YEARLY',
}

export class CreateCalendarNoteDto {
  @ApiProperty({ example: 2017, description: 'Ethiopian year' })
  @IsInt()
  @Min(1900)
  @Max(2200)
  ethiopianYear!: number;

  @ApiProperty({ example: 1, description: 'Ethiopian month (1-13)' })
  @IsInt()
  @Min(1)
  @Max(13)
  ethiopianMonth!: number;

  @ApiProperty({ example: 15, description: 'Ethiopian day (1-30)' })
  @IsInt()
  @Min(1)
  @Max(30)
  ethiopianDay!: number;

  @ApiProperty({
    example: '2024-09-22T00:00:00.000Z',
    description: 'Gregorian date equivalent',
  })
  @IsDateString()
  gregorianDate!: string;

  @ApiPropertyOptional({ example: 'My Note Title' })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional({ example: 'Note content goes here' })
  @IsOptional()
  @IsString()
  content?: string;

  @ApiPropertyOptional({ example: false, description: 'Enable reminder' })
  @IsOptional()
  @IsBoolean()
  hasReminder?: boolean;

  @ApiPropertyOptional({
    example: '2024-09-22T08:00:00.000Z',
    description: 'Reminder date and time',
  })
  @IsOptional()
  @IsDateString()
  reminderDateTime?: string;

  @ApiPropertyOptional({ enum: CalendarReminderRepeat })
  @IsOptional()
  @IsEnum(CalendarReminderRepeat)
  reminderRepeat?: CalendarReminderRepeat;

  @ApiPropertyOptional({ example: 4 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(13)
  reminderEthiopianMonth?: number;

  @ApiPropertyOptional({ example: 13 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(30)
  reminderEthiopianDay?: number;

  @ApiPropertyOptional({ example: 12 })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(23)
  reminderHour?: number;

  @ApiPropertyOptional({ example: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(59)
  reminderMinute?: number;

  @ApiPropertyOptional({ example: 'Africa/Addis_Ababa' })
  @IsOptional()
  @IsString()
  reminderTimezone?: string;
}
