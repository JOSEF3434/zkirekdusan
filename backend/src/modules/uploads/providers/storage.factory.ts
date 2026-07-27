// src/modules/uploads/providers/storage.factory.ts
import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IStorageProvider } from './storage.interface.js';
import { LocalStorageProvider } from './local.provider.js';
import { CloudinaryStorageProvider } from './cloudinary.provider.js';

export const STORAGE_PROVIDER_TOKEN = 'STORAGE_PROVIDER_TOKEN';

export const storageProviderFactory = {
  provide: STORAGE_PROVIDER_TOKEN,
  useFactory: (
    configService: ConfigService,
    localProvider: LocalStorageProvider,
    cloudinaryProvider: CloudinaryStorageProvider,
  ): IStorageProvider => {
    const logger = new Logger('StorageProviderFactory');

    const cloudName = configService.get<string>('CLOUDINARY_CLOUD_NAME');
    const apiKey = configService.get<string>('CLOUDINARY_API_KEY');
    const apiSecret = configService.get<string>('CLOUDINARY_API_SECRET');

    if (cloudName && apiKey && apiSecret) {
      logger.log('Cloudinary credentials found in .env — using CloudinaryStorageProvider');
      return cloudinaryProvider;
    }

    logger.log(
      'Cloudinary credentials missing or incomplete — falling back to LocalStorageProvider (uploads/ folder)',
    );
    return localProvider;
  },
  inject: [ConfigService, LocalStorageProvider, CloudinaryStorageProvider],
};
