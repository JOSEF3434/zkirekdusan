// src/modules/messages/dto/send-message.dto.ts
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { MessageType } from '@prisma/client';

export class SendMessageDto {
  @ApiPropertyOptional({ description: 'Text content of the message' })
  @IsOptional()
  @IsString()
  @MaxLength(10000)
  content?: string;

  @ApiProperty({ enum: MessageType, default: MessageType.TEXT })
  @IsEnum(MessageType)
  type: MessageType = MessageType.TEXT;

  @ApiPropertyOptional({ description: 'Reply to message ID (thread)' })
  @IsOptional()
  @IsUUID()
  replyToId?: string;

  @ApiPropertyOptional({ description: 'Attached file IDs' })
  @IsOptional()
  @IsUUID(undefined, { each: true })
  fileIds?: string[];

  @ApiPropertyOptional({ description: 'Forwarded from original message ID' })
  @IsOptional()
  @IsUUID()
  forwardFromMessageId?: string;

  @ApiPropertyOptional({ description: 'Original conversation ID (for forward)' })
  @IsOptional()
  @IsUUID()
  forwardFromConversationId?: string;

  @ApiPropertyOptional({ description: 'Mentioned user IDs in this message' })
  @IsOptional()
  @IsArray()
  @IsUUID(undefined, { each: true })
  mentionedUserIds?: string[];
}
