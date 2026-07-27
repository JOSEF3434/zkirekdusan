// src/modules/groups/dto/create-group.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';
import { GroupVisibility } from '@prisma/client';

export class CreateGroupDto {
  @ApiProperty({ example: 'Tech Enthusiasts' })
  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  @MaxLength(100)
  name!: string;

  @ApiProperty({ example: 'tech-enthusiasts' })
  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  @MaxLength(100)
  @Matches(/^[a-z0-9-]+$/, {
    message: 'Slug must be lower-case alphanumeric with hyphens only',
  })
  slug!: string;

  @ApiPropertyOptional({ example: 'A community for technology and software discussions' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  description?: string;

  @ApiPropertyOptional({ enum: GroupVisibility, default: GroupVisibility.PUBLIC })
  @IsOptional()
  @IsEnum(GroupVisibility)
  visibility?: GroupVisibility;
}
