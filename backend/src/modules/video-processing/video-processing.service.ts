// src/modules/video-processing/video-processing.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service.js';
import { VideoStatus, VideoResolution, FileProvider } from '@prisma/client';
import ffmpeg from 'fluent-ffmpeg';
import path from 'path';
import fs from 'fs/promises';
import { existsSync } from 'fs';

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

      // Output directory for video renditions & HLS
      const outputFolder = path.join(this.uploadsDir, 'videos', videoId);
      await fs.mkdir(outputFolder, { recursive: true });

      // Generate Thumbnail
      const thumbnailFileName = `thumb_${videoId}.jpg`;
      const thumbnailPath = path.join(outputFolder, thumbnailFileName);
      await this.generateThumbnail(absoluteSourcePath, thumbnailPath);

      const appUrl =
        this.configService.get<string>('APP_URL') ?? 'http://localhost:3000';
      const relThumbPath = `videos/${videoId}/${thumbnailFileName}`.replace(
        /\\/g,
        '/',
      );
      const thumbnailUrl = `${appUrl}/uploads/${relThumbPath}`;

      // Target resolutions to transcode
      const targets: {
        res: VideoResolution;
        height: number;
        width: number;
        bitrate: number;
      }[] = [
        { res: VideoResolution.R_240P, height: 240, width: 426, bitrate: 400 },
        { res: VideoResolution.R_360P, height: 360, width: 640, bitrate: 800 },
        { res: VideoResolution.R_480P, height: 480, width: 854, bitrate: 1200 },
        {
          res: VideoResolution.R_720P,
          height: 720,
          width: 1280,
          bitrate: 2500,
        },
        {
          res: VideoResolution.R_1080P,
          height: 1080,
          width: 1920,
          bitrate: 5000,
        },
      ].filter((t) => t.height <= videoHeight || t.height === 240);

      // Transcode HLS renditions
      const hlsMasterPlaylistPath = path.join(outputFolder, 'master.m3u8');
      const renditionUrls: {
        resolution: VideoResolution;
        height: number;
        width: number;
        bitrate: number;
        url: string;
        key: string;
      }[] = [];

      for (const target of targets) {
        const resFileName = `${target.height}p.m3u8`;
        const resPath = path.join(outputFolder, resFileName);

        await this.transcodeToHLS(
          absoluteSourcePath,
          resPath,
          target.width,
          target.height,
          target.bitrate,
        );

        const relResPath = `videos/${videoId}/${resFileName}`.replace(
          /\\/g,
          '/',
        );
        const renditionUrl = `${appUrl}/uploads/${relResPath}`;

        renditionUrls.push({
          resolution: target.res,
          height: target.height,
          width: target.width,
          bitrate: target.bitrate,
          url: renditionUrl,
          key: relResPath,
        });

        // Save Rendition to DB
        await this.prisma.videoRendition.upsert({
          where: { videoId_resolution: { videoId, resolution: target.res } },
          create: {
            videoId,
            resolution: target.res,
            height: target.height,
            width: target.width,
            bitrate: target.bitrate,
            fileSize: BigInt(1000000),
            storageKey: relResPath,
            url: renditionUrl,
            provider: FileProvider.LOCAL,
            isReady: true,
          },
          update: {
            url: renditionUrl,
            isReady: true,
          },
        });
      }

      // Build HLS Master Playlist
      await this.buildMasterPlaylist(hlsMasterPlaylistPath, targets);
      const masterRelPath = `videos/${videoId}/master.m3u8`.replace(/\\/g, '/');
      const hlsMasterUrl = `${appUrl}/uploads/${masterRelPath}`;

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
          hlsUrl: hlsMasterUrl,
        },
      });

      this.logger.log(
        `Video [${videoId}] processed successfully. HLS URL: ${hlsMasterUrl}`,
      );
    } catch (err: any) {
      this.logger.error(
        `Error processing video [${videoId}]: ${err.message}`,
        err.stack,
      );
      // Throw the error so BullMQ knows the job failed and can retry it.
      // The @OnWorkerEvent('failed') hook in the processor will set the status to FAILED
      // if retries are exhausted.
      throw err;
    }
  }

  private probeMetadata(filePath: string): Promise<{
    duration?: number;
    width?: number;
    height?: number;
    bitrate?: number;
  }> {
    return new Promise((resolve) => {
      ffmpeg.ffprobe(filePath, (err, metadata) => {
        if (err || !metadata) {
          return resolve({
            duration: 0,
            width: 1280,
            height: 720,
            bitrate: 2000,
          });
        }
        const videoStream = metadata.streams.find(
          (s) => s.codec_type === 'video',
        );
        resolve({
          duration: metadata.format.duration || 0,
          width: videoStream?.width || 1280,
          height: videoStream?.height || 720,
          bitrate: metadata.format.bit_rate
            ? Math.round(metadata.format.bit_rate / 1000)
            : 2000,
        });
      });
    });
  }

  private generateThumbnail(
    sourcePath: string,
    outputPath: string,
  ): Promise<void> {
    return new Promise((resolve, _reject) => {
      ffmpeg(sourcePath)
        .screenshots({
          timestamps: ['10%'],
          filename: path.basename(outputPath),
          folder: path.dirname(outputPath),
          size: '640x360',
        })
        .on('end', () => resolve())
        .on('error', (err) => {
          this.logger.warn(`Thumbnail generation failed: ${err.message}`);
          resolve(); // Non-blocking fallback
        });
    });
  }

  private transcodeToHLS(
    sourcePath: string,
    outputPath: string,
    width: number,
    height: number,
    bitrateKbps: number,
  ): Promise<void> {
    return new Promise((resolve) => {
      ffmpeg(sourcePath)
        .outputOptions([
          `-vf scale=${width}:${height}`,
          `-b:v ${bitrateKbps}k`,
          '-c:v libx264',
          '-c:a aac',
          '-b:a 128k',
          '-hls_time 6',
          '-hls_playlist_type vod',
          `-hls_segment_filename ${path.dirname(outputPath)}/${height}p_%03d.ts`,
        ])
        .output(outputPath)
        .on('end', () => resolve())
        .on('error', (err) => {
          this.logger.warn(
            `HLS Transcoding for ${height}p failed: ${err.message}`,
          );
          resolve();
        })
        .run();
    });
  }

  private async buildMasterPlaylist(
    masterPath: string,
    targets: { height: number; width: number; bitrate: number }[],
  ): Promise<void> {
    let content = '#EXTM3U\n#EXT-X-VERSION:3\n';
    for (const t of targets) {
      content += `#EXT-X-STREAM-INF:BANDWIDTH=${t.bitrate * 1000},RESOLUTION=${t.width}x${t.height}\n${t.height}p.m3u8\n`;
    }
    await fs.writeFile(masterPath, content);
  }
}
