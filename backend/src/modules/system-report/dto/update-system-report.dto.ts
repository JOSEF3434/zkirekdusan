import { PartialType } from '@nestjs/swagger';
import { CreateSystemReportDto } from './create-system-report.dto.js';
import { IsEnum, IsOptional } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { SystemReportStatus } from '@prisma/client';

export class UpdateSystemReportDto extends PartialType(CreateSystemReportDto) {
  @ApiPropertyOptional({ enum: SystemReportStatus })
  @IsOptional()
  @IsEnum(SystemReportStatus)
  status?: SystemReportStatus;
}
