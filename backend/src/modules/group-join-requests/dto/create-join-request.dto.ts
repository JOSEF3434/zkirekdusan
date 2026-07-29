// src/modules/group-join-requests/dto/create-join-request.dto.ts
import { IsOptional, IsString, MaxLength } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class CreateJoinRequestDto {
  @ApiPropertyOptional({ description: 'Optional note/message to the group admin' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
