import { Controller, Get, Param, Patch, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { PrismaService } from '../../prisma/prisma.service.js';

@ApiTags('Admin Moderation')
@Controller('admin/moderation')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
@ApiBearerAuth()
export class AdminModerationController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('cases')
  @ApiOperation({ summary: 'Get open moderation cases' })
  async getCases() {
    return this.prisma.moderationCase.findMany({
      where: { status: 'OPEN' },
      orderBy: { priority: 'desc' },
    });
  }

  @Patch('cases/:id/resolve')
  @ApiOperation({ summary: 'Resolve a moderation case' })
  async resolveCase(
    @Param('id') id: string,
    @Body() dto: { action: string; reason?: string },
  ) {
    return this.prisma.$transaction(async (tx) => {
      const updatedCase = await tx.moderationCase.update({
        where: { id },
        data: { status: 'RESOLVED' },
      });
      await tx.moderationAction.create({
        data: {
          caseId: id,
          actorId: 'admin-system', // Should come from @CurrentUser
          action: dto.action,
          reason: dto.reason,
        },
      });
      return updatedCase;
    });
  }
}
