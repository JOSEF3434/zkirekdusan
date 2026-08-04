// src/modules/uploads/providers/minio.provider.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IStorageProvider, StorageUploadResult } from './storage.interface.js';

@Injectable()
export class MinioStorageProvider implements IStorageProvider {
  private readonly logger = new Logger(MinioStorageProvider.name);
  private readonly endpoint: string;

  constructor(private readonly configService: ConfigService) {
    this.endpoint =
      this.configService.get<string>('MINIO_ENDPOINT') ?? 'localhost';
  }

  upload(
    file: {
      buffer: Buffer;
      originalname: string;
      mimetype: string;
      size: number;
    },
    subfolder: string,
  ): Promise<StorageUploadResult> {
    this.logger.log(
      `[MinIO Provider Ready] Simulating MinIO upload for ${file.originalname} into ${subfolder}`,
    );
    const key = `${subfolder}/${Date.now()}-${file.originalname}`;
    return Promise.resolve({
      storageKey: key,
      url: `http://${this.endpoint}:9000/media/${key}`,
      provider: 'MINIO',
    });
  }

  delete(storageKey: string): Promise<void> {
    this.logger.log(`[MinIO Provider] Deleting ${storageKey}`);
    return Promise.resolve();
  }

  getUrl(storageKey: string): string {
    return `http://${this.endpoint}:9000/media/${storageKey}`;
  }
}
