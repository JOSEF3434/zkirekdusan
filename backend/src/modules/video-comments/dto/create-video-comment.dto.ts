// src/modules/video-comments/dto/create-video-comment.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, MaxLength, MinLength } from 'class-validator';

export class CreateVideoCommentDto {
  @ApiProperty({ example: 'Great video! Thanks for sharing.' })
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  content!: string;

  @ApiPropertyOptional({ description: 'Parent comment ID for nested reply' })
  @IsOptional()
  @IsString()
  parentId?: string;
}
