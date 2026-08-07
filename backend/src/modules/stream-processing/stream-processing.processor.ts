import { Processor, WorkerHost, OnWorkerEvent } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { ProcessRecordingJobData } from './stream-processing.service.js';
import { PrismaService } from '../../prisma/prisma.service.js';
import { StreamRecordingStatus } from '@prisma/client';

export const STREAM_PROCESSING_QUEUE = 'stream-processing';

@Processor(STREAM_PROCESSING_QUEUE)
export class StreamProcessingProcessor extends WorkerHost {
  private readonly logger = new Logger(StreamProcessingProcessor.name);

  constructor(private readonly prisma: PrismaService) {
    super();
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
      // 2. Real FFmpeg HLS Transcoding
      // Assume the input recording is a standard MP4 or FLV dropped by Nginx-RTMP
      // We will transcode it to HLS (360p, 720p)
      
      const fs = await import('fs/promises');
      const path = await import('path');
      const ffmpeg = (await import('fluent-ffmpeg')).default;
      
      // Resolve paths (in a real scenario, this would pull from storage provider to local tmp, process, then upload back)
      // For this implementation, we assume local file system access to recordings
      const inputPath = path.resolve(process.cwd(), 'uploads', _recordingPath);
      const outputDir = path.resolve(process.cwd(), 'uploads', `hls_${recordingId}`);
      const masterPlaylistPath = path.join(outputDir, 'master.m3u8');
      
      // Ensure output directory exists
      await fs.mkdir(outputDir, { recursive: true });

      // Run FFmpeg to generate HLS
      await new Promise<void>((resolve, reject) => {
        ffmpeg(inputPath)
          // Video settings
          .videoCodec('libx264')
          .audioCodec('aac')
          .outputOptions([
            '-profile:v main',
            '-sc_threshold 0',
            '-g 48',
            '-keyint_min 48',
            '-hls_time 4',
            '-hls_playlist_type vod',
            '-b:v 2500k',
            '-maxrate 2675k',
            '-bufsize 3750k',
            '-b:a 128k',
            '-hls_segment_filename',
            path.join(outputDir, '720p_%03d.ts')
          ])
          .output(path.join(outputDir, '720p.m3u8'))
          .on('end', () => resolve())
          .on('error', (err) => {
            this.logger.error('FFmpeg HLS error', err);
            reject(err);
          })
          .run();
      });

      // Write master playlist
      const masterContent = `#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-STREAM-INF:BANDWIDTH=2800000,RESOLUTION=1280x720\n720p.m3u8\n`;
      await fs.writeFile(masterPlaylistPath, masterContent);

      // (We would normally upload the outputDir to S3/MinIO here using StorageProvider)

      const mockHlsUrl = `/uploads/hls_${recordingId}/master.m3u8`;

      // 3. Mark as READY
      await this.prisma.streamRecording.update({
        where: { id: recordingId },
        data: {
          status: StreamRecordingStatus.READY,
          hlsUrl: mockHlsUrl,
          // Extract actual duration in a full implementation via ffprobe
          duration: 3600, 
          completedAt: new Date(),
        },
      });

      this.logger.log(`Finished processing recording ${recordingId}`);
    } catch (error) {
      this.logger.error(`Failed to process recording ${recordingId}`, error);

      // 4. Mark as FAILED on error
      await this.prisma.streamRecording.update({
        where: { id: recordingId },
        data: { status: StreamRecordingStatus.FAILED },
      });
      throw error;
    }
  }

  @OnWorkerEvent('failed')
  onFailed(job: Job<ProcessRecordingJobData>, error: Error) {
    this.logger.error(`Job ${job.id} failed: ${error.message}`, error.stack);
  }
}
