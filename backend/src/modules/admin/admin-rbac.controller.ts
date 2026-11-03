// src/modules/admin/admin-rbac.controller.ts
import {
  Controller,
  Get,
  Put,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { PermissionsGuard } from '../../common/guards/permissions.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { Permissions } from '../../common/decorators/permissions.decorator.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { AdminRbacService } from './services/admin-rbac.service.js';
import { AdminAuditService } from './services/admin-audit.service.js';

@ApiTags('Admin RBAC')
@Controller('admin/rbac')
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
@ApiBearerAuth()
export class AdminRbacController {
  constructor(
    private readonly rbacService: AdminRbacService,
    private readonly auditService: AdminAuditService,
  ) {}

  @Get('roles')
  @ApiOperation({
    summary: 'Get all platform roles and their database permissions',
  })
  async getRoles() {
    return this.rbacService.getRbacRoles();
  }

  @Get('permissions')
  @ApiOperation({
    summary: 'Get the full platform permission catalogue with metadata',
  })
  async getPermissions() {
    return this.rbacService.getPermissionCatalogue();
  }

  @Put('roles/:roleName/permissions')
  @Permissions('roles.update')
  @ApiOperation({
    summary: 'Update permission assignments for a specific role (database-persisted)',
  })
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

  @Get('audit')
  @Permissions('audit.view')
  @ApiOperation({ summary: 'Get RBAC permission change audit history' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 30 })
  async getRbacAuditHistory(
    @Query('page') page = 1,
    @Query('limit') limit = 30,
  ) {
    return this.auditService.listAuditLogs(
      { targetType: 'ROLE', action: 'RBAC' },
      { page: Number(page), limit: Number(limit) },
    );
  }
}
