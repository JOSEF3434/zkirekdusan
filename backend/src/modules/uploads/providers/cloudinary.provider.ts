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
  private readonly apiKey: string;
  private readonly apiSecret: string;

  constructor(private readonly configService: ConfigService) {
    let cloud_name =
      this.configService.get<string>('CLOUDINARY_CLOUD_NAME') ||
      this.configService.get<string>('Cloud_name') ||
      process.env.CLOUDINARY_CLOUD_NAME ||
      process.env.Cloud_name;
    let api_key =
      this.configService.get<string>('CLOUDINARY_API_KEY') ||
      this.configService.get<string>('your_api_key') ||
      process.env.CLOUDINARY_API_KEY ||
      process.env.your_api_key;
    let api_secret =
      this.configService.get<string>('CLOUDINARY_API_SECRET') ||
      this.configService.get<string>('your_api_secret') ||
      process.env.CLOUDINARY_API_SECRET ||
      process.env.your_api_secret;

    const cloudinaryUrl =
      this.configService.get<string>('CLOUDINARY_URL') ||
      process.env.CLOUDINARY_URL;

    if ((!cloud_name || !api_key || !api_secret) && cloudinaryUrl) {
      try {
        const parsed = new URL(cloudinaryUrl);
        api_key = api_key || decodeURIComponent(parsed.username);
        api_secret = api_secret || decodeURIComponent(parsed.password);
        cloud_name = cloud_name || parsed.hostname;
      } catch (_) {}
    }

    // Default to verified project Cloudinary credentials if not provided in environment
    cloud_name = cloud_name || 'v6zdpkoh';
    api_key = api_key || '667751121616522';
    api_secret = api_secret || '5f7EQfkTHv8XbGL2A3gzAVSVHaw';

    if (cloud_name && api_key && api_secret) {
      cloudinary.config({ cloud_name, api_key, api_secret, secure: true });
      this.isConfigured = true;
      this.cloudName = cloud_name;
      this.apiKey = api_key;
      this.apiSecret = api_secret;
      this.logger.log(`Cloudinary configured: cloud=${cloud_name}`);
    } else {
      this.isConfigured = false;
      this.cloudName = '';
      this.apiKey = '';
      this.apiSecret = '';
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
    file: {
      buffer: Buffer;
      originalname: string;
      mimetype: string;
      size: number;
    },
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
    const resourceType: 'image' | 'video' | 'raw' =
      isVideo || isAudio ? 'video' : isImage ? 'image' : 'raw';

    return new Promise((resolve, reject) => {
      const uploadOptions: Record<string, any> = {
        folder: subfolder,
        resource_type: resourceType,
        use_filename: true,
        unique_filename: true,
      };

      if (isVideo) {
        // Video options: eager HLS transcoding & optimized MP4
        uploadOptions.eager = [{ streaming_profile: 'hd', format: 'm3u8' }];
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
            (error, result) =>
              this.handleUploadResponse(
                error,
                result,
                resourceType,
                resolve,
                reject,
              ),
          )
        : cloudinary.uploader.upload_stream(uploadOptions, (error, result) =>
            this.handleUploadResponse(
              error,
              result,
              resourceType,
              resolve,
              reject,
            ),
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
    const isVideo =
      mimetype?.startsWith('video/') ||
      ['.mp4', '.mov', '.avi', '.webm', '.mkv'].includes(ext);
    const isAudio =
      mimetype?.startsWith('audio/') ||
      ['.mp3', '.aac', '.wav', '.m4a', '.ogg', '.webm'].includes(ext);
    const isImage =
      mimetype?.startsWith('image/') ||
      ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'].includes(ext);

    const resourceType: 'image' | 'video' | 'raw' =
      isVideo || isAudio ? 'video' : isImage ? 'image' : 'raw';

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

    this.logger.log(
      `Cloudinary uploaded [${resourceType}]: ${result.public_id} -> ${result.secure_url}`,
    );

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
  async delete(
    storageKey: string,
    resourceType?: 'image' | 'video' | 'raw',
  ): Promise<void> {
    if (!this.isConfigured || !storageKey) return;

    const typesToTry: ('video' | 'image' | 'raw')[] = resourceType
      ? [resourceType]
      : ['video', 'image', 'raw'];

    for (const rt of typesToTry) {
      try {
        const r = await cloudinary.uploader.destroy(storageKey, {
          resource_type: rt,
        });
        if (r && r.result !== 'not found') {
          this.logger.log(`Deleted from Cloudinary [${rt}]: ${storageKey}`);
          return;
        }
      } catch (err: any) {
        this.logger.debug(
          `Could not delete key '${storageKey}' as ${rt}: ${err?.message}`,
        );
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
  static extractPublicId(
    cloudinaryUrl: string | null | undefined,
  ): string | null {
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
        if (
          segments[i].startsWith('v') &&
          /^\d+$/.test(segments[i].substring(1))
        ) {
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

  private get basicAuthHeader(): string {
    return `Basic ${Buffer.from(`${this.apiKey}:${this.apiSecret}`).toString('base64')}`;
  }

  /**
   * Create a live stream resource on Cloudinary (RTMP ingest -> HLS + Archive output).
   */
  async createLiveStream(
    name: string,
    options: { idleTimeoutSec?: number; maxRuntimeSec?: number } = {},
  ): Promise<CloudinaryLiveStreamResource> {
    if (!this.isConfigured) {
      throw new Error('Cloudinary is not configured with credentials');
    }

    const res = await fetch(
      `https://api.cloudinary.com/v2/video/${this.cloudName}/live_streams`,
      {
        method: 'POST',
        headers: {
          Authorization: this.basicAuthHeader,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name,
          input: { type: 'rtmp' },
          idle_timeout_sec: options.idleTimeoutSec ?? 120,
          max_runtime_sec: Math.min(options.maxRuntimeSec ?? 36000, 36000),
        }),
      },
    );

    if (!res.ok) {
      const errBody = await res.text();
      this.logger.error(
        `Cloudinary createLiveStream failed (${res.status}): ${errBody}`,
      );
      throw new Error(`Failed to create Cloudinary live stream: ${errBody}`);
    }

    const json = await res.json();
    const stream = json.data;
    if (!stream) {
      throw new Error('Cloudinary live stream creation returned empty data');
    }

    const hlsOutput = stream.outputs?.find((o: any) => o.type === 'hls');
    const archiveOutput = stream.outputs?.find(
      (o: any) => o.type === 'archive',
    );

    return {
      id: stream.id,
      name: stream.name,
      status: stream.status,
      rtmpIngestUrl: stream.input?.uri || 'rtmp://live.cloudinary.com/streams',
      streamKey: stream.input?.stream_key,
      hlsUrl:
        hlsOutput?.uri ||
        `https://res.cloudinary.com/${this.cloudName}/video/live/live_stream_${stream.id}_hls.m3u8`,
      archivePublicId:
        archiveOutput?.public_id || `live_stream_${stream.id}_archive`,
    };
  }

  /**
   * Activate a live stream and wait until Cloudinary confirms status=="active".
   * Cloudinary activation is asynchronous; calling publish before the stream
   * is active results in ConnectException: Failed to connectStream on Android.
   * We poll up to maxWaitMs (default 35 s) with pollIntervalMs (default 800 ms)
   * intervals before returning. The extra headroom ensures the RTMP ingest
   * endpoint is fully ready before the mobile client attempts to connect.
   */
  async activateLiveStream(
    streamId: string,
    maxWaitMs = 35_000,
    pollIntervalMs = 800,
  ): Promise<void> {
    if (!this.isConfigured) return;
    // 1. Send the activation request
    try {
      const res = await fetch(
        `https://api.cloudinary.com/v2/video/${this.cloudName}/live_streams/${streamId}/activate`,
        {
          method: 'POST',
          headers: { Authorization: this.basicAuthHeader },
        },
      );
      if (!res.ok) {
        const body = await res.text();
        this.logger.warn(
          `Cloudinary activateLiveStream warning (${res.status}): ${body}`,
        );
        // Don't throw — stream may already be active
      } else {
        this.logger.log(`Cloudinary live stream ${streamId} activation requested.`);
      }
    } catch (err: any) {
      this.logger.error(
        `Error activating Cloudinary live stream ${streamId}: ${err.message}`,
      );
      // Continue polling — the stream may already be active
    }

    // 2. Poll until status becomes "active" or we time out
    const deadline = Date.now() + maxWaitMs;
    let lastStatus = 'unknown';
    while (Date.now() < deadline) {
      await new Promise((r) => setTimeout(r, pollIntervalMs));
      try {
        const data = await this.getLiveStream(streamId);
        lastStatus = data?.status ?? 'unknown';
        if (lastStatus === 'active') {
          this.logger.log(
            `Cloudinary live stream ${streamId} is now active — RTMP ingest ready.`,
          );
          return;
        }
      } catch {
        // ignore poll errors, keep retrying
      }
    }

    // Timed out — log a warning but don't throw so the stream can still proceed
    this.logger.warn(
      `Cloudinary live stream ${streamId} did not reach "active" within ${maxWaitMs}ms ` +
        `(last status: ${lastStatus}). Client will attempt RTMP publish anyway — ` +
        `it may need additional retries on first connect.`,
    );
  }

  /**
   * Manually idle a live stream when broadcasting ends, triggering VOD archiving.
   */
  async idleLiveStream(streamId: string): Promise<void> {
    if (!this.isConfigured) return;
    try {
      const res = await fetch(
        `https://api.cloudinary.com/v2/video/${this.cloudName}/live_streams/${streamId}/idle`,
        {
          method: 'POST',
          headers: { Authorization: this.basicAuthHeader },
        },
      );
      if (!res.ok) {
        const body = await res.text();
        this.logger.warn(
          `Cloudinary idleLiveStream warning (${res.status}): ${body}`,
        );
      }
    } catch (err: any) {
      this.logger.error(
        `Error idling Cloudinary live stream ${streamId}: ${err.message}`,
      );
    }
  }

  /**
   * Query status of a live stream on Cloudinary.
   */
  async getLiveStream(streamId: string): Promise<any> {
    if (!this.isConfigured) return null;
    try {
      const res = await fetch(
        `https://api.cloudinary.com/v2/video/${this.cloudName}/live_streams/${streamId}`,
        {
          headers: { Authorization: this.basicAuthHeader },
        },
      );
      if (!res.ok) return null;
      const json = await res.json();
      return json.data;
    } catch {
      return null;
    }
  }
}

export interface CloudinaryLiveStreamResource {
  id: string;
  name: string;
  status: string;
  rtmpIngestUrl: string;
  streamKey: string;
  hlsUrl: string;
  archivePublicId: string;
}
