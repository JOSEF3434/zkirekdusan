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
    private readonly storageProvider: IStorageProvider,
  ) {
    this.uploadsDir = path.resolve(process.cwd(), 'uploads');
  }

  /**
   * Main transcode process for a video
   */
  async processVideo(data: TranscodeJobData): Promise<void> {
    const { videoId, sourceFilePath } = data;
    this.logger.log(`Starting processing for Video [${videoId}]...`);

    const video = await this.prisma.video.findUnique({
      where: { id: videoId },
      include: { sourceFile: true },
    });

    if (!video) {
      this.logger.error(`Video [${videoId}] not found in database.`);
      return;
    }

    await this.prisma.video.update({
      where: { id: videoId },
      data: { status: VideoStatus.PROCESSING },
    });

    try {
      // Full absolute file path on disk
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

      // Probe metadata (duration, width, height, bitrate)
      const meta = await this.probeMetadata(absoluteSourcePath);
      const videoWidth = meta.width || 1920;
      const videoHeight = meta.height || 1080;
      const duration = meta.duration || 0;
      const fps = meta.fps || 30;

      // Output directory for video renditions & HLS
      const outputFolder = path.join(this.uploadsDir, 'videos', videoId);
      await fs.mkdir(outputFolder, { recursive: true });

      // Generate Thumbnail Sprite (10 frames)
      const thumbnails = await this.generateThumbnailSprite(absoluteSourcePath, outputFolder, videoId);
      
      // Upload thumbnails if not using local storage
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
          // Optionally clean up local file
          await fs.unlink(thumb).catch(() => {});
        } else {
          const appUrl = this.configService.get<string>('APP_URL') ?? 'http://localhost:3000';
          const relThumbPath = `videos/${videoId}/${path.basename(thumb)}`.replace(/\\/g, '/');
          thumbUrl = `${appUrl}/uploads/${relThumbPath}`;
        }
        thumbnailUrlPaths.push(thumbUrl);
      }
      
      // We will use the first thumbnail as the main thumbnail
      const thumbnailUrl = thumbnailUrlPaths[0] || '';

      // Target resolutions to transcode
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

      // Transcode HLS renditions
      const hlsMasterPlaylistPath = path.join(outputFolder, 'master.m3u8');
      
      for (const target of targets) {
        const resFileName = `${target.height}p.m3u8`;
        const resPath = path.join(outputFolder, resFileName);

        await this.transcodeToHLS(
          absoluteSourcePath,
          resPath,
          target.width,
          target.height,
          target.bitrate,
          target.audioBitrate,
          fps
        );
      }

      // Build HLS Master Playlist
      await this.buildMasterPlaylist(hlsMasterPlaylistPath, targets, fps);

      // Upload all HLS files if using remote storage
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
              buffer,
              originalname: file,
              mimetype: mimeType,
              size: buffer.length,
            }, `videos/${videoId}`);
            
            if (file === 'master.m3u8') {
              masterUrl = res.url;
            }
            // Clean up local files after upload to save space
            await fs.unlink(filePath).catch(() => {});
          }
        }
      } else {
        const appUrl = this.configService.get<string>('APP_URL') ?? 'http://localhost:3000';
        const masterRelPath = `videos/${videoId}/master.m3u8`.replace(/\\/g, '/');
        masterUrl = `${appUrl}/uploads/${masterRelPath}`;
      }

      // Save Rendition to DB (Update URLs)
      for (const target of targets) {
        const resFileName = `${target.height}p.m3u8`;
        let renditionUrl = '';
        if (isRemoteStorage) {
          // Construct URL based on masterUrl path
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
            videoId,
            resolution: target.res,
            height: target.height,
            width: target.width,
            bitrate: target.bitrate,
            fileSize: BigInt(0), // Would need to calculate total size of .ts files
            storageKey: `videos/${videoId}/${resFileName}`,
            url: renditionUrl,
            provider: isRemoteStorage ? FileProvider.S3 : FileProvider.LOCAL,
            isReady: true,
          },
          update: {
            url: renditionUrl,
            isReady: true,
          },
        });
      }

      // Update Video to READY
      await this.prisma.video.update({
        where: { id: videoId },
        data: {
          status: VideoStatus.READY,
          duration,
          width: videoWidth,
          height: videoHeight,
          bitrate: meta.bitrate || 2000,
          thumbnailUrl,
          hlsUrl: masterUrl,
        },
      });

      this.logger.log(
        `Video [${videoId}] processed successfully. HLS URL: ${masterUrl}`,
      );
    } catch (err: any) {
      this.logger.error(
        `Error processing video [${videoId}]: ${err.message}`,
        err.stack,
      );
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
          return resolve({
            duration: 0,
            width: 1280,
            height: 720,
            bitrate: 2000,
            fps: 30
          });
        }
        const videoStream = metadata.streams.find(
          (s) => s.codec_type === 'video',
        );
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
          bitrate: metadata.format.bit_rate
            ? Math.round(metadata.format.bit_rate / 1000)
            : 2000,
          fps: isNaN(fps) ? 30 : fps,
        });
      });
    });
  }

  private generateThumbnailSprite(
    sourcePath: string,
    outputFolder: string,
    videoId: string
  ): Promise<string[]> {
    return new Promise((resolve, _reject) => {
      const timestamps = ['10%', '20%', '30%', '40%', '50%', '60%', '70%', '80%', '90%'];
      
      ffmpeg(sourcePath)
        .screenshots({
          timestamps: timestamps,
          filename: `thumb_${videoId}_%i.jpg`,
          folder: outputFolder,
          size: '640x360',
        })
        .on('end', async () => {
          // Resolve with the list of generated files
          const files: string[] = [];
          for (let i = 1; i <= timestamps.length; i++) {
            const file = path.join(outputFolder, `thumb_${videoId}_${i}.jpg`);
            if (existsSync(file)) {
              files.push(file);
            }
          }
          resolve(files);
        })
        .on('error', (err) => {
          this.logger.warn(`Thumbnail generation failed: ${err.message}`);
          resolve([]); // Non-blocking fallback
        });
    });
  }

  private transcodeToHLS(
    sourcePath: string,
    outputPath: string,
    width: number,
    height: number,
    bitrateKbps: number,
    audioBitrateKbps: number,
    fps: number
  ): Promise<void> {
    const gop = fps * 2; // 2 seconds GOP size
    return new Promise((resolve, reject) => {
      ffmpeg(sourcePath)
        .outputOptions([
          `-vf scale=${width}:${height}`,
          `-b:v ${bitrateKbps}k`,
          '-maxrate ' + Math.round(bitrateKbps * 1.07) + 'k', // 7% overhead
          '-bufsize ' + Math.round(bitrateKbps * 1.5) + 'k',
          '-c:v libx264',
          '-preset faster',
          '-crf 23',
          `-g ${gop}`,
          `-keyint_min ${gop}`,
          '-sc_threshold 0',
          '-c:a aac',
          `-b:a ${audioBitrateKbps}k`,
          '-hls_time 6',
          '-hls_playlist_type vod',
          `-hls_segment_filename ${path.dirname(outputPath)}/${height}p_%06d.ts`,
        ])
        .output(outputPath)
        .on('end', () => resolve())
        .on('error', (err) => {
          this.logger.warn(
            `HLS Transcoding for ${height}p failed: ${err.message}`,
          );
          reject(err);
        })
        .run();
    });
  }

  private async buildMasterPlaylist(
    masterPath: string,
    targets: { height: number; width: number; bitrate: number; audioBitrate: number }[],
    fps: number
  ): Promise<void> {
    let content = '#EXTM3U\n#EXT-X-VERSION:6\n';
    for (const t of targets) {
      const bandwidth = (t.bitrate + t.audioBitrate) * 1000;
      // Provide robust CODECS tag for Flutter video_player and HLS.js
      content += `#EXT-X-STREAM-INF:BANDWIDTH=${bandwidth},AVERAGE-BANDWIDTH=${bandwidth},RESOLUTION=${t.width}x${t.height},FRAME-RATE=${fps.toFixed(3)},CODECS="avc1.4d401f,mp4a.40.2"\n${t.height}p.m3u8\n`;
    }
    await fs.writeFile(masterPath, content);
  }
}
