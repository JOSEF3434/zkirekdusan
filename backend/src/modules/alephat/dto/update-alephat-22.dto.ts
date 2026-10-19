import { IsInt, IsString, IsOptional, IsBoolean } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateAlephat22Dto {
  @ApiPropertyOptional({ example: 'አ', description: 'Letter glyph' })
  @IsOptional()
  @IsString()
  letter?: string;

  @ApiPropertyOptional({ example: 'አሌፍ (አ)', description: 'Title of the Alephat entry' })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional({ example: 'አምላክ / መጀመሪያ', description: 'Traditional/spiritual meaning' })
  @IsOptional()
  @IsString()
  meaning?: string;

  @ApiPropertyOptional({ example: 1, description: 'Order (1 to 22)' })
  @IsOptional()
  @IsInt()
  order?: number;

  @ApiPropertyOptional({
    example: 'አሌፍ ማለት አምላክ ወይም መጀመሪያ ማለት ነው።',
    description: 'Detailed explanatory note',
  })
  @IsOptional()
  @IsString()
  note?: string;

  @ApiPropertyOptional({
    example: 'ተጨማሪ ማብራሪያ',
    description: 'Supplementary theological or grammatical information',
  })
  @IsOptional()
  @IsString()
  supplementaryInfo?: string;

  @ApiPropertyOptional({ example: true, description: 'Publication status' })
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}
