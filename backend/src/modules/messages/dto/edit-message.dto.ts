// src/modules/messages/dto/edit-message.dto.ts
import { IsString, MaxLength, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class EditMessageDto {
  @ApiProperty({ description: 'New message content' })
  @IsString()
  @MinLength(1)
  @MaxLength(10000)
  content!: string;
}
