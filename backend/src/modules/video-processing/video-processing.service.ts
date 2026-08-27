// src/modules/video-processing/video-processing.service.ts
import { Injectable, Logger, Inject } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service.js';
import { VideoStatus, VideoResolution, FileProvider } from '@prisma/client';
import ffmpeg from 'fluent-ffmpeg';
import path from 'path';
import fs from 'fs/promises';
import { existsSync } from 'fs';
import type { IStorageProvider } from '../uploads/providers/storage.interface.js';
import { STORAGE_PROVIDER_TOKEN } from '../uploads/providers/storage.factory.js';
import { CloudinaryStorageProvider } from '../uploads/providers/cloudinary.provider.js';

export interface TranscodeJobData {
  videoId: string;
  sourceFilePath: string;
  storageKey: string;
}

@Injectable()
export class VideoProcessingService {
  private readonly logger = new Logger(VideoProcessingService.name);
  private readonly uploadsDir: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    @Inject(STORAGE_PROVIDER_TOKEN)
    private readonly storageProvider: IStorageProvider & Record<string, any>,
  ) {
    this.uploadsDir = path.resolve(process.cwd(), 'uploads');
  }

  /**
   * Main entry point for video processing.
   * When using Cloudinary, bypasses FFmpeg and uses native Cloudinary streaming.
   * When using local storage, runs FFmpeg HLS transcoding.
   */
  async processVideo(data: TranscodeJobData): Promise<void> {
    const { videoId, storageKey } = data;
    this.logger.log(`Starting processing for Video [${videoId}]...`);

    const video = await this.prisma.video.findUnique({
      where: { id: videoId },
      include: { sourceFile: true },
    });

    if (!video) {
      this.logger.error(`Video [${videoId}] not found in database.`);
      return;
    }

    // ── Cloudinary path: use Cloudinary's native streaming ─────────────────
    if (this.storageProvider.providerType === 'CLOUDINARY') {
      await this._processCloudinaryVideo(videoId, storageKey, video);
      return;
    }

    // ── Local/MinIO path: FFmpeg HLS transcoding ───────────────────────────
    await this._processLocalVideo(data, video);
  }

  /**
   * Cloudinary-native video processing.
   * Builds HLS streaming URL and rendition URLs directly from the Cloudinary public_id.
   * No FFmpeg needed — Cloudinary handles transcoding server-side.
   */
  private async _processCloudinaryVideo(
    videoId: string,
    storageKey: string,
    video: any,
  ): Promise<void> {
    this.logger.log(
      `[Cloudinary] Processing video [${videoId}] with public_id: ${storageKey}`,
    );

    const cloudinaryProvider = this.storageProvider as CloudinaryStorageProvider;

    try {
      await this.prisma.video.update({
        where: { id: videoId },
        data: { status: VideoStatus.PROCESSING },
      });

      // The storageKey is the Cloudinary public_id — use it directly
      // If video.sourceFile?.storageKey is set, prefer it (more reliable)
      const publicId = video.sourceFile?.storageKey ?? storageKey;

      // Build Cloudinary HLS streaming URL (adaptive bitrate via sp_hd profile)
      const hlsStreamingUrl = cloudinaryProvider.getVideoStreamingUrl(publicId);

      // Build direct MP4 fallback URL (auto-quality, auto-format)
      const directMp4Url = cloudinaryProvider.getVideoDirectUrl(publicId);

      this.logger.log(`[Cloudinary] HLS URL: ${hlsStreamingUrl}`);
      this.logger.log(`[Cloudinary] Direct URL: ${directMp4Url}`);

      // Define rendition heights that Cloudinary will serve on-demand
      const renditionTargets: {
        res: VideoResolution;
        height: number;
        width: number;
        bitrate: number;
      }[] = [
        { res: VideoResolution.R_240P, height: 240, width: 426, bitrate: 400 },
        { res: VideoResolution.R_360P, height: 360, width: 640, bitrate: 800 },
        { res: VideoResolution.R_480P, height: 480, width: 854, bitrate: 1200 },
        { res: VideoResolution.R_720P, height: 720, width: 1280, bitrate: 2500 },
        { res: VideoResolution.R_1080P, height: 1080, width: 1920, bitrate: 5000 },
      ];

      // Upsert rendition records pointing to Cloudinary on-demand URLs
      for (const target of renditionTargets) {
        const renditionUrl = cloudinaryProvider.getVideoRenditionUrl(
          publicId,
          target.height,
        );

        await this.prisma.videoRendition.upsert({
          where: {
            videoId_resolution: { videoId, resolution: target.res },
          },
          create: {
            videoId,
            resolution: target.res,
            height: target.height,
            width: target.width,
            bitrate: target.bitrate,
            fileSize: BigInt(0),
            storageKey: publicId,
            url: renditionUrl,
            provider: FileProvider.CLOUDINARY,
            isReady: true,
          },
          update: {
            url: renditionUrl,
            storageKey: publicId,
            isReady: true,
          },
        });
      }

      // Determine thumbnail URL if not already set
      const posterThumbnailUrl =
        video.thumbnailUrl && !video.thumbnailUrl.includes('localhost')
          ? video.thumbnailUrl
          : `https://res.cloudinary.com/${cloudinaryProvider.currentCloudName || 'v6zdpkoh'}/video/upload/so_1,q_auto,f_jpg/${publicId}.jpg`;

      // Update video to READY with HLS URL as primary + direct MP4 as fallback
      await this.prisma.video.update({
        where: { id: videoId },
        data: {
          status: VideoStatus.READY,
          hlsUrl: hlsStreamingUrl,
          thumbnailUrl: posterThumbnailUrl,
        },
      });

      this.logger.log(
        `[Cloudinary] Video [${videoId}] marked READY. HLS: ${hlsStreamingUrl}`,
      );
    } catch (err: any) {
      this.logger.error(
        `[Cloudinary] Error processing video [${videoId}]: ${err.message}`,
        err.stack,
      );
      // On Cloudinary, don't fail — the raw URL is still playable
      // Just mark as READY with whatever URL we have
      try {
        const currentVideo = await this.prisma.video.findUnique({
          where: { id: videoId },
          select: { hlsUrl: true, status: true },
        });
        if (currentVideo && currentVideo.status !== VideoStatus.READY) {
          await this.prisma.video.update({
            where: { id: videoId },
            data: { status: VideoStatus.READY },
          });
          this.logger.warn(
            `[Cloudinary] Video [${videoId}] marked READY as fallback after error`,
          );
        }
      } catch (fallbackErr) {
        this.logger.error(`Failed to set fallback READY status: ${fallbackErr}`);
      }
    }
  }

  /**
   * Local/FFmpeg video processing pipeline.
   * Only used when STORAGE_PROVIDER is LOCAL or MINIO.
   */
  private async _processLocalVideo(data: TranscodeJobData, video: any): Promise<void> {
    const { videoId, sourceFilePath } = data;

    await this.prisma.video.update({
      where: { id: videoId },
      data: { status: VideoStatus.PROCESSING },
    });

    try {
      const absoluteSourcePath = path.isAbsolute(sourceFilePath)
        ? sourceFilePath
        : path.join(this.uploadsDir, sourceFilePath);

      if (!existsSync(absoluteSourcePath)) {
        this.logger.warn(
          `Source file does not exist at ${absoluteSourcePath}. Marking video READY as fallback.`,
        );
        await this.prisma.video.update({
          where: { id: videoId },
          data: { status: VideoStatus.READY },
        });
        return;
      }

      const meta = await this.probeMetadata(absoluteSourcePath);
      const videoWidth = meta.width || 1920;
      const videoHeight = meta.height || 1080;
      const duration = meta.duration || 0;
      const fps = meta.fps || 30;

      const outputFolder = path.join(this.uploadsDir, 'videos', videoId);
      await fs.mkdir(outputFolder, { recursive: true });

      const thumbnails = await this.generateThumbnailSprite(absoluteSourcePath, outputFolder, videoId);
      const thumbnailUrlPaths: string[] = [];
      for (const thumb of thumbnails) {
        let thumbUrl = '';
        if (this.storageProvider.constructor.name !== 'LocalStorageProvider') {
          const buffer = await fs.readFile(thumb);
          const res = await this.storageProvider.upload({
            buffer,
            originalname: path.basename(thumb),
            mimetype: 'image/jpeg',
            size: buffer.length,
          }, `videos/${videoId}`);
          thumbUrl = res.url;
          await fs.unlink(thumb).catch(() => {});
        } else {
          const appUrl = this.configService.get<string>('APP_URL') ?? 'http://localhost:3000';
          const relThumbPath = `videos/${videoId}/${path.basename(thumb)}`.replace(/\\/g, '/');
          thumbUrl = `${appUrl}/uploads/${relThumbPath}`;
        }
        thumbnailUrlPaths.push(thumbUrl);
      }
      const thumbnailUrl = thumbnailUrlPaths[0] || '';

      const targets: {
        res: VideoResolution;
        height: number;
        width: number;
        bitrate: number;
        audioBitrate: number;
      }[] = [
        { res: VideoResolution.R_240P, height: 240, width: 426, bitrate: 400, audioBitrate: 64 },
        { res: VideoResolution.R_360P, height: 360, width: 640, bitrate: 800, audioBitrate: 96 },
        { res: VideoResolution.R_480P, height: 480, width: 854, bitrate: 1200, audioBitrate: 128 },
        { res: VideoResolution.R_720P, height: 720, width: 1280, bitrate: 2500, audioBitrate: 128 },
        { res: VideoResolution.R_1080P, height: 1080, width: 1920, bitrate: 5000, audioBitrate: 192 },
        { res: VideoResolution.R_4K, height: 2160, width: 3840, bitrate: 15000, audioBitrate: 192 },
      ].filter((t) => t.height <= videoHeight || t.height === 240);

      const hlsMasterPlaylistPath = path.join(outputFolder, 'master.m3u8');
      for (const target of targets) {
        const resFileName = `${target.height}p.m3u8`;
        const resPath = path.join(outputFolder, resFileName);
        await this.transcodeToHLS(
          absoluteSourcePath, resPath, target.width, target.height,
          target.bitrate, target.audioBitrate, fps,
        );
      }

      await this.buildMasterPlaylist(hlsMasterPlaylistPath, targets, fps);

      let masterUrl = '';
      const isRemoteStorage = this.storageProvider.providerType !== 'LOCAL';

      if (isRemoteStorage) {
        this.logger.log(`Uploading HLS files to remote storage...`);
        const files = await fs.readdir(outputFolder);
        for (const file of files) {
          if (file.endsWith('.m3u8') || file.endsWith('.ts')) {
            const filePath = path.join(outputFolder, file);
            const buffer = await fs.readFile(filePath);
            const mimeType = file.endsWith('.m3u8') ? 'application/vnd.apple.mpegurl' : 'video/MP2T';
            const res = await this.storageProvider.upload({
              buffer, originalname: file, mimetype: mimeType, size: buffer.length,
            }, `videos/${videoId}`);
            if (file === 'master.m3u8') masterUrl = res.url;
            await fs.unlink(filePath).catch(() => {});
          }
        }
      } else {
        const appUrl = this.configService.get<string>('APP_URL') ?? 'http://localhost:3000';
        const masterRelPath = `videos/${videoId}/master.m3u8`.replace(/\\/g, '/');
        masterUrl = `${appUrl}/uploads/${masterRelPath}`;
      }

      for (const target of targets) {
        const resFileName = `${target.height}p.m3u8`;
        let renditionUrl = '';
        if (isRemoteStorage) {
          const urlBase = masterUrl.substring(0, masterUrl.lastIndexOf('/'));
          renditionUrl = `${urlBase}/${resFileName}`;
        } else {
          const appUrl = this.configService.get<string>('APP_URL') ?? 'http://localhost:3000';
          const relResPath = `videos/${videoId}/${resFileName}`.replace(/\\/g, '/');
          renditionUrl = `${appUrl}/uploads/${relResPath}`;
        }

        await this.prisma.videoRendition.upsert({
          where: { videoId_resolution: { videoId, resolution: target.res } },
          create: {
            videoId, resolution: target.res, height: target.height,
            width: target.width, bitrate: target.bitrate, fileSize: BigInt(0),
            storageKey: `videos/${videoId}/${resFileName}`, url: renditionUrl,
            provider: isRemoteStorage ? FileProvider.S3 : FileProvider.LOCAL,
            isReady: true,
          },
          update: { url: renditionUrl, isReady: true },
        });
      }

      await this.prisma.video.update({
        where: { id: videoId },
        data: {
          status: VideoStatus.READY, duration, width: videoWidth, height: videoHeight,
          bitrate: meta.bitrate || 2000, thumbnailUrl, hlsUrl: masterUrl,
        },
      });

      this.logger.log(`Video [${videoId}] processed successfully. HLS URL: ${masterUrl}`);
    } catch (err: any) {
      this.logger.error(`Error processing video [${videoId}]: ${err.message}`, err.stack);
      throw err;
    }
  }

  private probeMetadata(filePath: string): Promise<{
    duration?: number;
    width?: number;
    height?: number;
    bitrate?: number;
    fps?: number;
  }> {
    return new Promise((resolve) => {
      ffmpeg.ffprobe(filePath, (err, metadata) => {
        if (err || !metadata) {
          return resolve({ duration: 0, width: 1280, height: 720, bitrate: 2000, fps: 30 });
        }
        const videoStream = metadata.streams.find((s) => s.codec_type === 'video');
        let fps = 30;
        if (videoStream?.r_frame_rate) {
          const parts = videoStream.r_frame_rate.split('/');
          if (parts.length === 2 && parseInt(parts[1]) > 0) {
            fps = Math.round(parseInt(parts[0]) / parseInt(parts[1]));
          }
        }
        resolve({
          duration: metadata.format.duration || 0,
          width: videoStream?.width || 1280,
          height: videoStream?.height || 720,
          bitrate: metadata.format.bit_rate ? Math.round(metadata.format.bit_rate / 1000) : 2000,
          fps: isNaN(fps) ? 30 : fps,
        });
      });
    });
  }

  private generateThumbnailSprite(
    sourcePath: string,
    outputFolder: string,
    videoId: string,
  ): Promise<string[]> {
    return new Promise((resolve, _reject) => {
      const timestamps = ['10%', '20%', '30%', '40%', '50%', '60%', '70%', '80%', '90%'];
      ffmpeg(sourcePath)
        .screenshots({
          timestamps, filename: `thumb_${videoId}_%i.jpg`,
          folder: outputFolder, size: '640x360',
        })
        .on('end', async () => {
          const files: string[] = [];
          for (let i = 1; i <= timestamps.length; i++) {
            const file = path.join(outputFolder, `thumb_${videoId}_${i}.jpg`);
            if (existsSync(file)) files.push(file);
          }
          resolve(files);
        })
        .on('error', (err) => {
          this.logger.warn(`Thumbnail generation failed: ${err.message}`);
          resolve([]);
        });
    });
  }

  private transcodeToHLS(
    sourcePath: string, outputPath: string, width: number, height: number,
    bitrateKbps: number, audioBitrateKbps: number, fps: number,
  ): Promise<void> {
    const gop = fps * 2;
    return new Promise((resolve, reject) => {
      ffmpeg(sourcePath)
        .outputOptions([
          `-vf scale=${width}:${height}`,
          `-b:v ${bitrateKbps}k`,
          '-maxrate ' + Math.round(bitrateKbps * 1.07) + 'k',
          '-bufsize ' + Math.round(bitrateKbps * 1.5) + 'k',
          '-c:v libx264', '-preset faster', '-crf 23',
          `-g ${gop}`, `-keyint_min ${gop}`, '-sc_threshold 0',
          '-c:a aac', `-b:a ${audioBitrateKbps}k`,
          '-hls_time 6', '-hls_playlist_type vod',
          `-hls_segment_filename ${path.dirname(outputPath)}/${height}p_%06d.ts`,
        ])
        .output(outputPath)
        .on('end', () => resolve())
        .on('error', (err) => {
          this.logger.warn(`HLS Transcoding for ${height}p failed: ${err.message}`);
          reject(err);
        })
        .run();
    });
  }

  private async buildMasterPlaylist(
    masterPath: string,
    targets: { height: number; width: number; bitrate: number; audioBitrate: number }[],
    fps: number,
  ): Promise<void> {
    let content = '#EXTM3U\n#EXT-X-VERSION:6\n';
    for (const t of targets) {
      const bandwidth = (t.bitrate + t.audioBitrate) * 1000;
      content += `#EXT-X-STREAM-INF:BANDWIDTH=${bandwidth},AVERAGE-BANDWIDTH=${bandwidth},RESOLUTION=${t.width}x${t.height},FRAME-RATE=${fps.toFixed(3)},CODECS="avc1.4d401f,mp4a.40.2"\n${t.height}p.m3u8\n`;
    }
    await fs.writeFile(masterPath, content);
  }
}
