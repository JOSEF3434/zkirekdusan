// src/modules/auth/dto/reset-password.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { RecoveryMethodType } from './recovery.dto.js';

export class ResetPasswordDto {
  @ApiPropertyOptional({
    enum: RecoveryMethodType,
    example: RecoveryMethodType.EMAIL,
  })
  @IsOptional()
  @IsEnum(RecoveryMethodType)
  method?: RecoveryMethodType;

  @ApiPropertyOptional({
    example: '+251911223344',
  })
  @IsOptional()
  @IsString()
  destination?: string;

  @ApiPropertyOptional({
    example: '123456',
  })
  @IsOptional()
  @IsString()
  code?: string;

  @ApiPropertyOptional({
    example: 'a63b...',
    description: 'Token from email recovery link or OTP verify result',
  })
  @IsOptional()
  @IsString()
  token?: string;

  @ApiPropertyOptional({
    example: 'a63b...',
  })
  @IsOptional()
  @IsString()
  resetToken?: string;

  @ApiProperty({
    example: 'StrongP@ssw0rd!',
    description: 'New password (min 8 characters, uppercase, lowercase, number, special char)',
  })
  @IsString()
  @MinLength(8, { message: 'Password must be at least 8 characters long' })
  @MaxLength(64)
  @IsNotEmpty()
  @Matches(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_\-#])[A-Za-z\d@$!%*?&_\-#]+$/,
    {
      message:
        'Password must contain uppercase, lowercase, number and special character (@$!%*?&_-#).',
    },
  )
  password!: string;
}
