import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { ReportsService } from './reports.service.js';
import { CreateReportDto } from './dto/create-report.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';

@ApiTags('Reports')
@Controller('reports')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Post()
  @ApiOperation({
    summary: 'Submit a report against a user, group, post, comment or video',
  })
  @ApiResponse({ status: 201, description: 'Report submitted successfully' })
  async createReport(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateReportDto,
  ) {
    return this.reportsService.createReport(userId, dto);
  }

  @Get('my')
  @ApiOperation({ summary: 'Get current user submitted reports' })
  async getMyReports(@CurrentUser('sub') userId: string) {
    return this.reportsService.getMyReports(userId);
  }
}
