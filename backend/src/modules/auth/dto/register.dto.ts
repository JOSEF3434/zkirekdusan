// src/modules/auth/dto/register.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsPhoneNumber,
  IsString,
  Matches,
  MinLength,
  ValidateIf,
} from 'class-validator';
import { Transform } from 'class-transformer';

/**
 * Register DTO — flexible account creation:
 *
 * - email: optional (but recommended; normalized to lowercase)
 * - phoneNumber: optional (must be E.164 format if provided)
 * - AT LEAST ONE of email or phoneNumber must be supplied
 * - username: required, alphanumeric + underscore/hyphen, 3–32 characters
 * - password: required, minimum 8 characters
 *
 * Examples:
 *   { email, password }
 *   { phoneNumber, password }
 *   { email, phoneNumber, password }
 *   { email, username, firstName, lastName, password }
 */
export class RegisterDto {
  @ApiPropertyOptional({
    example: 'user@example.com',
    description: 'Email address (required if phoneNumber is not provided)',
  })
  @IsOptional()
  @IsEmail({}, { message: 'email must be a valid email address' })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.toLowerCase().trim() : value,
  )
  email?: string;

  @ApiPropertyOptional({
    example: '+12025550123',
    description:
      'Phone number in E.164 format (required if email is not provided)',
  })
  @IsOptional()
  @IsPhoneNumber(undefined, {
    message:
      'phoneNumber must be a valid E.164 phone number (e.g. +12025550123)',
  })
  phoneNumber?: string;

  @ApiPropertyOptional({
    example: 'johndoe',
    description: 'Unique username (3–32 chars, alphanumeric, _ or -)',
  })
  @IsOptional()
  @IsString()
  @MinLength(3, { message: 'Username must be at least 3 characters' })
  @Matches(/^[a-zA-Z0-9_-]+$/, {
    message:
      'Username can only contain letters, numbers, underscores and hyphens',
  })
  username?: string;

  @ApiPropertyOptional({
    example: 'John',
    description: 'First name',
  })
  @IsOptional()
  @IsString()
  firstName?: string;

  @ApiPropertyOptional({
    example: 'Doe',
    description: 'Last name',
  })
  @IsOptional()
  @IsString()
  lastName?: string;

  @ApiProperty({ example: 'StrongP@ssw0rd!' })
  @IsString()
  @IsNotEmpty({ message: 'password is required' })
  @MinLength(8, { message: 'Password must be at least 8 characters long' })
  password!: string;

  /**
   * Cross-field validation: at least one of email or phoneNumber must be provided.
   * These getters are picked up by class-validator @ValidateIf decorators.
   */
  @ValidateIf((o: RegisterDto) => !o.phoneNumber)
  @IsNotEmpty({ message: 'Provide at least one of email or phoneNumber' })
  get _emailRequired(): string | undefined {
    return this.email;
  }

  @ValidateIf((o: RegisterDto) => !o.email)
  @IsNotEmpty({ message: 'Provide at least one of email or phoneNumber' })
  get _phoneRequired(): string | undefined {
    return this.phoneNumber;
  }
}
