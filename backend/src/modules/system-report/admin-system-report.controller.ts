import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { SystemReportService } from './system-report.service.js';
import { CreateSystemReportDto } from './dto/create-system-report.dto.js';
import { UpdateSystemReportDto } from './dto/update-system-report.dto.js';
import { UpdateVisibilityDto } from './dto/update-visibility.dto.js';
import {
  CreateServiceCostDto,
  UpdateServiceCostDto,
} from './dto/service-cost.dto.js';
import { SystemReportDisplayMode } from '@prisma/client';

@ApiTags('Admin System Report')
@Controller('admin/system-report')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
@ApiBearerAuth()
export class AdminSystemReportController {
  constructor(private readonly systemReportService: SystemReportService) {}

  @Get('active')
  @ApiOperation({ summary: 'Get current active report or initialize initial draft' })
  async getActiveReport(@CurrentUser('sub') adminId: string) {
    return this.systemReportService.getLatestOrCreate(adminId);
  }

  @Get('overview')
  @ApiOperation({ summary: 'Get live all-over platform overview (users by role, groups, channels, videos, top videos, live streams)' })
  async getPlatformOverview() {
    return this.systemReportService.getPlatformOverview();
  }

  @Get('all')
  @ApiOperation({ summary: 'List all system reports' })
  async getAllReports() {
    return this.systemReportService.getAllReports();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get system report by ID with all administrative fields' })
  async getReportById(@Param('id') id: string) {
    return this.systemReportService.getAdminReportById(id);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new draft system report' })
  async createReport(
    @CurrentUser('sub') adminId: string,
    @Body() dto: CreateSystemReportDto,
  ) {
    return this.systemReportService.createReport(adminId, dto);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update system report data values' })
  async updateReport(
    @CurrentUser('sub') adminId: string,
    @Param('id') id: string,
    @Body() dto: UpdateSystemReportDto,
  ) {
    return this.systemReportService.updateReport(adminId, id, dto);
  }

  @Patch(':id/visibility')
  @ApiOperation({ summary: 'Update global and field visibility controls' })
  async updateVisibility(
    @CurrentUser('sub') adminId: string,
    @Param('id') id: string,
    @Body() dto: UpdateVisibilityDto,
  ) {
    return this.systemReportService.updateVisibility(adminId, id, dto);
  }

  @Post(':id/publish')
  @ApiOperation({ summary: 'Publish system report with revision increment' })
  async publishReport(
    @CurrentUser('sub') adminId: string,
    @Param('id') id: string,
    @Body('displayMode') displayMode?: SystemReportDisplayMode,
  ) {
    return this.systemReportService.publishReport(adminId, id, displayMode);
  }

  @Post(':id/unpublish')
  @ApiOperation({ summary: 'Unpublish system report' })
  async unpublishReport(
    @CurrentUser('sub') adminId: string,
    @Param('id') id: string,
  ) {
    return this.systemReportService.unpublishReport(adminId, id);
  }

  @Get(':id/preview')
  @ApiOperation({ summary: 'Preview exact user-facing filtered output before publishing' })
  async previewPublicReport(@Param('id') id: string) {
    return this.systemReportService.previewPublicReport(id);
  }

  @Post(':id/costs')
  @ApiOperation({ summary: 'Add a new service cost record' })
  async addCostItem(
    @CurrentUser('sub') adminId: string,
    @Param('id') id: string,
    @Body() dto: CreateServiceCostDto,
  ) {
    return this.systemReportService.addCostItem(adminId, id, dto);
  }

  @Put('costs/:costId')
  @ApiOperation({ summary: 'Update a service cost record' })
  async updateCostItem(
    @CurrentUser('sub') adminId: string,
    @Param('costId') costId: string,
    @Body() dto: UpdateServiceCostDto,
  ) {
    return this.systemReportService.updateCostItem(adminId, costId, dto);
  }

  @Delete('costs/:costId')
  @ApiOperation({ summary: 'Delete a service cost record' })
  async deleteCostItem(
    @CurrentUser('sub') adminId: string,
    @Param('costId') costId: string,
  ) {
    return this.systemReportService.deleteCostItem(adminId, costId);
  }
}
