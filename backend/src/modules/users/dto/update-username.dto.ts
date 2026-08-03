import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, Matches, MinLength } from 'class-validator';

export class UpdateUsernameDto {
  @ApiProperty({
    example: 'johndoe',
    description: 'Unique username (3–32 chars, alphanumeric, _ or -)',
  })
  @IsString()
  @IsNotEmpty({ message: 'username is required' })
  @MinLength(3, { message: 'Username must be at least 3 characters' })
  @Matches(/^[a-zA-Z0-9_-]+$/, {
    message:
      'Username can only contain letters, numbers, underscores and hyphens',
  })
  username!: string;
}
