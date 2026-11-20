// src/modules/licenses/licenses.controller.ts
import {
  Controller,
  Post,
  Get,
  Patch,
  Param,
  Body,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { LicensesService } from './licenses.service.js';
import { ValidateLicenseDto } from './dto/validate-license.dto.js';
import { ActivateLicenseDto } from './dto/activate-license.dto.js';
import { CreateLicenseDto } from './dto/create-license.dto.js';
import { Public } from '../../common/decorators/public.decorator.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { AppRole } from '../../common/constants/roles.js';

@ApiTags('App License Control')
@Controller('licenses')
export class LicensesController {
  constructor(private readonly service: LicensesService) {}

  // ── Public endpoints (called by the Flutter app, no auth needed) ──────────

  @Public()
  @Post('validate')
  @ApiOperation({ summary: 'Validate device license on app launch' })
  validate(@Body() dto: ValidateLicenseDto) {
    return this.service.validate(dto);
  }

  @Public()
  @Post('activate')
  @ApiOperation({ summary: 'Activate app with an activation code' })
  activate(@Body() dto: ActivateLicenseDto) {
    return this.service.activate(dto);
  }

  // ── Admin-only endpoints ──────────────────────────────────────────────────

  @ApiBearerAuth()
  @Roles(AppRole.ADMIN, AppRole.SUPER_ADMIN)
  @Post('admin')
  @ApiOperation({ summary: 'Admin: generate a new license activation code' })
  create(@Body() dto: CreateLicenseDto) {
    return this.service.createLicense(dto);
  }

  @ApiBearerAuth()
  @Roles(AppRole.ADMIN, AppRole.SUPER_ADMIN)
  @Get('admin')
  @ApiOperation({ summary: 'Admin: list all licenses with device info' })
  listAll() {
    return this.service.listAll();
  }

  @ApiBearerAuth()
  @Roles(AppRole.ADMIN, AppRole.SUPER_ADMIN)
  @Get('admin/:id')
  @ApiOperation({ summary: 'Admin: get a single license' })
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }

  @ApiBearerAuth()
  @Roles(AppRole.ADMIN, AppRole.SUPER_ADMIN)
  @Patch('admin/:id/revoke')
  @ApiOperation({ summary: 'Admin: revoke a license (blocks all its devices)' })
  revoke(@Param('id') id: string) {
    return this.service.revoke(id);
  }

  @ApiBearerAuth()
  @Roles(AppRole.ADMIN, AppRole.SUPER_ADMIN)
  @Patch('admin/devices/:deviceId/deactivate')
  @ApiOperation({ summary: 'Admin: deactivate a specific registered device' })
  deactivateDevice(@Param('deviceId') deviceId: string) {
    return this.service.deactivateDevice(deviceId);
  }
}
