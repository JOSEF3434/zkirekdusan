// src/modules/admin/admin-rbac.controller.ts
import {
  Controller,
  Get,
  Put,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { AdminRbacService } from './services/admin-rbac.service.js';

@ApiTags('Admin RBAC')
@Controller('admin/rbac')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
@ApiBearerAuth()
export class AdminRbacController {
  constructor(private readonly rbacService: AdminRbacService) {}

  @Get('roles')
  @ApiOperation({ summary: 'Get all platform roles and their database permissions' })
  async getRoles() {
    return this.rbacService.getRbacRoles();
  }

  @Put('roles/:roleName/permissions')
  @ApiOperation({ summary: 'Update and insert permissions for a specific role into the database' })
  async updateRolePermissions(
    @Param('roleName') roleName: string,
    @Body() body: { permissions: Record<string, boolean> },
    @CurrentUser('sub') actorId: string,
  ) {
    return this.rbacService.updateRolePermissions(
      roleName,
      body.permissions ?? {},
      actorId,
    );
  }
}
