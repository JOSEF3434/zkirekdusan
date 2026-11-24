// src/modules/auth/dto/google-auth.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class GoogleAuthDto {
  @ApiProperty({
    description: 'OpenID Connect ID token issued by Google',
    example: 'eyJhbGciOiJSUzI1NiIsImtpZCI6Ij...',
  })
  @IsString()
  @IsNotEmpty({ message: 'idToken must not be empty' })
  idToken!: string;
}

export class GoogleLinkAccountDto {
  @ApiProperty({
    description: 'OpenID Connect ID token issued by Google',
    example: 'eyJhbGciOiJSUzI1NiIsImtpZCI6Ij...',
  })
  @IsString()
  @IsNotEmpty({ message: 'idToken must not be empty' })
  idToken!: string;

  @ApiProperty({
    description:
      'Current account password required to authorize linking an existing account',
    example: 'StrongPassword123!',
  })
  @IsString()
  @MinLength(8, { message: 'Password must be at least 8 characters long' })
  password!: string;
}

export class FederatedIdentityDto {
  @ApiProperty({ example: 'google' })
  provider!: string;

  @ApiProperty({ example: 'user@gmail.com', nullable: true })
  email?: string | null;

  @ApiProperty({ example: '2026-11-24T10:00:00.000Z' })
  createdAt!: Date;
}

export class UserIdentitiesDto {
  @ApiProperty({ example: true, description: 'Whether the account has a password configured' })
  hasPassword!: boolean;

  @ApiProperty({ type: [FederatedIdentityDto], description: 'Connected external identities' })
  identities!: FederatedIdentityDto[];
}
