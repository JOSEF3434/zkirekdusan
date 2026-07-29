// src/modules/group-join-requests/dto/join-request-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class JoinRequestResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() groupId!: string;
  @ApiProperty() userId!: string;
  @ApiProperty() username!: string;
  @ApiPropertyOptional() displayName?: string;
  @ApiPropertyOptional() avatarUrl?: string;
  @ApiProperty() status!: string; // PENDING | APPROVED | REJECTED
  @ApiPropertyOptional() note?: string;
  @ApiProperty() createdAt!: Date;
  @ApiPropertyOptional() respondedAt?: Date;
}
