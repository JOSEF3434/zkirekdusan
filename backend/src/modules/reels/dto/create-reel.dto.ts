// src/modules/reels/dto/create-reel.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsNotEmpty, IsNumber, IsOptional, IsString, IsUUID } from 'class-validator';

export class CreateReelDto {
  @ApiProperty({ example: 'file-uuid', description: 'Uploaded video file ID' })
  @IsUUID()
  @IsNotEmpty({ message: 'fileId is required' })
  fileId!: string;

  @ApiPropertyOptional({ example: 'https://cdn.example.com/thumbnail.jpg' })
  @IsOptional()
  @IsString()
  thumbnailUrl?: string;

  @ApiPropertyOptional({ example: 'Check out this awesome video! #viral #reels' })
  @IsOptional()
  @IsString()
  caption?: string;

  @ApiPropertyOptional({ example: ['#viral', '#reels'], type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  hashtags?: string[];

  @ApiProperty({ example: 15.5, description: 'Duration in seconds' })
  @IsNumber()
  duration!: number;
}
