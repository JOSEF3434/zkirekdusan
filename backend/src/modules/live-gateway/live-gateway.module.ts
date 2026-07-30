import { Module } from '@nestjs/common';
import { LiveGateway } from './live.gateway.js';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule } from '@nestjs/config';
import { StreamChatModule } from '../stream-chat/stream-chat.module.js';
import { StreamAnalyticsModule } from '../stream-analytics/stream-analytics.module.js';

@Module({
  imports: [
    JwtModule.register({}),
    ConfigModule,
    StreamChatModule,
    StreamAnalyticsModule,
  ],
  providers: [LiveGateway],
  exports: [LiveGateway],
})
export class LiveGatewayModule {}
