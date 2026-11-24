// src/modules/auth/dto/recovery.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEmail,
  IsEnum,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { Transform } from 'class-transformer';

export enum RecoveryMethodType {
  EMAIL = 'EMAIL',
  PHONE = 'PHONE',
}

/**
 * DTO for requesting password recovery via Email or Ethiopian Phone Number.
 */
export class RecoveryRequestDto {
  @ApiPropertyOptional({
    enum: RecoveryMethodType,
    example: RecoveryMethodType.EMAIL,
    description: 'Preferred recovery method. If omitted, will be inferred from identifier.',
  })
  @IsOptional()
  @IsEnum(RecoveryMethodType)
  method?: RecoveryMethodType;

  @ApiPropertyOptional({
    example: 'user@example.com',
    description: 'Email or Ethiopian phone number (+2519... / 09... / +2517... / 07...)',
  })
  @IsOptional()
  @IsString()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  identifier?: string;

  @ApiPropertyOptional({
    example: 'user@example.com',
    description: 'Explicit email address (alternative to identifier)',
  })
  @IsOptional()
  @IsEmail()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.toLowerCase().trim() : value,
  )
  email?: string;

  @ApiPropertyOptional({
    example: '+251911223344',
    description: 'Explicit Ethiopian phone number (alternative to identifier)',
  })
  @IsOptional()
  @IsString()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  phoneNumber?: string;
}

/**
 * DTO for verifying an OTP code or recovery token.
 */
export class RecoveryVerifyDto {
  @ApiProperty({
    enum: RecoveryMethodType,
    example: RecoveryMethodType.PHONE,
    description: 'Recovery method used',
  })
  @IsNotEmpty()
  @IsEnum(RecoveryMethodType)
  method!: RecoveryMethodType;

  @ApiProperty({
    example: '+251911223344',
    description: 'Normalized phone number or email',
  })
  @IsNotEmpty()
  @IsString()
  destination!: string;

  @ApiPropertyOptional({
    example: '123456',
    description: '6-digit OTP code (for phone recovery)',
  })
  @IsOptional()
  @IsString()
  code?: string;

  @ApiPropertyOptional({
    example: 'd3b07384d113edec49eaa6238ad5ff00',
    description: 'Secret token from email link (for email recovery)',
  })
  @IsOptional()
  @IsString()
  token?: string;
}

/**
 * DTO for resending recovery OTP or email.
 */
export class RecoveryResendDto {
  @ApiProperty({
    enum: RecoveryMethodType,
    example: RecoveryMethodType.PHONE,
  })
  @IsNotEmpty()
  @IsEnum(RecoveryMethodType)
  method!: RecoveryMethodType;

  @ApiProperty({
    example: '+251911223344',
    description: 'Phone number or email address',
  })
  @IsNotEmpty()
  @IsString()
  identifier!: string;
}

/**
 * DTO for completing password reset.
 */
export class RecoveryResetPasswordDto {
  @ApiPropertyOptional({
    enum: RecoveryMethodType,
    example: RecoveryMethodType.PHONE,
  })
  @IsOptional()
  @IsEnum(RecoveryMethodType)
  method?: RecoveryMethodType;

  @ApiPropertyOptional({
    example: '+251911223344',
    description: 'Required if completing phone OTP recovery',
  })
  @IsOptional()
  @IsString()
  destination?: string;

  @ApiPropertyOptional({
    example: '123456',
    description: '6-digit OTP code (for phone recovery)',
  })
  @IsOptional()
  @IsString()
  code?: string;

  @ApiPropertyOptional({
    example: 'd3b07384d113edec49eaa6238ad5ff00',
    description: 'Token from email recovery link or OTP verification result',
  })
  @IsOptional()
  @IsString()
  token?: string;

  @ApiPropertyOptional({
    example: 'd3b07384d113edec49eaa6238ad5ff00',
    description: 'Alias for token',
  })
  @IsOptional()
  @IsString()
  resetToken?: string;

  @ApiProperty({
    example: 'StrongP@ssw0rd!',
    description: 'New password (min 8 chars, uppercase, lowercase, digit, special char)',
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(8, { message: 'Password must be at least 8 characters long' })
  @MaxLength(64)
  @Matches(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_\-#])[A-Za-z\d@$!%*?&_\-#]+$/,
    {
      message:
        'Password must contain uppercase, lowercase, number and special character (@$!%*?&_-#).',
    },
  )
  password!: string;
}
