import {
  IsString,
  IsNotEmpty,
  MaxLength,
  IsOptional,
  IsInt,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class MuteUserDto {
  @ApiProperty({ example: 300, description: 'Duration in seconds' })
  @IsInt()
  @Min(60)
  durationSeconds!: number;

  @ApiPropertyOptional({ example: 'Spamming the chat' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  reason?: string;
}

export class BanUserDto {
  @ApiPropertyOptional({ example: 'Hate speech' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  reason?: string;
}
