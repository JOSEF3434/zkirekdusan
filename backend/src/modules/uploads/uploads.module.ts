// src/modules/uploads/uploads.module.ts
import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { UploadsService } from './uploads.service.js';
import { UploadsRepository } from './uploads.repository.js';
import { UploadsController } from './uploads.controller.js';
import { LocalStorageProvider } from './providers/local.provider.js';
import { CloudinaryStorageProvider } from './providers/cloudinary.provider.js';
import { MinioStorageProvider } from './providers/minio.provider.js';
import { storageProviderFactory } from './providers/storage.factory.js';

@Module({
  imports: [
    MulterModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        limits: {
          fileSize:
            configService.get<number>('UPLOAD_MAX_SIZE') ?? 50 * 1024 * 1024, // 50MB
        },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [UploadsController],
  providers: [
    UploadsService,
    UploadsRepository,
    LocalStorageProvider,
    CloudinaryStorageProvider,
    MinioStorageProvider,
    storageProviderFactory,
  ],
  exports: [UploadsService],
})
export class UploadsModule {}
