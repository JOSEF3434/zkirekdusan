// src/modules/likes/dto/like-request.dto.ts
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional } from 'class-validator';
import { ReactionType } from '@prisma/client';

export class LikeRequestDto {
  @ApiPropertyOptional({ enum: ReactionType, example: ReactionType.LIKE })
  @IsOptional()
  @IsEnum(ReactionType)
  reaction?: ReactionType;
}
