// src/modules/uploads/uploads.module.ts
import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { UploadsService } from './uploads.service.js';
import { UploadsRepository } from './uploads.repository.js';
import { UploadsController } from './uploads.controller.js';
import { GroupUploadsController } from './group-uploads.controller.js';
import { LocalStorageProvider } from './providers/local.provider.js';
import { CloudinaryStorageProvider } from './providers/cloudinary.provider.js';
import { MinioStorageProvider } from './providers/minio.provider.js';
import {
  storageProviderFactory,
  STORAGE_PROVIDER_TOKEN,
} from './providers/storage.factory.js';

@Module({
  imports: [
    MulterModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        limits: {
          fileSize:
            configService.get<number>('UPLOAD_MAX_SIZE') ?? 500 * 1024 * 1024, // 500MB
        },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [UploadsController, GroupUploadsController],
  providers: [
    UploadsService,
    UploadsRepository,
    LocalStorageProvider,
    CloudinaryStorageProvider,
    MinioStorageProvider,
    storageProviderFactory,
  ],
  exports: [
    UploadsService,
    UploadsRepository,
    STORAGE_PROVIDER_TOKEN,
    LocalStorageProvider,
    CloudinaryStorageProvider,
    MinioStorageProvider,
  ],
})
export class UploadsModule { }
