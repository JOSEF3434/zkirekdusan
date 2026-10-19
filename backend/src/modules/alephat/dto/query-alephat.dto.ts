import { IsOptional, IsString, IsBoolean } from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class QueryAlephatDto {
  @ApiPropertyOptional({ example: 'ሀ', description: 'Search term for letter, title, or note' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ example: false, description: 'Include unpublished items (requires admin/moderator permission)' })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  includeUnpublished?: boolean;
}
