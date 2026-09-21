import { Module } from '@nestjs/common';
import { TrendingController } from './trending.controller.js';
import { TrendingService } from './trending.service.js';
import { PrismaModule } from '../../prisma/prisma.module.js';

import { BullModule } from '@nestjs/bullmq';
import {
  TrendingComputeProcessor,
  TRENDING_COMPUTE_QUEUE,
} from './trending.processor.js';

@Module({
  imports: [
    PrismaModule,
    BullModule.registerQueue({
      name: TRENDING_COMPUTE_QUEUE,
    }),
  ],
  controllers: [TrendingController],
  providers: [TrendingService, TrendingComputeProcessor],
  exports: [TrendingService],
})
export class TrendingModule {}
