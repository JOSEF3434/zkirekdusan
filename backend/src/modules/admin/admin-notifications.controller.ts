import {
  Controller,
  Get,
  Post,
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
import { AdminNotificationsService } from './services/admin-notifications.service.js';

@ApiTags('Admin Notifications')
@Controller('admin/notifications')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
@ApiBearerAuth()
export class AdminNotificationsController {
  constructor(private readonly notificationsService: AdminNotificationsService) {}

  @Post('broadcast')
  @ApiOperation({ summary: 'Broadcast system notification to users or roles' })
  async broadcastNotification(
    @CurrentUser('sub') actorId: string,
    @Body()
    dto: {
      title: string;
      body: string;
      targetRole?: string;
      data?: any;
    },
  ) {
    return this.notificationsService.broadcastSystemNotification({
      ...dto,
      actorId,
    });
  }

  @Get()
  @ApiOperation({ summary: 'List recent administrative system announcements' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getNotifications(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.notificationsService.listAdminNotifications({ page, limit });
  }
}
