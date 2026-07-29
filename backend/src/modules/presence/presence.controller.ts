// src/modules/presence/presence.controller.ts
import { Body, Controller, Get, Param, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString } from 'class-validator';
import { PresenceStatus } from '@prisma/client';
import { PresenceService } from './presence.service.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

class UpdatePresenceDto {
  @ApiProperty({ enum: PresenceStatus })
  @IsEnum(PresenceStatus)
  status!: PresenceStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  customStatus?: string;
}

@ApiTags('Presence')
@ApiBearerAuth()
@Controller('presence')
export class PresenceController {
  constructor(private readonly presenceService: PresenceService) {}

  @Put()
  @ApiOperation({ summary: 'Update your presence status (ONLINE/OFFLINE/IDLE/BUSY)' })
  async updatePresence(
    @Body() dto: UpdatePresenceDto,
    @CurrentUser('sub') userId: string,
  ) {
    return this.presenceService.setStatus(userId, dto.status, dto.customStatus);
  }

  @Get(':userId')
  @ApiOperation({ summary: "Get a user's current presence" })
  async getPresence(@Param('userId') userId: string) {
    return this.presenceService.getPresence(userId);
  }
}
