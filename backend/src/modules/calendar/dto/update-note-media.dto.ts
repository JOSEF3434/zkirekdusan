import { IsString, IsInt, IsOptional, Min } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateNoteMediaDto {
  @ApiPropertyOptional({ example: 1, description: 'New display order' })
  @IsOptional()
  @IsInt()
  @Min(0)
  order?: number;

  @ApiPropertyOptional({ example: 'Updated caption' })
  @IsOptional()
  @IsString()
  caption?: string;
}
