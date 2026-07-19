// src/modules/dto/login.dto.ts

import { IsNotEmpty } from 'class-validator';
import { IsEmail } from 'class-validator/types/decorator/string/IsEmail.js';
import { MinLength } from 'class-validator/types/decorator/string/MinLength.js';
import { IsString } from 'class-validator/types/decorator/typechecker/IsString.js';

export class LoginDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(6)
  @IsNotEmpty()
  password!: string;
}
