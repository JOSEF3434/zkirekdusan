import {
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Body,
  UseGuards,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { PrismaService } from '../../prisma/prisma.service.js';

@ApiTags('Admin Users')
@Controller('admin/users')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
@ApiBearerAuth()
export class AdminUsersController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @ApiOperation({ summary: 'Get all users' })
  async getUsers(@Query('limit') limit = 50, @Query('page') page = 1) {
    const skip = (Number(page) - 1) * Number(limit);
    return this.prisma.user.findMany({
      take: Number(limit),
      skip: skip,
      include: {
        profile: { select: { displayName: true, avatarUrl: true } },
      },
    });
  }

  @Patch(':id/status')
  @ApiOperation({ summary: 'Update user status (ban, suspend, activate)' })
  async updateUserStatus(
    @Param('id') id: string,
    @Body() dto: { status: 'ACTIVE' | 'INACTIVE' | 'SUSPENDED' | 'BANNED' },
  ) {
    return this.prisma.user.update({
      where: { id },
      data: { status: dto.status },
    });
  }

  @Post(':id/ban')
  @ApiOperation({ summary: 'Ban user account' })
  async banUser(
    @Param('id') id: string,
    @Body() body?: { reason?: string },
  ) {
    const user = await this.prisma.user.update({
      where: { id },
      data: { status: 'BANNED' },
    });
    return { success: true, message: `User ${user.username ?? id} has been banned.` };
  }

  @Post(':id/deactivate')
  @ApiOperation({ summary: 'Deactivate user account' })
  async deactivateUser(
    @Param('id') id: string,
    @Body() body?: { reason?: string },
  ) {
    const user = await this.prisma.user.update({
      where: { id },
      data: { status: 'INACTIVE' },
    });
    return { success: true, message: `User ${user.username ?? id} has been deactivated.` };
  }

  @Post(':id/activate')
  @ApiOperation({ summary: 'Reactivate user account' })
  async activateUser(@Param('id') id: string) {
    const user = await this.prisma.user.update({
      where: { id },
      data: { status: 'ACTIVE' },
    });
    return { success: true, message: `User ${user.username ?? id} has been reactivated.` };
  }
}
