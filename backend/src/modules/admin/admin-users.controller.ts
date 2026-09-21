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
import { AdminUsersService } from './services/admin-users.service.js';

@ApiTags('Admin Users')
@Controller('admin/users')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN, AppRole.SUPPORT)
@ApiBearerAuth()
export class AdminUsersController {
  constructor(private readonly usersService: AdminUsersService) {}

  @Get()
  @ApiOperation({
    summary: 'List platform users with server pagination and filtering',
  })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['ALL', 'ACTIVE', 'INACTIVE', 'SUSPENDED', 'BANNED'],
  })
  @ApiQuery({ name: 'role', required: false })
  async getUsers(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('search') search?: string,
    @Query('status') status?: string,
    @Query('role') role?: string,
  ) {
    return this.usersService.listUsers({ page, limit, search, status, role });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get detailed user view with roles and counts' })
  async getUserDetail(@Param('id') id: string) {
    return this.usersService.getUserDetail(id);
  }

  @Get(':id/permissions')
  @ApiOperation({ summary: 'Get effective permissions for a user' })
  async getUserPermissions(@Param('id') id: string) {
    return this.usersService.getUserEffectivePermissions(id);
  }

  @Patch(':id/status')
  @ApiOperation({
    summary: 'Update user status with audit logging and protection',
  })
  async updateUserStatus(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body()
    dto: {
      status: 'ACTIVE' | 'INACTIVE' | 'SUSPENDED' | 'BANNED';
      reason?: string;
    },
  ) {
    return this.usersService.updateUserStatus(
      actorId,
      id,
      dto.status,
      dto.reason,
    );
  }

  @Post(':id/role')
  @Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
  @ApiOperation({
    summary: 'Assign platform role with escalation guard and audit log',
  })
  async assignRole(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() dto: { roleName: AppRole; reason?: string },
  ) {
    return this.usersService.assignRole(actorId, id, dto.roleName, dto.reason);
  }

  @Post(':id/ban')
  @ApiOperation({ summary: 'Ban user account' })
  async banUser(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    const user = await this.usersService.updateUserStatus(
      actorId,
      id,
      'BANNED',
      body?.reason,
    );
    return {
      success: true,
      message: `User ${user.username ?? id} has been banned.`,
    };
  }

  @Post(':id/deactivate')
  @ApiOperation({ summary: 'Deactivate user account' })
  async deactivateUser(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    const user = await this.usersService.updateUserStatus(
      actorId,
      id,
      'INACTIVE',
      body?.reason,
    );
    return {
      success: true,
      message: `User ${user.username ?? id} has been deactivated.`,
    };
  }

  @Post(':id/activate')
  @ApiOperation({ summary: 'Reactivate user account' })
  async activateUser(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
  ) {
    const user = await this.usersService.updateUserStatus(
      actorId,
      id,
      'ACTIVE',
    );
    return {
      success: true,
      message: `User ${user.username ?? id} has been reactivated.`,
    };
  }
}
