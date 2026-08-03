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
    const { liveStreamId, recordingId, recordingPath } = job.data;

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
      // Here we would run FFmpeg to transcode the recording to HLS (ABR)
      // For this implementation plan, we simulate processing time
      await new Promise((resolve) => setTimeout(resolve, 5000));

      const mockHlsUrl = `/recordings/${liveStreamId}/master.m3u8`;

      // 2. Mark as READY
      await this.prisma.streamRecording.update({
        where: { id: recordingId },
        data: {
          status: StreamRecordingStatus.READY,
          hlsUrl: mockHlsUrl,
          duration: 3600, // Mock 1 hour
          completedAt: new Date(),
        },
      });

      this.logger.log(`Finished processing recording ${recordingId}`);
    } catch (error) {
      this.logger.error(`Failed to process recording ${recordingId}`, error);

      // 3. Mark as FAILED on error
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
