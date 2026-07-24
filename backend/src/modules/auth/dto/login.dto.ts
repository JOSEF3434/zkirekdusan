// src/modules/dto/login.dto.ts

import { IsNotEmpty, MinLength } from 'class-validator';
import { IsEmail, IsString } from 'class-validator';
export class LoginDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(6)
  @IsNotEmpty()
  password!: string;
}
