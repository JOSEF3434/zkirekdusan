// src/modules/uploads/providers/storage.factory.ts
import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IStorageProvider } from './storage.interface.js';
import { LocalStorageProvider } from './local.provider.js';
import { CloudinaryStorageProvider } from './cloudinary.provider.js';
import { MinioStorageProvider } from './minio.provider.js';

export const STORAGE_PROVIDER_TOKEN = 'STORAGE_PROVIDER_TOKEN';

export const storageProviderFactory = {
  provide: STORAGE_PROVIDER_TOKEN,
  useFactory: (
    configService: ConfigService,
    localProvider: LocalStorageProvider,
    cloudinaryProvider: CloudinaryStorageProvider,
    minioProvider: MinioStorageProvider,
  ): IStorageProvider => {
    const logger = new Logger('StorageProviderFactory');

    const providerType = configService
      .get<string>('STORAGE_PROVIDER')
      ?.toUpperCase();

    // Explicit LOCAL opt-in for isolated offline tests
    if (providerType === 'LOCAL') {
      logger.log(
        'STORAGE_PROVIDER=LOCAL explicitly configured — using LocalStorageProvider',
      );
      return localProvider;
    }

    if (providerType === 'MINIO') {
      logger.log(
        'STORAGE_PROVIDER=MINIO configured — using MinioStorageProvider',
      );
      return minioProvider;
    }

    const cloudName = configService.get<string>('CLOUDINARY_CLOUD_NAME');
    const apiKey = configService.get<string>('CLOUDINARY_API_KEY');
    const apiSecret = configService.get<string>('CLOUDINARY_API_SECRET');

    if (cloudName && apiKey && apiSecret) {
      logger.log(
        `Cloudinary credentials configured (cloud: ${cloudName}) — using CloudinaryStorageProvider`,
      );
      return cloudinaryProvider;
    }

    const isProduction = configService.get<string>('NODE_ENV') === 'production';
    if (isProduction || providerType === 'CLOUDINARY') {
      throw new Error(
        'FATAL: STORAGE_PROVIDER=CLOUDINARY is required in production, but CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, or CLOUDINARY_API_SECRET is missing from environment variables.',
      );
    }

    logger.warn(
      'No Cloudinary credentials found — falling back to LocalStorageProvider (Development only)',
    );
    return localProvider;
  },
  inject: [
    ConfigService,
    LocalStorageProvider,
    CloudinaryStorageProvider,
    MinioStorageProvider,
  ],
};
