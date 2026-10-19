import {
  IsInt,
  IsString,
  IsOptional,
  IsBoolean,
  IsArray,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CreateFamilyMemberDto } from './create-family-member.dto.js';

export class CreateAlephatLetterDto {
  @ApiProperty({ example: 'ሀ', description: 'Base Amharic letter character' })
  @IsString()
  letter!: string;

  @ApiPropertyOptional({ example: 'ሆይ', description: 'Name or title of the base letter' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: 1, description: 'Display order in the alphabet list' })
  @IsOptional()
  @IsInt()
  order?: number;

  @ApiPropertyOptional({
    example: 'ሀ፡ ሆይ ይባላል። የመጀመሪያው የፊደል መገኛ ድምጽ ነው።',
    description: 'General explanatory note for this base letter',
  })
  @IsOptional()
  @IsString()
  defaultNote?: string;

  @ApiPropertyOptional({ example: 'Hä - Pronounced from the throat', description: 'Pronunciation guidance' })
  @IsOptional()
  @IsString()
  pronunciationGuide?: string;

  @ApiPropertyOptional({ example: true, description: 'Publication status' })
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;

  @ApiPropertyOptional({
    type: [CreateFamilyMemberDto],
    description: 'Initial letter family members (orders 1 through 7/8)',
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateFamilyMemberDto)
  familyMembers?: CreateFamilyMemberDto[];
}
