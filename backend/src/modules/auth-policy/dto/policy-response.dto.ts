// src/modules/auth-policy/dto/policy-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class LoginPolicyResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty({
    enum: ['SINGLE_IDENTIFIER', 'DUAL_IDENTIFIER', 'ALL_IDENTIFIERS'],
    description: 'Active login policy type',
  })
  activePolicy!: string;

  @ApiProperty({ description: 'Email allowed as identifier' })
  allowEmail!: boolean;

  @ApiProperty({ description: 'Phone number allowed as identifier' })
  allowPhone!: boolean;

  @ApiProperty({ description: 'Username allowed as identifier' })
  allowUsername!: boolean;

  @ApiPropertyOptional({
    enum: ['EMAIL_PHONE', 'EMAIL_USERNAME', 'PHONE_USERNAME'],
    nullable: true,
  })
  dualCombination?: string | null;

  @ApiProperty({ description: 'Whether the login policy is locked from routine updates' })
  isLocked!: boolean;

  @ApiProperty({ description: 'Timestamp of last update' })
  updatedAt!: Date;
}

/** Safe public-facing config — only exposes fields needed by the login form */
export class PublicLoginPolicyDto {
  @ApiProperty({ enum: ['SINGLE_IDENTIFIER', 'DUAL_IDENTIFIER', 'ALL_IDENTIFIERS'] })
  activePolicy!: string;

  @ApiProperty()
  allowEmail!: boolean;

  @ApiProperty()
  allowPhone!: boolean;

  @ApiProperty()
  allowUsername!: boolean;

  @ApiPropertyOptional({ enum: ['EMAIL_PHONE', 'EMAIL_USERNAME', 'PHONE_USERNAME'], nullable: true })
  dualCombination?: string | null;
}
