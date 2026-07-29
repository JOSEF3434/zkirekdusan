// src/modules/conversations/dto/create-direct-conversation.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsUUID } from 'class-validator';

export class CreateDirectConversationDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000', description: 'Target user ID to start direct 1-on-1 chat' })
  @IsUUID()
  @IsNotEmpty({ message: 'recipientId is required' })
  recipientId!: string;
}
