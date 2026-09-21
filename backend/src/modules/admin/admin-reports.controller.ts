import {
  Controller,
  Get,
  Patch,
  Post,
  Param,
  UseGuards,
  Body,
  Query,
  DefaultValuePipe,
  ParseIntPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { AdminModerationService } from './services/admin-moderation.service.js';

@ApiTags('Admin Reports')
@Controller('admin/reports')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN, AppRole.MODERATOR)
@ApiBearerAuth()
export class AdminReportsController {
  constructor(private readonly moderationService: AdminModerationService) {}

  @Get()
  @ApiOperation({
    summary: 'Get reports with optional status filter and pagination',
  })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['ALL', 'PENDING', 'REVIEWING', 'RESOLVED', 'DISMISSED'],
  })
  @ApiQuery({ name: 'targetType', required: false })
  @ApiQuery({ name: 'reason', required: false })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 30 })
  async getReports(
    @Query('status') status?: string,
    @Query('targetType') targetType?: string,
    @Query('reason') reason?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page = 1,
    @Query('limit', new DefaultValuePipe(30), ParseIntPipe) limit = 30,
  ) {
    return this.moderationService.getReports({
      status,
      targetType,
      reason,
      page,
      limit,
    });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get report detail by ID' })
  async getReportDetail(@Param('id') id: string) {
    return this.moderationService.getReportDetail(id);
  }

  @Post(':id/action')
  @ApiOperation({
    summary: 'Perform admin action on report (BAN, DEACTIVATE, DISMISS, WARN)',
  })
  async performAction(
    @Param('id') id: string,
    @CurrentUser('sub') adminId: string,
    @Body()
    dto: {
      action:
        | 'BAN_USER'
        | 'DEACTIVATE_USER'
        | 'DISMISS'
        | 'RESOLVE'
        | 'SUSPEND_USER'
        | 'DELETE_CONTENT';
      note?: string;
    },
  ) {
    return this.moderationService.performAction(id, adminId, dto);
  }

  @Patch(':id/resolve')
  @ApiOperation({ summary: 'Resolve or dismiss a report' })
  async resolveReport(
    @Param('id') id: string,
    @CurrentUser('sub') adminId: string,
    @Body() dto: { status: 'RESOLVED' | 'DISMISSED'; actionTaken?: string },
  ) {
    return this.moderationService.resolveReport(id, adminId, dto);
  }
}
