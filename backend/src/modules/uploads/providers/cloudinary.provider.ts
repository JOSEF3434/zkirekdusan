import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary } from 'cloudinary';
import { IStorageProvider, StorageUploadResult } from './storage.interface.js';
import { Readable } from 'stream';
import path from 'path';

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

  get configured(): boolean {
    return this.isConfigured;
  }

  get currentCloudName(): string {
    return this.cloudName;
  }

  /**
   * Upload buffer to Cloudinary with automatic resource-type detection,
   * proper folder namespacing, and optimized transformations.
   */
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
        resourceType: 'raw',
        bytes: file.size,
      };
    }

    const isVideo = file.mimetype.startsWith('video/');
    const isImage = file.mimetype.startsWith('image/');
    const isAudio = file.mimetype.startsWith('audio/');
    // In Cloudinary, audio is treated under the 'video' resource type
    const resourceType: 'image' | 'video' | 'raw' = isVideo || isAudio ? 'video' : isImage ? 'image' : 'raw';

    return new Promise((resolve, reject) => {
      const uploadOptions: Record<string, any> = {
        folder: subfolder,
        resource_type: resourceType,
        use_filename: true,
        unique_filename: true,
      };

      if (isVideo) {
        // Video options: eager HLS transcoding & optimized MP4
        uploadOptions.eager = [
          { streaming_profile: 'hd', format: 'm3u8' },
        ];
        uploadOptions.eager_async = true;
        uploadOptions.format = 'mp4';
        uploadOptions.transformation = [
          { quality: 'auto', fetch_format: 'mp4' },
        ];
      }

      // If file is large (> 20MB) or video, use upload_large_stream
      const isLarge = file.size > 20 * 1024 * 1024;
      const uploaderMethod = isLarge
        ? cloudinary.uploader.upload_large_stream(
            { ...uploadOptions, chunk_size: 10 * 1024 * 1024 },
            (error, result) => this.handleUploadResponse(error, result, resourceType, resolve, reject),
          )
        : cloudinary.uploader.upload_stream(
            uploadOptions,
            (error, result) => this.handleUploadResponse(error, result, resourceType, resolve, reject),
          );

      const readStream = Readable.from(file.buffer);
      readStream.pipe(uploaderMethod);
    });
  }

  /**
   * Upload a local file path to Cloudinary (used during database migrations)
   */
  async uploadFilePath(
    filePath: string,
    subfolder: string,
    mimetype?: string,
  ): Promise<StorageUploadResult> {
    if (!this.isConfigured) {
      throw new Error('Cloudinary is not configured');
    }

    const ext = path.extname(filePath).toLowerCase();
    const isVideo = mimetype?.startsWith('video/') || ['.mp4', '.mov', '.avi', '.webm', '.mkv'].includes(ext);
    const isAudio = mimetype?.startsWith('audio/') || ['.mp3', '.aac', '.wav', '.m4a', '.ogg', '.webm'].includes(ext);
    const isImage = mimetype?.startsWith('image/') || ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'].includes(ext);

    const resourceType: 'image' | 'video' | 'raw' = (isVideo || isAudio) ? 'video' : isImage ? 'image' : 'raw';

    const uploadOptions: Record<string, any> = {
      folder: subfolder,
      resource_type: resourceType,
      use_filename: true,
      unique_filename: true,
    };

    if (isVideo) {
      uploadOptions.format = 'mp4';
      uploadOptions.transformation = [{ quality: 'auto', fetch_format: 'mp4' }];
    }

    const result = await cloudinary.uploader.upload(filePath, uploadOptions);
    return {
      storageKey: result.public_id,
      url: result.secure_url,
      provider: 'CLOUDINARY',
      width: result.width,
      height: result.height,
      duration: result.duration,
      format: result.format,
      resourceType,
      bytes: result.bytes,
    };
  }

  private handleUploadResponse(
    error: any,
    result: any,
    resourceType: 'image' | 'video' | 'raw',
    resolve: (res: StorageUploadResult) => void,
    reject: (err: any) => void,
  ) {
    if (error) {
      this.logger.error('Cloudinary upload error', error);
      return reject(error);
    }
    if (!result) {
      return reject(new Error('Cloudinary upload returned empty result'));
    }

    this.logger.log(`Cloudinary uploaded [${resourceType}]: ${result.public_id} -> ${result.secure_url}`);

    resolve({
      storageKey: result.public_id,
      url: result.secure_url,
      provider: 'CLOUDINARY',
      width: result.width,
      height: result.height,
      duration: result.duration,
      format: result.format,
      resourceType,
      bytes: result.bytes,
    });
  }

  /**
   * Deletes an asset safely from Cloudinary.
   */
  async delete(storageKey: string, resourceType?: 'image' | 'video' | 'raw'): Promise<void> {
    if (!this.isConfigured || !storageKey) return;

    const typesToTry: ('video' | 'image' | 'raw')[] = resourceType
      ? [resourceType]
      : ['video', 'image', 'raw'];

    for (const rt of typesToTry) {
      try {
        const r = await cloudinary.uploader.destroy(storageKey, { resource_type: rt });
        if (r && r.result !== 'not found') {
          this.logger.log(`Deleted from Cloudinary [${rt}]: ${storageKey}`);
          return;
        }
      } catch (err: any) {
        this.logger.debug(`Could not delete key '${storageKey}' as ${rt}: ${err?.message}`);
      }
    }
  }

  /**
   * Public URL of stored object
   */
  getUrl(storageKey: string): string {
    if (!this.isConfigured || !this.cloudName) {
      return `https://res.cloudinary.com/demo/image/upload/${storageKey}`;
    }
    return cloudinary.url(storageKey, { secure: true });
  }

  /**
   * Returns the Cloudinary HLS streaming URL for a video.
   */
  getVideoStreamingUrl(publicId: string): string {
    if (!this.isConfigured || !this.cloudName) {
      return `https://res.cloudinary.com/demo/video/upload/sp_hd/${publicId}.m3u8`;
    }
    return `https://res.cloudinary.com/${this.cloudName}/video/upload/sp_hd/${publicId}.m3u8`;
  }

  /**
   * Returns a direct MP4 URL with quality transformation for a specific height rendition.
   */
  getVideoRenditionUrl(publicId: string, height: number): string {
    if (!this.isConfigured || !this.cloudName) {
      return `https://res.cloudinary.com/demo/video/upload/h_${height},c_scale,q_auto,vc_auto/${publicId}.mp4`;
    }
    return `https://res.cloudinary.com/${this.cloudName}/video/upload/h_${height},c_scale,q_auto,vc_auto/${publicId}.mp4`;
  }

  /**
   * Returns the direct universal MP4 URL with auto quality/format optimization.
   */
  getVideoDirectUrl(publicId: string): string {
    if (!this.isConfigured || !this.cloudName) {
      return `https://res.cloudinary.com/demo/video/upload/q_auto,vc_auto,f_mp4/${publicId}.mp4`;
    }
    return `https://res.cloudinary.com/${this.cloudName}/video/upload/q_auto,vc_auto,f_mp4/${publicId}.mp4`;
  }

  /**
   * Returns an optimized image URL from Cloudinary with optional width & height transformations.
   */
  getImageUrl(publicId: string, width?: number, height?: number): string {
    if (!this.isConfigured || !this.cloudName) {
      return `https://res.cloudinary.com/demo/image/upload/${publicId}`;
    }
    const transforms: string[] = ['q_auto', 'f_auto'];
    if (width) transforms.push(`w_${width}`);
    if (height) transforms.push(`h_${height}`);
    const t = transforms.join(',');
    return `https://res.cloudinary.com/${this.cloudName}/image/upload/${t}/${publicId}`;
  }

  /**
   * Direct download/playback URL for raw files (documents, audio, etc.)
   */
  getRawUrl(publicId: string): string {
    if (!this.isConfigured || !this.cloudName) {
      return `https://res.cloudinary.com/demo/raw/upload/${publicId}`;
    }
    return `https://res.cloudinary.com/${this.cloudName}/raw/upload/${publicId}`;
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

  /**
   * Checks if a given URL is hosted on Cloudinary.
   */
  static isCloudinaryUrl(url: string | null | undefined): boolean {
    if (!url) return false;
    return url.includes('res.cloudinary.com') || url.includes('cloudinary.com');
  }

  /**
   * Extracts the public_id from a Cloudinary secure_url.
   */
  static extractPublicId(cloudinaryUrl: string | null | undefined): string | null {
    if (!cloudinaryUrl) return null;
    try {
      const url = new URL(cloudinaryUrl);
      const parts = url.pathname.split('/upload/');
      if (parts.length < 2) return null;
      const afterUpload = parts[1];
      const withoutExt = afterUpload.replace(/\.[^/.]+$/, '');
      const segments = withoutExt.split('/');
      let startIdx = 0;
      for (let i = 0; i < segments.length - 1; i++) {
        if (segments[i].startsWith('v') && /^\d+$/.test(segments[i].substring(1))) {
          startIdx = i + 1;
          break;
        } else if (
          segments[i].includes('_') ||
          segments[i].startsWith('sp_') ||
          segments[i].startsWith('s--')
        ) {
          startIdx = i + 1;
        } else {
          break;
        }
      }
      return segments.slice(startIdx).join('/');
    } catch {
      return null;
    }
  }
}
