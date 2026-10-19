import {
  IsInt,
  IsString,
  IsOptional,
  IsBoolean,
  IsArray,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { CreateFamilyMemberDto } from './create-family-member.dto.js';

export class UpdateAlephatLetterDto {
  @ApiPropertyOptional({ example: 'ሀ', description: 'Base Amharic letter character' })
  @IsOptional()
  @IsString()
  letter?: string;

  @ApiPropertyOptional({ example: 'ሆይ', description: 'Name or title of the base letter' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: 1, description: 'Display order in the alphabet list' })
  @IsOptional()
  @IsInt()
  order?: number;

  @ApiPropertyOptional({
    example: 'ሀ፡ ሆይ ይባላል።',
    description: 'General explanatory note for this base letter',
  })
  @IsOptional()
  @IsString()
  defaultNote?: string;

  @ApiPropertyOptional({ example: 'Hä', description: 'Pronunciation guidance' })
  @IsOptional()
  @IsString()
  pronunciationGuide?: string;

  @ApiPropertyOptional({ example: true, description: 'Publication status' })
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;

  @ApiPropertyOptional({
    type: [CreateFamilyMemberDto],
    description: 'Optional replace/sync family members',
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateFamilyMemberDto)
  familyMembers?: CreateFamilyMemberDto[];
}
