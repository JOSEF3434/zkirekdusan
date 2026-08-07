// src/modules/uploads/providers/minio.provider.ts
import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as Minio from 'minio';
import { IStorageProvider, StorageUploadResult } from './storage.interface.js';

@Injectable()
export class MinioStorageProvider implements IStorageProvider, OnModuleInit {
  private readonly logger = new Logger(MinioStorageProvider.name);
  private minioClient: Minio.Client;
  private readonly bucketName: string;
  private readonly endpoint: string;
  private readonly port: number;
  private readonly useSSL: boolean;

  constructor(private readonly configService: ConfigService) {
    this.endpoint = this.configService.get<string>('MINIO_ENDPOINT') ?? 'localhost';
    this.port = parseInt(this.configService.get<string>('MINIO_PORT') ?? '9000', 10);
    this.useSSL = this.configService.get<string>('MINIO_USE_SSL') === 'true';
    this.bucketName = this.configService.get<string>('MINIO_BUCKET') ?? 'streamhub';
    
    this.minioClient = new Minio.Client({
      endPoint: this.endpoint,
      port: this.port,
      useSSL: this.useSSL,
      accessKey: this.configService.get<string>('MINIO_ACCESS_KEY') ?? 'minioadmin',
      secretKey: this.configService.get<string>('MINIO_SECRET_KEY') ?? 'minioadmin',
    });
  }

  async onModuleInit() {
    try {
      const exists = await this.minioClient.bucketExists(this.bucketName);
      if (!exists) {
        await this.minioClient.makeBucket(this.bucketName, 'us-east-1');
        
        // Make bucket public for public URLs
        const policy = {
          Version: '2012-10-17',
          Statement: [
            {
              Effect: 'Allow',
              Principal: '*',
              Action: ['s3:GetObject'],
              Resource: [`arn:aws:s3:::${this.bucketName}/*`],
            },
          ],
        };
        await this.minioClient.setBucketPolicy(this.bucketName, JSON.stringify(policy));
        this.logger.log(`Created bucket '${this.bucketName}' and set public policy`);
      }
    } catch (error) {
      this.logger.warn(`Could not verify/create MinIO bucket: ${(error as Error).message}`);
    }
  }

  async upload(
    file: { buffer: Buffer; originalname: string; mimetype: string; size: number },
    subfolder: string,
  ): Promise<StorageUploadResult> {
    const key = `${subfolder}/${Date.now()}-${file.originalname}`.replace(/\\/g, '/');
    
    await this.minioClient.putObject(
      this.bucketName,
      key,
      file.buffer,
      file.size,
      { 'Content-Type': file.mimetype }
    );
    
    this.logger.log(`Uploaded file to MinIO: ${key}`);
    
    return {
      storageKey: key,
      url: this.getUrl(key),
      provider: 'MINIO',
    };
  }

  async delete(storageKey: string): Promise<void> {
    await this.minioClient.removeObject(this.bucketName, storageKey);
    this.logger.log(`[MinIO Provider] Deleted ${storageKey}`);
  }

  getUrl(storageKey: string): string {
    const protocol = this.useSSL ? 'https' : 'http';
    return `${protocol}://${this.endpoint}:${this.port}/${this.bucketName}/${storageKey}`;
  }
  
  async getSignedUrl(storageKey: string, expiresIn = 3600): Promise<string> {
    return this.minioClient.presignedGetObject(this.bucketName, storageKey, expiresIn);
  }
}
