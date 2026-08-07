// src/modules/notifications/device-tokens.controller.ts
import {
  Controller,
  Post,
  Delete,
  Body,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { IsString, IsIn, IsOptional } from 'class-validator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { PrismaService } from '../../prisma/prisma.service.js';

class RegisterDeviceTokenDto {
  @IsString() token!: string;
  @IsIn(['ANDROID', 'IOS', 'WEB']) platform!: string;
  @IsString() @IsOptional() deviceId?: string;
}

@ApiTags('Device Tokens')
@Controller('device-tokens')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class DeviceTokensController {
  constructor(private readonly prisma: PrismaService) {}

  @Post()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Register FCM device token for push notifications' })
  async register(
    @CurrentUser('sub') userId: string,
    @Body() dto: RegisterDeviceTokenDto,
  ) {
    // Upsert so the same token is refreshed rather than duplicated
    await this.prisma.deviceToken.upsert({
      where: { token: dto.token },
      create: {
        userId,
        token: dto.token,
        platform: dto.platform,
        deviceId: dto.deviceId,
        lastSeenAt: new Date(),
      },
      update: {
        userId,
        platform: dto.platform,
        deviceId: dto.deviceId,
        lastSeenAt: new Date(),
      },
    });
    return { message: 'Device token registered' };
  }

  @Delete(':token')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Remove FCM device token (on logout)' })
  async remove(
    @CurrentUser('sub') userId: string,
    @Param('token') token: string,
  ) {
    await this.prisma.deviceToken.deleteMany({
      where: { token, userId },
    });
  }
}
