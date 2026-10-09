// src/modules/auth-policy/dto/update-policy.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  ValidateIf,
} from 'class-validator';

export enum LoginPolicyTypeDto {
  SINGLE_IDENTIFIER = 'SINGLE_IDENTIFIER',
  DUAL_IDENTIFIER = 'DUAL_IDENTIFIER',
  ALL_IDENTIFIERS = 'ALL_IDENTIFIERS',
}

export enum DualIdentifierCombinationDto {
  EMAIL_PHONE = 'EMAIL_PHONE',
  EMAIL_USERNAME = 'EMAIL_USERNAME',
  PHONE_USERNAME = 'PHONE_USERNAME',
}

export class UpdateLoginPolicyDto {
  @ApiProperty({
    enum: LoginPolicyTypeDto,
    description: 'The active login policy type to enforce',
    example: LoginPolicyTypeDto.SINGLE_IDENTIFIER,
  })
  @IsEnum(LoginPolicyTypeDto)
  activePolicy!: LoginPolicyTypeDto;

  @ApiPropertyOptional({
    description: 'Allow email as a login identifier (SINGLE_IDENTIFIER mode)',
    example: true,
  })
  @IsBoolean()
  @IsOptional()
  allowEmail?: boolean;

  @ApiPropertyOptional({
    description: 'Allow phone number as a login identifier (SINGLE_IDENTIFIER mode)',
    example: true,
  })
  @IsBoolean()
  @IsOptional()
  allowPhone?: boolean;

  @ApiPropertyOptional({
    description: 'Allow username as a login identifier (SINGLE_IDENTIFIER mode)',
    example: true,
  })
  @IsBoolean()
  @IsOptional()
  allowUsername?: boolean;

  @ApiPropertyOptional({
    enum: DualIdentifierCombinationDto,
    description: 'Required combination for DUAL_IDENTIFIER policy',
    example: DualIdentifierCombinationDto.EMAIL_PHONE,
  })
  @ValidateIf((o: UpdateLoginPolicyDto) => o.activePolicy === LoginPolicyTypeDto.DUAL_IDENTIFIER)
  @IsEnum(DualIdentifierCombinationDto)
  dualCombination?: DualIdentifierCombinationDto;

  @ApiPropertyOptional({
    description: 'Optional admin-provided reason for the policy change',
    maxLength: 500,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;

  @ApiPropertyOptional({
    description:
      'Explicitly acknowledge that activating this policy may affect existing users who lack the required identifiers',
  })
  @IsOptional()
  @IsBoolean()
  acknowledgeUserImpact?: boolean;
}
