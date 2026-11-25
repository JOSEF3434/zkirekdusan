import { IsInt, IsOptional, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class DismissReportDto {
  @ApiProperty({ description: 'The revision number being dismissed' })
  @IsInt()
  @Min(1)
  revision!: number;
}
