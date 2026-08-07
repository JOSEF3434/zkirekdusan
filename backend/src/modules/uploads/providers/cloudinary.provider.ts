// src/modules/uploads/providers/cloudinary.provider.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary } from 'cloudinary';
import { IStorageProvider, StorageUploadResult } from './storage.interface.js';

@Injectable()
export class CloudinaryStorageProvider implements IStorageProvider {
  private readonly logger = new Logger(CloudinaryStorageProvider.name);
  private readonly isConfigured: boolean;

  constructor(private readonly configService: ConfigService) {
    const cloud_name = this.configService.get<string>('CLOUDINARY_CLOUD_NAME');
    const api_key = this.configService.get<string>('CLOUDINARY_API_KEY');
    const api_secret = this.configService.get<string>('CLOUDINARY_API_SECRET');

    if (cloud_name && api_key && api_secret) {
      cloudinary.config({ cloud_name, api_key, api_secret });
      this.isConfigured = true;
    } else {
      this.isConfigured = false;
    }
  }

  async upload(
    file: { buffer: Buffer; originalname: string; mimetype: string; size: number },
    subfolder: string,
  ): Promise<StorageUploadResult> {
    if (!this.isConfigured) {
      this.logger.warn('Cloudinary is not configured. Falling back to stub upload.');
      const fakeKey = `${subfolder}/cloudinary_${Date.now()}`;
      return {
        storageKey: fakeKey,
        url: `https://res.cloudinary.com/demo/image/upload/${fakeKey}`,
        provider: 'CLOUDINARY',
      };
    }

    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        { folder: subfolder, resource_type: 'auto' },
        (error, result) => {
          if (error) {
            this.logger.error('Cloudinary upload failed', error);
            return reject(error);
          }
          if (!result) return reject(new Error('Cloudinary upload returned null'));
          
          resolve({
            storageKey: result.public_id,
            url: result.secure_url,
            provider: 'CLOUDINARY',
            width: result.width,
            height: result.height,
          });
        },
      );

      uploadStream.end(file.buffer);
    });
  }

  async delete(storageKey: string): Promise<void> {
    if (!this.isConfigured) return;
    
    try {
      await cloudinary.uploader.destroy(storageKey);
      this.logger.log(`Cloudinary file deleted: ${storageKey}`);
    } catch (err) {
      this.logger.error(`Failed to delete from Cloudinary: ${storageKey}`, err);
    }
  }

  getUrl(storageKey: string): string {
    if (!this.isConfigured) return `https://res.cloudinary.com/demo/image/upload/${storageKey}`;
    return cloudinary.url(storageKey, { secure: true });
  }

  async getSignedUrl(storageKey: string, expiresIn = 3600): Promise<string> {
    if (!this.isConfigured) return this.getUrl(storageKey);
    // Cloudinary signed URLs use specific auth params
    const timestamp = Math.floor(Date.now() / 1000) + expiresIn;
    return cloudinary.utils.api_sign_request({ timestamp, public_id: storageKey }, this.configService.get<string>('CLOUDINARY_API_SECRET')!);
  }
}
