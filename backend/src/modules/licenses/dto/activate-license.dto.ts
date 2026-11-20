import { IsString, IsNotEmpty, Matches } from 'class-validator';

export class ActivateLicenseDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/, {
    message: 'activationCode must be in format XXXX-XXXX-XXXX-XXXX',
  })
  activationCode: string;

  @IsString()
  @IsNotEmpty()
  deviceId: string;

  @IsString()
  @IsNotEmpty()
  platform: string;

  @IsString()
  @IsNotEmpty()
  appVersion: string;
}
