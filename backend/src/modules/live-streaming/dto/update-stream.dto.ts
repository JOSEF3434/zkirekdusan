import { PartialType, OmitType } from '@nestjs/swagger';
import { CreateStreamDto } from './create-stream.dto.js';
import { IsOptional, IsString, IsEnum } from 'class-validator';
import { LiveStreamStatus } from '@prisma/client';

export class UpdateStreamDto extends PartialType(
  OmitType(CreateStreamDto, ['protocol'] as const),
) {
  @IsOptional()
  @IsEnum(LiveStreamStatus)
  status?: LiveStreamStatus;

  @IsOptional()
  @IsString()
  thumbnailUrl?: string;
}
