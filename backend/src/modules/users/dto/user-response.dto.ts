// src/modules/users/dto/user-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class UserResponseDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiPropertyOptional({ example: 'user@example.com', nullable: true })
  email?: string | null;

  @ApiPropertyOptional({ example: '+12025550123', nullable: true })
  phoneNumber?: string | null;

  @ApiProperty({ example: 'johndoe' })
  username!: string | null;

  @ApiProperty({ example: 'USER' })
  role!: string;

  @ApiProperty({ example: 'ACTIVE' })
  status!: string;

  @ApiProperty({ example: true })
  isEmailVerified!: boolean;

  @ApiProperty({ example: false })
  isPhoneVerified!: boolean;

  @ApiPropertyOptional({ example: '2024-01-15T10:00:00.000Z', nullable: true })
  lastLoginAt?: Date | null;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  createdAt!: Date;
}
