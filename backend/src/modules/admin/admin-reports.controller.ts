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
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { PrismaService } from '../../prisma/prisma.service.js';

@ApiTags('Admin Reports')
@Controller('admin/reports')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
@ApiBearerAuth()
export class AdminReportsController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @ApiOperation({ summary: 'Get reports with optional status filter and pagination' })
  @ApiQuery({ name: 'status', required: false, enum: ['ALL', 'PENDING', 'REVIEWING', 'RESOLVED', 'DISMISSED'] })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 30 })
  async getReports(
    @Query('status') status?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page = 1,
    @Query('limit', new DefaultValuePipe(30), ParseIntPipe) limit = 30,
  ) {
    const where: any = {};
    if (status && status !== 'ALL') {
      where.status = status;
    }

    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      this.prisma.report.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          reporter: {
            select: {
              id: true,
              username: true,
              profile: {
                select: {
                  displayName: true,
                  avatarUrl: true,
                },
              },
            },
          },
        },
      }),
      this.prisma.report.count({ where }),
    ]);

    // Enrich with target user details if targetUserId or targetType == USER
    const enrichedItems = await Promise.all(
      items.map(async (report) => {
        let targetUser: any = null;
        const targetUserId = report.targetUserId || (report.targetType === 'USER' ? report.targetId : null);
        if (targetUserId) {
          targetUser = await this.prisma.user.findUnique({
            where: { id: targetUserId },
            select: {
              id: true,
              username: true,
              status: true,
              role: { select: { name: true } },
              profile: {
                select: {
                  displayName: true,
                  avatarUrl: true,
                },
              },
            },
          });
        }
        return {
          ...report,
          targetUser,
        };
      }),
    );

    return {
      items: enrichedItems,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      hasNext: page * limit < total,
    };
  }

  @Post(':id/action')
  @ApiOperation({ summary: 'Perform admin action on report (BAN, DEACTIVATE, DISMISS, WARN)' })
  async performAction(
    @Param('id') id: string,
    @CurrentUser('sub') adminId: string,
    @Body() dto: { action: 'BAN_USER' | 'DEACTIVATE_USER' | 'DISMISS' | 'RESOLVE' | 'SUSPEND_USER'; note?: string },
  ) {
    const report = await this.prisma.report.findUnique({ where: { id } });
    if (!report) {
      return { success: false, message: 'Report not found' };
    }

    const targetUserId = report.targetUserId || (report.targetType === 'USER' ? report.targetId : null);

    // Apply user action if requested
    if (targetUserId) {
      if (dto.action === 'BAN_USER') {
        await this.prisma.user.update({
          where: { id: targetUserId },
          data: { status: 'BANNED' },
        });
      } else if (dto.action === 'DEACTIVATE_USER') {
        await this.prisma.user.update({
          where: { id: targetUserId },
          data: { status: 'INACTIVE' },
        });
      } else if (dto.action === 'SUSPEND_USER') {
        await this.prisma.user.update({
          where: { id: targetUserId },
          data: { status: 'SUSPENDED' },
        });
      }
    }

    const newStatus = dto.action === 'DISMISS' ? 'DISMISSED' : 'RESOLVED';

    const updated = await this.prisma.report.update({
      where: { id },
      data: {
        status: newStatus,
        actionTaken: dto.action,
        resolvedById: adminId,
        resolvedAt: new Date(),
      },
    });

    return {
      success: true,
      message: `Action ${dto.action} performed successfully.`,
      report: updated,
    };
  }

  @Patch(':id/resolve')
  @ApiOperation({ summary: 'Resolve or dismiss a report' })
  async resolveReport(
    @Param('id') id: string,
    @CurrentUser('sub') adminId: string,
    @Body() dto: { status: 'RESOLVED' | 'DISMISSED'; actionTaken?: string },
  ) {
    return this.prisma.report.update({
      where: { id },
      data: {
        status: dto.status,
        actionTaken: dto.actionTaken ?? dto.status,
        resolvedById: adminId,
        resolvedAt: new Date(),
      },
    });
  }
}
