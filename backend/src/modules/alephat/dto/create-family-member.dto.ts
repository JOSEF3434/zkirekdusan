import { IsInt, IsString, IsOptional, Min, Max, IsBoolean, IsArray } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateFamilyMemberDto {
  @ApiProperty({ example: 'ሁ', description: 'Ethiopic character for this order' })
  @IsString()
  glyph!: string;

  @ApiProperty({ example: 2, description: 'Order index (1=ግዕዝ, 2=ካዕብ, 3=ሣልስ, 4=ራብዕ, 5=ኃምስ, 6=ሳድስ, 7=ሳብዕ, 8=ሳምን, 9..13+ for labiovelars/extended)' })
  @IsInt()
  @Min(1)
  @Max(50)
  orderIndex!: number;

  @ApiPropertyOptional({ example: 'ካዕብ', description: 'Traditional order name' })
  @IsOptional()
  @IsString()
  orderName?: string;

  @ApiPropertyOptional({ example: 'ሁ፡ ካዕብ - የሁለተኛው ድምጽ ማብራሪያ', description: 'Individual note for this family member' })
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
