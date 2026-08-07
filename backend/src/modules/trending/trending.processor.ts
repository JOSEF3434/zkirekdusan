import { Processor, WorkerHost, OnWorkerEvent } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { PrismaService } from '../../prisma/prisma.service.js';

export const TRENDING_COMPUTE_QUEUE = 'trending-compute';

@Processor(TRENDING_COMPUTE_QUEUE)
export class TrendingComputeProcessor extends WorkerHost {
  private readonly logger = new Logger(TrendingComputeProcessor.name);

  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async process(job: Job): Promise<void> {
    this.logger.log(`Computing trending scores (Job: ${job.id})`);

    // In a real system, we'd query recommendation_events within the time window
    // and aggregate views/likes to update trending_scores.
    // For this milestone, we'll simulate calculating trending scores by
    // fetching top videos and creating/updating their trending_scores.

    const topVideos = await this.prisma.video.findMany({
      where: { status: 'READY', visibility: 'PUBLIC' },
      orderBy: { viewsCount: 'desc' },
      take: 50,
    });

    // We'll clear the old scores for VIDEOS and insert new ones
    await this.prisma.trendingScore.deleteMany({
      where: { entityType: 'VIDEOS', window: 'DAILY' },
    });

    if (topVideos.length > 0) {
      const newScores = topVideos.map((v, index) => {
        // Base score on views, decaying slightly by index
        const score = Number(v.viewsCount) + (50 - index) * 10;
        return {
          entityType: 'VIDEOS',
          entityId: v.id,
          window: 'DAILY',
          score,
          categoryId: null, // Global
          rank: index + 1,
        };
      });

      await this.prisma.trendingScore.createMany({
        data: newScores,
      });
    }

    this.logger.log(`Trending scores computed for ${topVideos.length} videos`);
  }

  @OnWorkerEvent('failed')
  onFailed(job: Job, error: Error) {
    this.logger.error(`Job ${job.id} failed: ${error.message}`, error.stack);
  }
}
