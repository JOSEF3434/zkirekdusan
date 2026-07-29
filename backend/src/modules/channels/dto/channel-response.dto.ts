// src/modules/channels/dto/channel-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ChannelType } from '@prisma/client';

export class ChannelResponseDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  groupId!: string;

  @ApiProperty({ example: 'general' })
  name!: string;

  @ApiProperty({ example: 'general' })
  slug!: string;

  @ApiProperty({ enum: ChannelType })
  type!: ChannelType;

  @ApiPropertyOptional({ example: 'General discussion channel', nullable: true })
  description?: string | null;

  @ApiProperty({ example: false })
  isPrivate!: boolean;

  @ApiPropertyOptional({ example: 'conversation-uuid', nullable: true })
  conversationId?: string | null;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  createdAt!: Date;
}
