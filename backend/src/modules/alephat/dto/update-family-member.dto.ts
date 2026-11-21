import { IsInt, IsString, IsOptional, Min, Max, IsBoolean, IsArray } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateFamilyMemberDto {
  @ApiPropertyOptional({ example: 'ሁ', description: 'Ethiopic character for this order' })
  @IsOptional()
  @IsString()
  glyph?: string;

  @ApiPropertyOptional({ example: 2, description: 'Order index (1=ግዕዝ ... 8=ሳምን, 9..13+ for extended)' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(50)
  orderIndex?: number;

  @ApiPropertyOptional({ example: 'ካዕብ', description: 'Traditional order name' })
  @IsOptional()
  @IsString()
  orderName?: string;

  @ApiPropertyOptional({ example: 'ሁ፡ ካዕብ - ማብራሪያ', description: 'Individual note for this family member' })
  @IsOptional()
  @IsString()
  note?: string;

  @ApiPropertyOptional({ example: 'hu', description: 'Pronunciation transliteration' })
  @IsOptional()
  @IsString()
  pronunciation?: string;

  @ApiPropertyOptional({
    type: [String],
    description: 'Attached media URLs for this family member',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  mediaUrls?: string[];

  @ApiPropertyOptional({ example: true, description: 'Publication status' })
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}
