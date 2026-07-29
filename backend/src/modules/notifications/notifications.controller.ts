// src/modules/notifications/notifications.controller.ts
import { Controller, Delete, Get, Param, Patch } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { NotificationsService } from './notifications.service.js';
import { NotificationResponseDto } from './dto/notification-response.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Notifications')
@ApiBearerAuth()
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all notifications (latest 50)' })
  @ApiResponse({ status: 200, type: [NotificationResponseDto] })
  async getAll(
    @CurrentUser('sub') userId: string,
  ): Promise<NotificationResponseDto[]> {
    return this.notificationsService.getMyNotifications(userId);
  }

  @Get('unread')
  @ApiOperation({ summary: 'Get only unread notifications' })
  @ApiResponse({ status: 200, type: [NotificationResponseDto] })
  async getUnread(
    @CurrentUser('sub') userId: string,
  ): Promise<NotificationResponseDto[]> {
    return this.notificationsService.getUnreadNotifications(userId);
  }

  @Get('unread/count')
  @ApiOperation({ summary: 'Get unread notification count' })
  @ApiResponse({ status: 200 })
  async getUnreadCount(
    @CurrentUser('sub') userId: string,
  ): Promise<{ count: number }> {
    return this.notificationsService.getUnreadCount(userId);
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'Mark a notification as read' })
  @ApiResponse({ status: 200 })
  async markAsRead(
    @Param('id') id: string,
    @CurrentUser('sub') userId: string,
  ): Promise<{ success: boolean }> {
    return this.notificationsService.markAsRead(id, userId);
  }

  @Patch('read-all')
  @ApiOperation({ summary: 'Mark all notifications as read' })
  @ApiResponse({ status: 200 })
  async markAllAsRead(
    @CurrentUser('sub') userId: string,
  ): Promise<{ success: boolean }> {
    return this.notificationsService.markAllAsRead(userId);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a notification' })
  @ApiResponse({ status: 200 })
  async delete(
    @Param('id') id: string,
    @CurrentUser('sub') userId: string,
  ): Promise<{ success: boolean }> {
    return this.notificationsService.delete(id, userId);
  }
}
