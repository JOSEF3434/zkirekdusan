// src/main.ts
import { ValidationPipe, Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { NestExpressApplication } from '@nestjs/platform-express';
import path from 'path';
import helmet from 'helmet';
import compression from 'compression';
import { AppModule } from './app.module.js';
import { RedisIoAdapter } from './common/adapters/redis-io.adapter.js';

async function bootstrap() {
  const logger = new Logger('Bootstrap');

  // ── Graceful Redis-error handling ──────────────────────────────────────────
  // BullMQ / ioredis can emit MaxRetriesPerRequestError as an unhandled rejection
  // when Redis is unavailable. Catch it here so the process stays alive.
  process.on('unhandledRejection', (reason: unknown) => {
    const msg = String(reason);
    if (
      msg.includes('MaxRetriesPerRequest') ||
      msg.includes('ECONNREFUSED') ||
      msg.includes('Redis')
    ) {
      logger.warn(`[Redis] Unhandled rejection (non-fatal): ${msg}`);
    } else {
      logger.error(`Unhandled Promise Rejection: ${msg}`);
    }
  });

  process.on('uncaughtException', (err: Error) => {
    const msg = err.message ?? String(err);
    if (
      msg.includes('MaxRetriesPerRequest') ||
      msg.includes('ECONNREFUSED') ||
      msg.includes('Redis')
    ) {
      logger.warn(`[Redis] Uncaught exception (non-fatal): ${msg}`);
    } else {
      logger.error(`Uncaught Exception: ${msg}`, err.stack);
      process.exit(1);
    }
  });
  // ───────────────────────────────────────────────────────────────────────────

  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Graceful shutdown for container environments (Kubernetes, Docker, Render)
  app.enableShutdownHooks();

  // Security Hardening (Phase 8)
  app.use(helmet());

  // Gzip compression for all HTTP responses
  app.use(compression());

  // CORS — read allowed origins from env (comma-separated list)
  const configuredOrigins = (process.env.CORS_ORIGINS ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  const allowedOrigins = new Set(configuredOrigins);

  app.enableCors({
    origin: (origin, callback) => {
      if (!origin) {
        return callback(null, true);
      }

      if (allowedOrigins.has(origin)) {
        return callback(null, true);
      }

      // Allow Flutter Web development on any localhost or 127.0.0.1 port
      if (
        /^http:\/\/localhost(:\d+)?$/.test(origin) ||
        /^http:\/\/127\.0\.0\.1(:\d+)?$/.test(origin) ||
        /^http:\/\/0\.0\.0\.0(:\d+)?$/.test(origin) ||
        /^https:\/\/.*\.onrender\.com$/.test(origin) ||
        /^https:\/\/.*\.vercel\.app$/.test(origin)
      ) {
        return callback(null, true);
      }

      return callback(
        new Error(`CORS: Origin ${origin} is not allowed`),
        false,
      );
    },

    credentials: true,

    methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],

    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'Accept',
      'Origin',
      'X-Requested-With',
      'Range',
    ],

    exposedHeaders: ['Content-Length', 'Content-Range', 'Accept-Ranges'],

    optionsSuccessStatus: 204,
  });

  // Global Validation Pipe with automatic payload transformation
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  // Setup Redis Adapter for Socket.IO (optional — falls back to default in-process adapter)
  const redisIoAdapter = new RedisIoAdapter(app);
  await redisIoAdapter.connectToRedis();
  app.useWebSocketAdapter(redisIoAdapter);

  // Serve static files from local uploads folder
  const uploadDir = path.resolve(process.cwd(), 'uploads');
  app.useStaticAssets(uploadDir, { prefix: '/uploads/' });

  // Set global API prefix
  app.setGlobalPrefix('api');

  // Configure Swagger OpenAPI documentation
  const swaggerConfig = new DocumentBuilder()
    .setTitle('Enterprise Social & Video Platform API')
    .setDescription(
      'Production-grade YouTube + Instagram + Discord backend platform built with NestJS, Clean Architecture, Prisma, PostgreSQL (Neon), BullMQ, HLS Video Pipeline, and Two-Level RBAC.',
    )
    .setVersion('4.0.0')
    .addBearerAuth()
    // Phase 1 Tags
    .addTag(
      'Authentication',
      'Login, registration, token rotation & session management',
    )
    .addTag('Users', 'Platform user management & admin controls')
    .addTag(
      'Roles',
      'Global role-based access control (SUPER_ADMIN, ADMIN, USER)',
    )
    .addTag('Sessions', 'User active session tracking & revocation')
    .addTag('Profiles', 'User profile CRUD, visibility & statistics')
    .addTag('Groups', 'Group management, approval workflows & membership RBAC')
    .addTag(
      'Group Uploads',
      'Group-scoped file upload API with pluggable storage (Local, Cloudinary, MinIO, S3)',
    )

    // Phase 2 Tags
    .addTag('Follows', 'Follow/unfollow system & follower/following lists')
    .addTag(
      'Posts',
      'Posts feed (Text, Image, Video, Carousel) with visibility & hashtags',
    )
    .addTag('Likes & Reactions', 'Reactions on posts, reels, and comments')
    .addTag('Comments', 'Nested comments & replies')
    .addTag(
      'Stories (24h Expiration)',
      '24-hour temporary media and text stories',
    )
    .addTag(
      'Reels (Short-form Videos)',
      'Instagram/YouTube Shorts style short videos',
    )
    .addTag('Saved Posts', 'Bookmark and save posts for later viewing')

    // Phase 3 Tags
    .addTag(
      'Group Channels',
      'Messaging channels (Text, Announcement, Voice) inside groups',
    )
    .addTag('Conversations', 'Direct 1-on-1 and Group messaging conversations')
    .addTag(
      'Messages',
      'Real-time messaging with attachments, reactions, read receipts, and pinning',
    )
    .addTag(
      'Notifications',
      'User notifications for messages, mentions, and system events',
    )
    .addTag('Group Join Requests', 'Group join request approval workflow')
    .addTag('Presence', 'User online/offline/idle presence management')

    // Phase 4 Tags
    .addTag(
      'Video Channels',
      'Group-owned Video Channels for publishing media content',
    )
    .addTag(
      'Videos',
      'Video upload, HLS playback, watch progress, recommendations, and analytics',
    )
    .addTag(
      'Video Processing',
      'BullMQ background transcoding queue and FFmpeg pipeline',
    )
    .addTag('Video Playlists', 'Custom user & channel video playlists')
    .addTag(
      'Video Comments',
      'Nested video comment system with pinned comments',
    )
    .addTag(
      'Video Subscriptions',
      'Channel subscriptions and subscription feed',
    )
    .addTag(
      'Downloads',
      'Enterprise multi-resolution media download system with RBAC authorization',
    )

    // Phase 5 Tags
    .addTag(
      'Live Streaming',
      'Enterprise Live Streaming (RTMP/WebRTC) channel management',
    )
    .addTag('Stream Chat', 'Real-time Live Chat for streams with moderation')
    .addTag(
      'Stream Analytics',
      'Live stream concurrent viewers and engagement metrics',
    )
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT ?? 3000;
  await app.listen(port);

  logger.log(`🚀 Enterprise Server running at http://localhost:${port}/api`);
  logger.log(
    `📚 Swagger Documentation live at http://localhost:${port}/api/docs`,
  );
}

void bootstrap();
