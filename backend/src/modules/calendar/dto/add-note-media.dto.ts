import { IsString, IsInt, IsOptional, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class AddNoteMediaDto {
  @ApiProperty({ example: 'file-uuid', description: 'File ID from uploads' })
  @IsString()
  fileId!: string;

  @ApiProperty({ example: 0, description: 'Display order (0-based)' })
  @IsInt()
  @Min(0)
  order!: number;

  @ApiPropertyOptional({ example: 'Beautiful sunset' })
  @IsOptional()
  @IsString()
  caption?: string;
}
