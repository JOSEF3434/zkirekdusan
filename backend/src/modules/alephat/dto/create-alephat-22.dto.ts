import { IsInt, IsString, IsOptional, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateAlephat22Dto {
  @ApiProperty({ example: 'አ', description: 'Letter glyph' })
  @IsString()
  letter!: string;

  @ApiProperty({ example: 'አሌፍ (አ)', description: 'Title of the Alephat entry' })
  @IsString()
  title!: string;

  @ApiPropertyOptional({ example: 'አምላክ / መጀመሪያ', description: 'Traditional/spiritual meaning' })
  @IsOptional()
  @IsString()
  meaning?: string;

  @ApiPropertyOptional({ example: 1, description: 'Order (1 to 22)' })
  @IsOptional()
  @IsInt()
  order?: number;

  @ApiProperty({
    example: 'አሌፍ ማለት አምላክ ወይም መጀመሪያ ማለት ነው። እግዚአብሔር የሁሉ መጀመሪያ መሆኑን ያመለክታል።',
    description: 'Detailed explanatory note',
  })
  @IsString()
  note!: string;

  @ApiPropertyOptional({
    example: 'በመዝሙረ ዳዊት (መዝ. 119/118) እያንዳንዱ አንቀጽ በዕብራይስጥና በግዕዝ አሌፋት ቅደም ተከተል ተከፍሏል።',
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
