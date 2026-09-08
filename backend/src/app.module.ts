// src/app.module.ts
import { Module } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { BullModule } from '@nestjs/bullmq';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { CacheModule } from '@nestjs/cache-manager';
import { createKeyv } from '@keyv/redis';

import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';

import { PrismaModule } from './prisma/prisma.module.js';
import { CommonModule } from './common/common.module.js';

import { AuthModule } from './modules/auth/auth.module.js';
import { UsersModule } from './modules/users/users.module.js';
import { RolesModule } from './modules/roles/roles.module.js';
import { RefreshTokenModule } from './modules/refresh-token/refresh-token.module.js';
import { SessionsModule } from './modules/sessions/sessions.module.js';
import { AuthorizationModule } from './modules/authorization/authorization.module.js';
import { ProfilesModule } from './modules/profiles/profiles.module.js';
import { GroupsModule } from './modules/groups/groups.module.js';
import { UploadsModule } from './modules/uploads/uploads.module.js';

// Social Features Modules (Phase 2)
import { FollowsModule } from './modules/follows/follows.module.js';
import { PostsModule } from './modules/posts/posts.module.js';
import { LikesModule } from './modules/likes/likes.module.js';
import { CommentsModule } from './modules/comments/comments.module.js';
import { StoriesModule } from './modules/stories/stories.module.js';
import { ReelsModule } from './modules/reels/reels.module.js';
import { SavedPostsModule } from './modules/saved-posts/saved-posts.module.js';

// Messaging Platform Modules (Phase 3)
import { ChannelsModule } from './modules/channels/channels.module.js';
import { ConversationsModule } from './modules/conversations/conversations.module.js';
import { MessagesModule } from './modules/messages/messages.module.js';
import { MessagingGatewayModule } from './modules/messaging-gateway/messaging-gateway.module.js';
import { NotificationsModule } from './modules/notifications/notifications.module.js';
import { GroupJoinRequestsModule } from './modules/group-join-requests/group-join-requests.module.js';
import { PresenceModule } from './modules/presence/presence.module.js';

// Video Platform Modules (Phase 4)
import { VideoChannelsModule } from './modules/video-channels/video-channels.module.js';
import { VideosModule } from './modules/videos/videos.module.js';
import { VideoProcessingModule } from './modules/video-processing/video-processing.module.js';
import { VideoPlaylistsModule } from './modules/video-playlists/video-playlists.module.js';
import { VideoCommentsModule } from './modules/video-comments/video-comments.module.js';
import { VideoSubscriptionsModule } from './modules/video-subscriptions/video-subscriptions.module.js';
import { DownloadsModule } from './modules/downloads/downloads.module.js';

// Phase 5 — Live Streaming Platform
import { LiveStreamingModule } from './modules/live-streaming/live-streaming.module.js';
import { StreamChatModule } from './modules/stream-chat/stream-chat.module.js';
import { StreamAnalyticsModule } from './modules/stream-analytics/stream-analytics.module.js';
import { StreamProcessingModule } from './modules/stream-processing/stream-processing.module.js';
import { LiveGatewayModule } from './modules/live-gateway/live-gateway.module.js';
import { StreamHighlightsModule } from './modules/stream-highlights/stream-highlights.module.js';

// Phase 6 — Discovery
import { SearchModule } from './modules/search/search.module.js';
import { RecommendationsModule } from './modules/recommendations/recommendations.module.js';
import { TrendingModule } from './modules/trending/trending.module.js';
import { ExploreModule } from './modules/explore/explore.module.js';

// Ethiopian Calendar
import { CalendarModule } from './modules/calendar/calendar.module.js';

// Phase 7 — Admin Platform & Moderation
import { AdminModule } from './modules/admin/admin.module.js';
import { ReportsModule } from './modules/reports/reports.module.js';

// Health Check
import { HealthModule } from './modules/health/health.module.js';

import { JwtAuthGuard } from './common/guards/jwt-auth.guard.js';
import { RolesGuard } from './common/guards/roles.guard.js';
import { PermissionsGuard } from './common/guards/permissions.guard.js';

import { GlobalExceptionFilter } from './common/filters/global-exception.filter.js';
import { ResponseInterceptor } from './common/interceptors/response.interceptor.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
      expandVariables: true,
    }),

    BullModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (config: ConfigService) => ({
        connection: {
          host: config.get<string>('REDIS_HOST') || 'localhost',
          port: config.get<number>('REDIS_PORT') || 6379,
          // null = keep retrying in background without throwing (prevents process crash)
          maxRetriesPerRequest: null,
          enableOfflineQueue: false,
          lazyConnect: true,
          connectTimeout: 5000,
        },
      }),
      inject: [ConfigService],
    }),

    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 100,
      },
    ]),

    CacheModule.registerAsync({
      isGlobal: true,
      imports: [ConfigModule],
      useFactory: (config: ConfigService) => {
        const host = config.get<string>('REDIS_HOST') || 'localhost';
        const port = config.get<number>('REDIS_PORT') || 6379;
        return {
          store: createKeyv(`redis://${host}:${port}`),
        };
      },
      inject: [ConfigService],
    }),

    PrismaModule,
    CommonModule,
    HealthModule,

    // Phase 1 — Foundation
    AuthModule,
    UsersModule,
    RolesModule,
    SessionsModule,
    RefreshTokenModule,
    AuthorizationModule,
    ProfilesModule,
    GroupsModule,
    UploadsModule,

    // Phase 2 — Social Features
    FollowsModule,
    PostsModule,
    LikesModule,
    CommentsModule,
    StoriesModule,
    ReelsModule,
    SavedPostsModule,

    // Phase 3 — Enterprise Messaging Platform
    ChannelsModule,
    ConversationsModule,
    MessagesModule,
    MessagingGatewayModule,
    NotificationsModule,
    GroupJoinRequestsModule,
    PresenceModule,

    // Phase 4 — Enterprise Video Platform & Downloads
    VideoChannelsModule,
    VideosModule,
    VideoProcessingModule,
    VideoPlaylistsModule,
    VideoCommentsModule,
    VideoSubscriptionsModule,
    DownloadsModule,

    // Phase 5 — Live Streaming Platform
    LiveStreamingModule,
    StreamChatModule,
    StreamAnalyticsModule,
    StreamProcessingModule,
    LiveGatewayModule,
    StreamHighlightsModule,

    // Phase 6 — Discovery
    SearchModule,
    RecommendationsModule,
    TrendingModule,
    ExploreModule,

    // Ethiopian Calendar
    CalendarModule,

    // Phase 7 — Admin Platform & Reports
    AdminModule,
    ReportsModule,
  ],

  controllers: [AppController],

  providers: [
    AppService,

    // Global Guards (evaluated in top-to-bottom order)
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    {
      provide: APP_GUARD,
      useClass: RolesGuard,
    },
    {
      provide: APP_GUARD,
      useClass: PermissionsGuard,
    },

    // Global Interceptor & Filter
    {
      provide: APP_INTERCEPTOR,
      useClass: ResponseInterceptor,
    },
    {
      provide: APP_FILTER,
      useClass: GlobalExceptionFilter,
    },
  ],
})
export class AppModule {}
