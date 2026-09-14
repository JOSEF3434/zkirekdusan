import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { AdminGroupsService } from './services/admin-groups.service.js';

@ApiTags('Admin Groups')
@Controller('admin/groups')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN, AppRole.MODERATOR)
@ApiBearerAuth()
export class AdminGroupsController {
  constructor(private readonly groupsService: AdminGroupsService) {}

  @Get()
  @ApiOperation({ summary: 'List platform groups with pagination and filters' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'status', required: false, enum: ['ALL', 'ACTIVE', 'PENDING_APPROVAL', 'SUSPENDED', 'ARCHIVED', 'REJECTED'] })
  async getGroups(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('search') search?: string,
    @Query('status') status?: string,
  ) {
    return this.groupsService.listGroups({ page, limit, search, status });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get detailed view of a group' })
  async getGroupDetail(@Param('id') id: string) {
    return this.groupsService.getGroupDetail(id);
  }

  @Post(':id/approve')
  @ApiOperation({ summary: 'Approve a pending group' })
  async approveGroup(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.groupsService.approveGroup(actorId, id, body?.reason);
  }

  @Post(':id/reject')
  @ApiOperation({ summary: 'Reject a pending group' })
  async rejectGroup(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.groupsService.rejectGroup(actorId, id, body?.reason);
  }

  @Post(':id/suspend')
  @ApiOperation({ summary: 'Suspend a group' })
  async suspendGroup(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.groupsService.suspendGroup(actorId, id, body?.reason);
  }

  @Post(':id/restore')
  @ApiOperation({ summary: 'Restore a suspended or rejected group' })
  async restoreGroup(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.groupsService.restoreGroup(actorId, id, body?.reason);
  }

  @Delete(':id')
  @Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
  @ApiOperation({ summary: 'Delete group permanently' })
  async deleteGroup(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.groupsService.deleteGroup(actorId, id, body?.reason);
  }

  @Delete(':id/members/:memberId')
  @ApiOperation({ summary: 'Force remove a member from group' })
  async removeMember(
    @Param('id') id: string,
    @Param('memberId') memberId: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.groupsService.removeMember(actorId, id, memberId, body?.reason);
  }
}
