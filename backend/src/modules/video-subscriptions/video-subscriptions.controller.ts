// src/modules/video-subscriptions/video-subscriptions.controller.ts
import { Controller, Get, Query } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { VideoSubscriptionsService } from './video-subscriptions.service.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Video Subscriptions')
@ApiBearerAuth()
@Controller('video-subscriptions')
export class VideoSubscriptionsController {
  constructor(private readonly service: VideoSubscriptionsService) {}

  @Get()
  @ApiOperation({ summary: 'List current user video channel subscriptions' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getMySubscriptions(
    @CurrentUser('sub') userId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.service.getUserSubscriptions(userId, +page, +limit);
  }

  @Get('feed')
  @ApiOperation({
    summary: 'Get subscription feed (latest videos from subscribed channels)',
  })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getSubscriptionFeed(
    @CurrentUser('sub') userId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.service.getSubscriptionFeed(userId, +page, +limit);
  }
}
