import { Processor, WorkerHost, OnWorkerEvent } from '@nestjs/bullmq';
import { Logger, Inject } from '@nestjs/common';
import { Job } from 'bullmq';
import { ProcessRecordingJobData } from './stream-processing.service.js';
import { PrismaService } from '../../prisma/prisma.service.js';
import {
  StreamRecordingStatus,
  VideoResolution,
  FileProvider,
} from '@prisma/client';
import { ConfigService } from '@nestjs/config';
import type { IStorageProvider } from '../uploads/providers/storage.interface.js';
import { STORAGE_PROVIDER_TOKEN } from '../uploads/providers/storage.factory.js';
import path from 'path';
import fs from 'fs/promises';
import { existsSync } from 'fs';
import ffmpeg from 'fluent-ffmpeg';
import { nanoid } from 'nanoid';

export const STREAM_PROCESSING_QUEUE = 'stream-processing';

@Processor(STREAM_PROCESSING_QUEUE)
export class StreamProcessingProcessor extends WorkerHost {
  private readonly logger = new Logger(StreamProcessingProcessor.name);
  private readonly uploadsDir: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    @Inject(STORAGE_PROVIDER_TOKEN)
    private readonly storageProvider: IStorageProvider,
  ) {
    super();
    this.uploadsDir = path.resolve(process.cwd(), 'uploads');
  }

  async process(job: Job<ProcessRecordingJobData>): Promise<void> {
    const {
      liveStreamId,
      recordingId,
      recordingPath: _recordingPath,
    } = job.data;

    this.logger.log(
      `Processing recording for stream ${liveStreamId} (Job: ${job.id})`,
    );

    // 1. Update status to PROCESSING
    await this.prisma.streamRecording.update({
      where: { id: recordingId },
      data: {
        status: StreamRecordingStatus.PROCESSING,
        processingJobId: job.id,
      },
    });

    try {
      // 2. Real FFmpeg HLS Transcoding for ABR ladder
      const absoluteSourcePath = path.isAbsolute(_recordingPath)
        ? _recordingPath
        : path.join(this.uploadsDir, _recordingPath);

      if (!existsSync(absoluteSourcePath)) {
        throw new Error(`Recording file not found at ${absoluteSourcePath}`);
      }

      // Output directory
      const outputFolder = path.join(this.uploadsDir, `hls_${recordingId}`);
      await fs.mkdir(outputFolder, { recursive: true });

      // Probe meta for duration, resolution and fps
      const meta = await this.probeMetadata(absoluteSourcePath);
      const videoWidth = meta.width || 1280;
      const videoHeight = meta.height || 720;
      const duration = meta.duration || 0;
      const fps = meta.fps || 30;

      // Target resolutions
      const targets: {
        res: VideoResolution;
        height: number;
        width: number;
        bitrate: number;
        audioBitrate: number;
      }[] = [
        {
          res: VideoResolution.R_240P,
          height: 240,
          width: 426,
          bitrate: 400,
          audioBitrate: 64,
        },
        {
          res: VideoResolution.R_360P,
          height: 360,
          width: 640,
          bitrate: 800,
          audioBitrate: 96,
        },
        {
          res: VideoResolution.R_480P,
          height: 480,
          width: 854,
          bitrate: 1200,
          audioBitrate: 128,
        },
        {
          res: VideoResolution.R_720P,
          height: 720,
          width: 1280,
          bitrate: 2500,
          audioBitrate: 128,
        },
        {
          res: VideoResolution.R_1080P,
          height: 1080,
          width: 1920,
          bitrate: 5000,
          audioBitrate: 192,
        },
        {
          res: VideoResolution.R_4K,
          height: 2160,
          width: 3840,
          bitrate: 15000,
          audioBitrate: 192,
        },
      ].filter((t) => t.height <= videoHeight || t.height === 240);

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
          fps,
        );
      }

      // Build Master Playlist
      await this.buildMasterPlaylist(hlsMasterPlaylistPath, targets, fps);

      // Upload to storage provider
      let masterUrl = '';
      const isRemoteStorage = this.storageProvider.providerType !== 'LOCAL';

      if (isRemoteStorage) {
        this.logger.log(`Uploading Live VOD HLS files to remote storage...`);
        const files: string[] = await fs.readdir(outputFolder);
        for (const file of files) {
          if (file.endsWith('.m3u8') || file.endsWith('.ts')) {
            const filePath = path.join(outputFolder, file);
            const buffer = await fs.readFile(filePath);
            const mimeType = file.endsWith('.m3u8')
              ? 'application/vnd.apple.mpegurl'
              : 'video/MP2T';

            const res = await this.storageProvider.upload(
              {
                buffer,
                originalname: file,
                mimetype: mimeType,
                size: buffer.length,
              },
              `live-recordings/${recordingId}`,
            );

            if (file === 'master.m3u8') {
              masterUrl = res.url;
            }
            await fs.unlink(filePath).catch(() => {});
          }
        }
      } else {
        const appUrl =
          this.configService.get<string>('APP_URL') ??
          this.configService.get<string>('RENDER_EXTERNAL_URL') ??
          'https://zikrekidusan.onrender.com';
        const masterRelPath = `hls_${recordingId}/master.m3u8`.replace(
          /\\/g,
          '/',
        );
        masterUrl = `${appUrl}/uploads/${masterRelPath}`;
      }

      // 3. Mark Recording as READY
      await this.prisma.streamRecording.update({
        where: { id: recordingId },
        data: {
          status: StreamRecordingStatus.READY,
          hlsUrl: masterUrl,
          duration: duration,
          completedAt: new Date(),
        },
      });

      // 4. Auto-publish VOD
      const stream = await this.prisma.liveStream.findUnique({
        where: { id: liveStreamId },
      });

      if (stream) {
        const existingVideo = await this.prisma.video.findFirst({
          where: { hlsUrl: masterUrl },
        });

        if (!existingVideo) {
          await this.prisma.video.create({
            data: {
              videoChannelId: stream.videoChannelId,
              uploadedById: stream.createdById,
              title: stream.title,
              description:
                stream.description ?? `VOD for stream ${stream.title}`,
              slug: `vod-${stream.id}-${nanoid(8)}`,
              status: 'READY',
              visibility: 'PUBLIC',
              duration: duration,
              hlsUrl: masterUrl,
            },
          });
          this.logger.log(`Auto-published VOD for stream ${liveStreamId}`);
        } else {
          this.logger.log(`VOD already exists for stream ${liveStreamId}`);
        }
      }

      this.logger.log(`Finished processing recording ${recordingId}`);
    } catch (error) {
      this.logger.error(`Failed to process recording ${recordingId}`, error);

      await this.prisma.streamRecording.update({
        where: { id: recordingId },
        data: { status: StreamRecordingStatus.FAILED },
      });
      throw error;
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
            fps: 30,
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

  private transcodeToHLS(
    sourcePath: string,
    outputPath: string,
    width: number,
    height: number,
    bitrateKbps: number,
    audioBitrateKbps: number,
    fps: number,
  ): Promise<void> {
    const gop = fps * 2;
    return new Promise((resolve, reject) => {
      ffmpeg(sourcePath)
        .outputOptions([
          `-vf scale=${width}:${height}`,
          `-b:v ${bitrateKbps}k`,
          '-maxrate ' + Math.round(bitrateKbps * 1.07) + 'k',
          '-bufsize ' + Math.round(bitrateKbps * 1.5) + 'k',
          '-c:v libx264',
          '-preset faster',
          '-crf 23',
          `-g ${gop}`,
          `-keyint_min ${gop}`,
          '-sc_threshold 0',
          '-c:a aac',
          `-b:a ${audioBitrateKbps}k`,
          // LL-HLS flags for live recordings
          '-hls_time 2',
          '-hls_list_size 0',
          '-hls_flags independent_segments+delete_segments',
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
    targets: {
      height: number;
      width: number;
      bitrate: number;
      audioBitrate: number;
    }[],
    fps: number,
  ): Promise<void> {
    let content = '#EXTM3U\n#EXT-X-VERSION:6\n';
    for (const t of targets) {
      const bandwidth = (t.bitrate + t.audioBitrate) * 1000;
      content += `#EXT-X-STREAM-INF:BANDWIDTH=${bandwidth},AVERAGE-BANDWIDTH=${bandwidth},RESOLUTION=${t.width}x${t.height},FRAME-RATE=${fps.toFixed(3)},CODECS="avc1.4d401f,mp4a.40.2"\n${t.height}p.m3u8\n`;
    }
    await fs.writeFile(masterPath, content);
  }

  @OnWorkerEvent('failed')
  onFailed(job: Job<ProcessRecordingJobData>, error: Error) {
    this.logger.error(`Job ${job.id} failed: ${error.message}`, error.stack);
  }
}
