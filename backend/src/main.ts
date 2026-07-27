// src/main.ts
import { ValidationPipe, Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { NestExpressApplication } from '@nestjs/platform-express';
import path from 'path';
import { AppModule } from './app.module.js';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Enable CORS
  app.enableCors({
    origin: true,
    credentials: true,
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

  // Serve static files from local uploads folder
  const uploadDir = path.resolve(process.cwd(), 'uploads');
  app.useStaticAssets(uploadDir, { prefix: '/uploads/' });

  // Set global API prefix
  app.setGlobalPrefix('api');

  // Configure Swagger OpenAPI documentation
  const swaggerConfig = new DocumentBuilder()
    .setTitle('Enterprise Social Platform API')
    .setDescription(
      'Production-ready social platform foundation (YouTube + Instagram + Discord style) built with NestJS, Clean Architecture, Prisma, PostgreSQL (Neon), and Two-Level RBAC.',
    )
    .setVersion('1.0.0')
    .addBearerAuth()
    .addTag('Authentication', 'Login, registration, token rotation & session management')
    .addTag('Users', 'Platform user management')
    .addTag('Profiles', 'User profile CRUD, visibility & statistics')
    .addTag('Groups', 'Group system with approval workflows & membership management')
    .addTag('Group Uploads', 'Group-scoped file upload API with pluggable storage backends')
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT ?? 3000;
  await app.listen(port);

  logger.log(`🚀 Enterprise Server running at http://localhost:${port}/api`);
  logger.log(`📚 Swagger Documentation live at http://localhost:${port}/api/docs`);
}

void bootstrap();
