// src/modules/uploads/providers/cloudinary.provider.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary } from 'cloudinary';
import { IStorageProvider, StorageUploadResult } from './storage.interface.js';

@Injectable()
export class CloudinaryStorageProvider implements IStorageProvider {
  readonly providerType = 'CLOUDINARY';
  private readonly logger = new Logger(CloudinaryStorageProvider.name);
  private readonly isConfigured: boolean;
  private readonly cloudName: string;

  constructor(private readonly configService: ConfigService) {
    const cloud_name = this.configService.get<string>('CLOUDINARY_CLOUD_NAME');
    const api_key = this.configService.get<string>('CLOUDINARY_API_KEY');
    const api_secret = this.configService.get<string>('CLOUDINARY_API_SECRET');

    if (cloud_name && api_key && api_secret) {
      cloudinary.config({ cloud_name, api_key, api_secret, secure: true });
      this.isConfigured = true;
      this.cloudName = cloud_name;
      this.logger.log(`Cloudinary configured: cloud=${cloud_name}`);
    } else {
      this.isConfigured = false;
      this.cloudName = '';
      this.logger.warn('Cloudinary credentials missing — stub mode active');
    }
  }

  async upload(
    file: { buffer: Buffer; originalname: string; mimetype: string; size: number },
    subfolder: string,
  ): Promise<StorageUploadResult> {
    if (!this.isConfigured) {
      const fakeKey = `${subfolder}/stub_${Date.now()}`;
      return {
        storageKey: fakeKey,
        url: `https://res.cloudinary.com/demo/video/upload/${fakeKey}`,
        provider: 'CLOUDINARY',
      };
    }

    const isVideo = file.mimetype.startsWith('video/');
    const isImage = file.mimetype.startsWith('image/');
    const resourceType = isVideo ? 'video' : isImage ? 'image' : 'raw';

    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder: subfolder,
          resource_type: resourceType,
          // Videos: trigger async Cloudinary transcoding to MP4 but don't block
          ...(isVideo ? { eager_async: true } : {}),
        },
        (error, result) => {
          if (error) {
            this.logger.error('Cloudinary upload failed', error);
            return reject(error);
          }
          if (!result) return reject(new Error('Cloudinary upload returned null'));

          const url = result.secure_url;
          this.logger.log(`Cloudinary upload: ${result.public_id} → ${url}`);
          resolve({
            storageKey: result.public_id,
            url,
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
    for (const rt of ['video', 'image', 'raw'] as const) {
      try {
        const r = await cloudinary.uploader.destroy(storageKey, { resource_type: rt });
        if (r.result !== 'not found') {
          this.logger.log(`Deleted from Cloudinary: ${storageKey}`);
          return;
        }
      } catch { /* try next */ }
    }
  }

  getUrl(storageKey: string): string {
    if (!this.isConfigured || !this.cloudName) {
      return `https://res.cloudinary.com/demo/video/upload/${storageKey}`;
    }
    return cloudinary.url(storageKey, { secure: true });
  }

  async getSignedUrl(storageKey: string, expiresIn = 3600): Promise<string> {
    if (!this.isConfigured) return this.getUrl(storageKey);
    const timestamp = Math.floor(Date.now() / 1000) + expiresIn;
    const sig = cloudinary.utils.api_sign_request(
      { timestamp, public_id: storageKey },
      this.configService.get<string>('CLOUDINARY_API_SECRET')!,
    );
    return `https://res.cloudinary.com/${this.cloudName}/video/upload/s--${sig}--/${storageKey}`;
  }
}
