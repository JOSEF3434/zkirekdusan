import { Module, forwardRef } from '@nestjs/common';
import { StreamAnalyticsController } from './stream-analytics.controller.js';
import { StreamAnalyticsService } from './stream-analytics.service.js';
import { StreamAnalyticsRepository } from './stream-analytics.repository.js';
import { AuthorizationModule } from '../authorization/authorization.module.js';
import { LiveStreamingModule } from '../live-streaming/live-streaming.module.js';

@Module({
  imports: [AuthorizationModule, forwardRef(() => LiveStreamingModule)],
  controllers: [StreamAnalyticsController],
  providers: [StreamAnalyticsService, StreamAnalyticsRepository],
  exports: [StreamAnalyticsService, StreamAnalyticsRepository],
})
export class StreamAnalyticsModule {}
