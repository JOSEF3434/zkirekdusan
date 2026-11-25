import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
} from '@nestjs/swagger';
import type { Request } from 'express';
import { JwtService } from '@nestjs/jwt';
import { Public } from '../../common/decorators/public.decorator.js';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { SystemReportService } from './system-report.service.js';
import { DismissReportDto } from './dto/dismiss-report.dto.js';

@ApiTags('System Report')
@Controller('system-report')
export class SystemReportController {
  constructor(
    private readonly systemReportService: SystemReportService,
    private readonly jwtService: JwtService,
  ) {}

  @Public()
  @Get('active')
  @ApiOperation({
    summary: 'Get active published system report with strict user-visibility filtering',
  })
  async getActiveReport(@Req() req: Request) {
    let userId: string | undefined = undefined;

    // If an Authorization header is provided, safely extract userId to check dismissal status
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const token = authHeader.substring(7);
        const decoded = this.jwtService.decode(token) as { sub?: string; userId?: string } | null;
        userId = decoded?.sub ?? decoded?.userId;
      } catch {
        // Ignore invalid token on public endpoint
      }
    }

    return this.systemReportService.getActivePublicReport(userId);
  }

  @Post(':id/dismiss')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Record that the current user has viewed and dismissed a specific revision of the report',
  })
  async dismissReport(
    @CurrentUser('sub') userId: string,
    @Param('id') reportId: string,
    @Body() dto: DismissReportDto,
  ) {
    await this.systemReportService.recordUserDismissal(
      userId,
      reportId,
      dto.revision,
    );
    return { success: true };
  }
}
