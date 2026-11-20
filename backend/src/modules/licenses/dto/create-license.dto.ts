import { IsString, IsOptional, IsInt, IsDateString, Min } from 'class-validator';

export class CreateLicenseDto {
  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  maxDevices?: number;

  @IsOptional()
  @IsDateString()
  expiresAt?: string;
}
