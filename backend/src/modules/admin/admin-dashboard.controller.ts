import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { AdminDashboardService } from './services/admin-dashboard.service.js';

@ApiTags('Admin Dashboard')
@Controller('admin/dashboard')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN, AppRole.MODERATOR, AppRole.SUPPORT)
@ApiBearerAuth()
export class AdminDashboardController {
  constructor(private readonly dashboardService: AdminDashboardService) {}

  @Get('metrics')
  @ApiOperation({ summary: 'Get comprehensive platform metrics and stats' })
  async getMetrics() {
    return this.dashboardService.getPlatformMetrics();
  }

  @Get('summary')
  @ApiOperation({ summary: 'Get executive dashboard summary' })
  async getSummary() {
    return this.dashboardService.getPlatformMetrics();
  }
}
