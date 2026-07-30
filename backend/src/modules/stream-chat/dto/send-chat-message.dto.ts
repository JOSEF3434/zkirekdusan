import { IsString, IsNotEmpty, MaxLength, IsOptional, IsEnum, IsInt, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { StreamChatMessageType } from '@prisma/client';

export class SendChatMessageDto {
  @ApiProperty({ example: 'Hello stream!', description: 'Message content' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  content!: string;

  @ApiPropertyOptional({
    enum: StreamChatMessageType,
    default: StreamChatMessageType.TEXT,
  })
  @IsOptional()
  @IsEnum(StreamChatMessageType)
  type?: StreamChatMessageType;

  @ApiPropertyOptional({ example: 'uuid', description: 'ID of message being replied to' })
  @IsOptional()
  @IsString()
  replyToId?: string;

  @ApiPropertyOptional({ example: 500, description: 'Super chat amount in cents' })
  @IsOptional()
  @IsInt()
  @Min(100)
  superChatAmount?: number;

  @ApiPropertyOptional({ example: 'USD', description: 'Super chat currency' })
  @IsOptional()
  @IsString()
  @MaxLength(3)
  superChatCurrency?: string;
}
