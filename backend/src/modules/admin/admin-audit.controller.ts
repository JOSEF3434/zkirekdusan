import { Controller, Get, UseGuards, Query } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { AdminAuditService } from './services/admin-audit.service.js';

@ApiTags('Audit Logs')
@Controller('admin/audit')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
@ApiBearerAuth()
export class AdminAuditController {
  constructor(private readonly auditService: AdminAuditService) {}

  @Get()
  @ApiOperation({
    summary: 'Get system audit logs with pagination and filters',
  })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 30 })
  @ApiQuery({ name: 'actorId', required: false })
  @ApiQuery({ name: 'action', required: false })
  @ApiQuery({ name: 'targetType', required: false })
  async getAuditLogs(
    @Query('page') page = 1,
    @Query('limit') limit = 30,
    @Query('actorId') actorId?: string,
    @Query('action') action?: string,
    @Query('targetType') targetType?: string,
  ) {
    return this.auditService.listAuditLogs({
      page,
      limit,
      actorId,
      action,
      targetType,
    });
  }
}
