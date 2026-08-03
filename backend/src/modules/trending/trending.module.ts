import { Module } from '@nestjs/common';
import { TrendingController } from './trending.controller.js';
import { TrendingService } from './trending.service.js';
import { PrismaModule } from '../../prisma/prisma.module.js';

@Module({
  imports: [PrismaModule],
  controllers: [TrendingController],
  providers: [TrendingService],
  exports: [TrendingService],
})
export class TrendingModule {}
