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
 *  - Username + password
 *
 * Exactly ONE of `email`, `phoneNumber`, or `username` should ideally be provided, but at least ONE is required.
 *
 * Phone numbers must be in E.164 format (e.g. +1234567890).
 */
export class LoginDto {
  @ApiPropertyOptional({
    example: 'user@example.com',
    description:
      'User email address (provide either email, phoneNumber, or username)',
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
      'Phone number in E.164 format (provide either email, phoneNumber, or username)',
  })
  @IsOptional()
  @IsPhoneNumber(undefined, {
    message:
      'phoneNumber must be a valid E.164 phone number (e.g. +12025550123)',
  })
  phoneNumber?: string;

  @ApiPropertyOptional({
    example: 'johndoe',
    description:
      'Username (provide either email, phoneNumber, or username)',
  })
  @IsOptional()
  @IsString()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.toLowerCase().trim() : value,
  )
  username?: string;

  @ApiProperty({ example: 'StrongP@ssw0rd!' })
  @IsString()
  @IsNotEmpty({ message: 'password is required' })
  password!: string;

  /**
   * Custom validator: at least one of email, phoneNumber, or username must be present.
   */
  @ValidateIf((o: LoginDto) => !o.phoneNumber && !o.username)
  @IsNotEmpty({ message: 'Provide either email, phoneNumber, or username to login' })
  get _emailRequired(): string | undefined {
    return this.email;
  }

  @ValidateIf((o: LoginDto) => !o.email && !o.username)
  @IsNotEmpty({ message: 'Provide either email, phoneNumber, or username to login' })
  get _phoneRequired(): string | undefined {
    return this.phoneNumber;
  }

  @ValidateIf((o: LoginDto) => !o.email && !o.phoneNumber)
  @IsNotEmpty({ message: 'Provide either email, phoneNumber, or username to login' })
  get _usernameRequired(): string | undefined {
    return this.username;
  }
}
