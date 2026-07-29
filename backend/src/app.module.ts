// src/app.module.ts
import { Module } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';

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

    PrismaModule,
    CommonModule,

    AuthModule,
    UsersModule,
    RolesModule,
    SessionsModule,
    RefreshTokenModule,
    AuthorizationModule,
    ProfilesModule,
    GroupsModule,
    UploadsModule,

    // Phase 2 Social Features
    FollowsModule,
    PostsModule,
    LikesModule,
    CommentsModule,
    StoriesModule,
    ReelsModule,
    SavedPostsModule,
  ],

  controllers: [AppController],

  providers: [
    AppService,

    // Global Guards (evaluated in top-to-bottom order)
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
