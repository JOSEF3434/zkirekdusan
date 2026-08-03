import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { STREAM_PROCESSING_QUEUE } from './stream-processing.processor.js';

export interface ProcessRecordingJobData {
  liveStreamId: string;
  recordingId: string;
  recordingPath: string;
}

@Injectable()
export class StreamProcessingService {
  private readonly logger = new Logger(StreamProcessingService.name);

  constructor(
    @InjectQueue(STREAM_PROCESSING_QUEUE) private readonly queue: Queue,
  ) {}

  async enqueueRecording(data: ProcessRecordingJobData) {
    this.logger.log(
      `Enqueueing recording ${data.recordingId} for stream ${data.liveStreamId}`,
    );

    await this.queue.add('process-recording', data, {
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 5000, // 5s, 25s, 125s
      },
      removeOnComplete: true,
    });
  }
}
