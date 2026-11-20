import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class ValidateLicenseDto {
  @IsString()
  @IsNotEmpty()
  deviceId: string;

  @IsString()
  @IsNotEmpty()
  platform: string;

  @IsOptional()
  @IsString()
  appVersion?: string;
}
