import { IsDateString, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ScheduleStreamDto {
  @ApiProperty({
    example: '2026-08-01T18:00:00Z',
    description: 'ISO scheduled start time',
  })
  @IsNotEmpty()
  @IsDateString()
  scheduledAt!: string;
}
