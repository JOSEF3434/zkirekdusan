// src/modules/messages/dto/add-reaction.dto.ts
import { IsString, MaxLength, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AddReactionDto {
  @ApiProperty({ description: 'Emoji character for the reaction', example: '👍' })
  @IsString()
  @MinLength(1)
  @MaxLength(10)
  emoji: string;
}
