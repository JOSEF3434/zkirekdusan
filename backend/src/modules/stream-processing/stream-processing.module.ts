import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { StreamProcessingService } from './stream-processing.service.js';
import {
  StreamProcessingProcessor,
  STREAM_PROCESSING_QUEUE,
} from './stream-processing.processor.js';
import { PrismaModule } from '../../prisma/prisma.module.js';

@Module({
  imports: [
    PrismaModule,
    BullModule.registerQueue({
      name: STREAM_PROCESSING_QUEUE,
    }),
  ],
  providers: [StreamProcessingService, StreamProcessingProcessor],
  exports: [StreamProcessingService],
})
export class StreamProcessingModule {}
