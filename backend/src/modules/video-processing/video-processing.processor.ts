// src/modules/video-processing/video-processing.processor.ts
import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { VideoProcessingService, TranscodeJobData } from './video-processing.service.js';

export const VIDEO_PROCESSING_QUEUE = 'video-processing';

@Processor(VIDEO_PROCESSING_QUEUE)
export class VideoProcessingProcessor extends WorkerHost {
  private readonly logger = new Logger(VideoProcessingProcessor.name);

  constructor(private readonly videoProcessingService: VideoProcessingService) {
    super();
  }

  async process(job: Job<TranscodeJobData>): Promise<any> {
    this.logger.log(`Processing video job [${job.id}] for Video [${job.data.videoId}]`);
    await this.videoProcessingService.processVideo(job.data);
    return { status: 'completed', videoId: job.data.videoId };
  }
}
