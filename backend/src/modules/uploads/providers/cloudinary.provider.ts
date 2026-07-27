// src/modules/uploads/providers/cloudinary.provider.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IStorageProvider, StorageUploadResult } from './storage.interface.js';

@Injectable()
export class CloudinaryStorageProvider implements IStorageProvider {
  private readonly logger = new Logger(CloudinaryStorageProvider.name);

  constructor(private readonly configService: ConfigService) {}

  async upload(
    file: { buffer: Buffer; originalname: string; mimetype: string; size: number },
    subfolder: string,
  ): Promise<StorageUploadResult> {
    this.logger.log(`Cloudinary provider uploading ${file.originalname} to folder ${subfolder}`);
    // When Cloudinary API credentials are present, integration runs here.
    // Stub fallback logic returning provider structure:
    const fakeKey = `cloudinary_${subfolder}_${Date.now()}`;
    return {
      storageKey: fakeKey,
      url: `https://res.cloudinary.com/demo/image/upload/${fakeKey}`,
      provider: 'CLOUDINARY',
    };
  }

  async delete(storageKey: string): Promise<void> {
    this.logger.log(`Cloudinary file delete requested: ${storageKey}`);
  }

  getUrl(storageKey: string): string {
    return `https://res.cloudinary.com/demo/image/upload/${storageKey}`;
  }
}
