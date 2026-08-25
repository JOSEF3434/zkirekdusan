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
      const uploadOptions: Record<string, any> = {
        folder: subfolder,
        resource_type: resourceType,
        // Use original filename without extension as public_id base
        use_filename: true,
        unique_filename: true,
      };

      if (isVideo) {
        // For videos: request eager async transformation to generate HLS streaming
        // Cloudinary will transcode in the background — we use the streaming profile URL
        uploadOptions.eager = [
          // Generate adaptive HLS with Cloudinary's sp_hd streaming profile
          { streaming_profile: 'hd', format: 'm3u8' },
        ];
        uploadOptions.eager_async = true; // Don't block upload on transcoding
        // Request all common formats for maximum compatibility
        uploadOptions.format = 'mp4'; // Ensure output is MP4 container
        uploadOptions.transformation = [
          { quality: 'auto', fetch_format: 'mp4' },
        ];
      }

      const uploadStream = cloudinary.uploader.upload_stream(
        uploadOptions,
        (error, result) => {
          if (error) {
            this.logger.error('Cloudinary upload failed', error);
            return reject(error);
          }
          if (!result) return reject(new Error('Cloudinary upload returned null'));

          // Use secure_url as the direct playback URL
          const url = result.secure_url;

          this.logger.log(`Cloudinary upload: ${result.public_id} → ${url}`);
          this.logger.log(`Resource type: ${result.resource_type}, format: ${result.format}`);

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

  /**
   * Returns the Cloudinary HLS streaming URL for a video.
   * Uses the sp_hd streaming profile which generates adaptive bitrate HLS.
   * Format: https://res.cloudinary.com/{cloud}/video/upload/sp_hd/{public_id}.m3u8
   */
  getVideoStreamingUrl(publicId: string): string {
    if (!this.isConfigured || !this.cloudName) {
      return `https://res.cloudinary.com/demo/video/upload/sp_hd/${publicId}.m3u8`;
    }
    // Cloudinary streaming profile URL — works without transcoding being complete
    return `https://res.cloudinary.com/${this.cloudName}/video/upload/sp_hd/${publicId}.m3u8`;
  }

  /**
   * Returns a direct MP4 URL with quality transformation for a specific height.
   * Used as fallback renditions when HLS is not yet available.
   */
  getVideoRenditionUrl(publicId: string, height: number): string {
    if (!this.isConfigured || !this.cloudName) {
      return `https://res.cloudinary.com/demo/video/upload/h_${height},q_auto/${publicId}.mp4`;
    }
    return `https://res.cloudinary.com/${this.cloudName}/video/upload/h_${height},c_scale,q_auto,vc_auto/${publicId}.mp4`;
  }

  /**
   * Returns the direct MP4 URL with auto quality/format optimization.
   * This is the most compatible fallback for all devices.
   */
  getVideoDirectUrl(publicId: string): string {
    if (!this.isConfigured || !this.cloudName) {
      return `https://res.cloudinary.com/demo/video/upload/q_auto,vc_auto,f_mp4/${publicId}.mp4`;
    }
    return `https://res.cloudinary.com/${this.cloudName}/video/upload/q_auto,vc_auto,f_mp4/${publicId}.mp4`;
  }

  /**
   * Returns an optimized image URL from Cloudinary.
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
   * Helper to check if a given URL is a Cloudinary URL.
   */
  static isCloudinaryUrl(url: string): boolean {
    return url.includes('res.cloudinary.com') || url.includes('cloudinary.com');
  }

  /**
   * Extracts the public_id from a Cloudinary secure_url.
   * e.g. https://res.cloudinary.com/cloud/video/upload/stories/abc123.mp4 → stories/abc123
   */
  static extractPublicId(cloudinaryUrl: string): string | null {
    try {
      const url = new URL(cloudinaryUrl);
      // Path format: /cloud/video/upload/[transformations]/public_id.ext
      const parts = url.pathname.split('/upload/');
      if (parts.length < 2) return null;
      const afterUpload = parts[1];
      // Remove any transformation segments (they don't contain '/')
      // Public ID is the last part(s) of the path, stripping extension
      const withoutExt = afterUpload.replace(/\.[^/.]+$/, '');
      // Remove leading transformation segments (e.g., q_auto,f_mp4/)
      const segments = withoutExt.split('/');
      // Find where folder segments start (skip transform-only segments like q_auto,h_720)
      let startIdx = 0;
      for (let i = 0; i < segments.length - 1; i++) {
        if (segments[i].includes('_') && !segments[i].includes('%')) {
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
