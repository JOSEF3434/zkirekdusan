// src/modules/auth/dto/forgot-password.dto.ts
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsEnum, IsOptional, IsString } from 'class-validator';
import { RecoveryMethodType } from './recovery.dto.js';

export class ForgotPasswordDto {
  @ApiPropertyOptional({
    enum: RecoveryMethodType,
    example: RecoveryMethodType.EMAIL,
  })
  @IsOptional()
  @IsEnum(RecoveryMethodType)
  method?: RecoveryMethodType;

  @ApiPropertyOptional({
    example: 'user@example.com',
    description: 'Email address or Ethiopian phone number',
  })
  @IsOptional()
  @IsString()
  identifier?: string;

  @ApiPropertyOptional({
    example: 'user@example.com',
  })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({
    example: '+251911223344',
  })
  @IsOptional()
  @IsString()
  phoneNumber?: string;
}

export { RecoveryMethodType } from './recovery.dto.js';
