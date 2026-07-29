// src/modules/auth/dto/auth-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class UserSummaryDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiPropertyOptional({ example: 'user@example.com', nullable: true })
  email?: string | null;

  @ApiPropertyOptional({ example: '+12025550123', nullable: true })
  phoneNumber?: string | null;

  @ApiProperty({ example: 'johndoe' })
  username!: string;

  @ApiProperty({ example: 'USER' })
  role!: string;
}

export class AuthResponseDto {
  @ApiProperty({ type: UserSummaryDto })
  user!: UserSummaryDto;

  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' })
  accessToken!: string;

  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' })
  refreshToken!: string;
}
