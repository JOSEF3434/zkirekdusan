// src/modules/video-processing/video-processing.processor.ts
import { Processor, WorkerHost, OnWorkerEvent } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import {
  VideoProcessingService,
  TranscodeJobData,
} from './video-processing.service.js';
import { PrismaService } from '../../prisma/prisma.service.js';
import { VideoStatus } from '@prisma/client';

export const VIDEO_PROCESSING_QUEUE = 'video-processing';

@Processor(VIDEO_PROCESSING_QUEUE)
export class VideoProcessingProcessor extends WorkerHost {
  private readonly logger = new Logger(VideoProcessingProcessor.name);

  constructor(
    private readonly videoProcessingService: VideoProcessingService,
    private readonly prisma: PrismaService,
  ) {
    super();
  }

  async process(job: Job<TranscodeJobData>): Promise<any> {
    this.logger.log(
      `Processing video job [${job.id}] for Video [${job.data.videoId}]`,
    );
    await this.videoProcessingService.processVideo(job.data);
    return { status: 'completed', videoId: job.data.videoId };
  }

  @OnWorkerEvent('failed')
  async onFailed(job: Job<TranscodeJobData>, error: Error) {
    this.logger.error(
      `Job [${job.id}] permanently failed for Video [${job.data.videoId}]: ${error.message}`,
      error.stack,
    );
    // Only set FAILED when retries are exhausted (attemptsMade === opts.attempts)
    if (job.attemptsMade >= (job.opts.attempts ?? 1)) {
      try {
        await this.prisma.video.update({
          where: { id: job.data.videoId },
          data: { status: VideoStatus.FAILED },
        });
        this.logger.warn(
          `Video [${job.data.videoId}] marked as FAILED after ${job.attemptsMade} attempts`,
        );
      } catch (dbErr) {
        this.logger.error(
          `Failed to update video status to FAILED: ${String(dbErr)}`,
        );
      }
    }
  }
}
