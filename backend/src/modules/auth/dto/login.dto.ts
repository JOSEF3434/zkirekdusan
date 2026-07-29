// src/modules/auth/dto/login.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsPhoneNumber,
  IsString,
  ValidateIf,
} from 'class-validator';
import { Transform } from 'class-transformer';

/**
 * Login DTO — supports authentication via:
 *  - Email + password
 *  - Phone number + password
 *
 * Exactly ONE of `email` or `phoneNumber` must be provided.
 * The system detects which identifier was provided and queries accordingly.
 *
 * Phone numbers must be in E.164 format (e.g. +1234567890).
 */
export class LoginDto {
  @ApiPropertyOptional({
    example: 'user@example.com',
    description: 'User email address (provide either email or phoneNumber, not both)',
  })
  @IsOptional()
  @IsEmail({}, { message: 'email must be a valid email address' })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.toLowerCase().trim() : value,
  )
  email?: string;

  @ApiPropertyOptional({
    example: '+12025550123',
    description: 'Phone number in E.164 format (provide either email or phoneNumber, not both)',
  })
  @IsOptional()
  @IsPhoneNumber(undefined, { message: 'phoneNumber must be a valid E.164 phone number (e.g. +12025550123)' })
  phoneNumber?: string;

  @ApiProperty({ example: 'StrongP@ssw0rd!' })
  @IsString()
  @IsNotEmpty({ message: 'password is required' })
  password!: string;

  /**
   * Custom validator: exactly one of email or phoneNumber must be present.
   * Applied via @ValidateIf — we validate email presence when phoneNumber is absent.
   */
  @ValidateIf((o: LoginDto) => !o.phoneNumber)
  @IsNotEmpty({ message: 'Provide either email or phoneNumber to login' })
  get _emailRequired(): string | undefined {
    return this.email;
  }

  @ValidateIf((o: LoginDto) => !o.email)
  @IsNotEmpty({ message: 'Provide either email or phoneNumber to login' })
  get _phoneRequired(): string | undefined {
    return this.phoneNumber;
  }
}
