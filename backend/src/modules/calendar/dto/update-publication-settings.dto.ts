import { IsBoolean, IsEnum, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CalendarReminderRepeat } from './create-calendar-note.dto.js';

export class UpdatePublicationSettingsDto {
  @ApiProperty({ enum: CalendarReminderRepeat, example: 'MONTHLY' })
  @IsEnum(CalendarReminderRepeat)
  recurrenceType!: CalendarReminderRepeat;

  @ApiProperty({ example: true, description: 'Whether automatic publication is enabled' })
  @IsBoolean()
  isAutoPublishEnabled!: boolean;

  @ApiPropertyOptional({ example: '12:00', description: 'Local publication time (HH:mm)' })
  @IsOptional()
  @IsString()
  autoPublishTime?: string;
}
