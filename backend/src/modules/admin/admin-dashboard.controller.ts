import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { PrismaService } from '../../prisma/prisma.service.js';

@ApiTags('Admin Dashboard')
@Controller('admin/dashboard')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
@ApiBearerAuth()
export class AdminDashboardController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('metrics')
  @ApiOperation({ summary: 'Get high-level platform metrics' })
  async getMetrics() {
    const [totalUsers, totalGroups, totalPosts, totalStreams] =
      await Promise.all([
        this.prisma.user.count(),
        this.prisma.group.count(),
        this.prisma.post.count(),
        this.prisma.liveStream.count(),
      ]);

    return {
      totalUsers,
      totalGroups,
      totalPosts,
      totalStreams,
    };
  }
}
