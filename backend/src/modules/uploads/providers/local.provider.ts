// src/modules/uploads/providers/local.provider.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import fs from 'fs/promises';
import path from 'path';
import crypto from 'crypto';
import { IStorageProvider, StorageUploadResult } from './storage.interface.js';

@Injectable()
export class LocalStorageProvider implements IStorageProvider {
  private readonly logger = new Logger(LocalStorageProvider.name);
  private readonly uploadDir: string;
  private readonly baseUrl: string;

  constructor(private readonly configService: ConfigService) {
    this.uploadDir = path.resolve(process.cwd(), 'uploads');
    this.baseUrl =
      this.configService.get<string>('APP_URL') ?? 'http://localhost:3000';
  }

  async upload(
    file: {
      buffer: Buffer;
      originalname: string;
      mimetype: string;
      size: number;
    },
    subfolder: string,
  ): Promise<StorageUploadResult> {
    const folderPath = path.join(this.uploadDir, subfolder);
    await fs.mkdir(folderPath, { recursive: true });

    const ext = path.extname(file.originalname).toLowerCase();
    const randomName = `${crypto.randomUUID()}${ext}`;
    const filePath = path.join(folderPath, randomName);
    const storageKey = path.join(subfolder, randomName).replace(/\\/g, '/');

    await fs.writeFile(filePath, file.buffer);
    const url = `${this.baseUrl}/uploads/${storageKey}`;

    this.logger.log(`File saved locally: ${filePath} -> ${url}`);

    return {
      storageKey,
      url,
      provider: 'LOCAL',
    };
  }

  async delete(storageKey: string): Promise<void> {
    const filePath = path.join(this.uploadDir, storageKey);
    try {
      await fs.unlink(filePath);
      this.logger.log(`Local file deleted: ${filePath}`);
    } catch (err) {
      this.logger.warn(`Could not delete local file ${filePath}: ${err}`);
    }
  }

  getUrl(storageKey: string): string {
    return `${this.baseUrl}/uploads/${storageKey}`;
  }
}
