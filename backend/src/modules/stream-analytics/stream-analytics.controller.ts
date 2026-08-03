import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { StreamAnalyticsService } from './stream-analytics.service.js';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Stream Analytics')
@Controller('streams/:streamId/analytics')
export class StreamAnalyticsController {
  constructor(
    private readonly streamAnalyticsService: StreamAnalyticsService,
  ) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get full analytics report (Moderator only)' })
  @ApiParam({ name: 'streamId', description: 'Live Stream ID' })
  async getAnalytics(
    @CurrentUser('sub') userId: string,
    @Param('streamId') streamId: string,
  ) {
    return this.streamAnalyticsService.getAnalytics(userId, streamId);
  }
}
