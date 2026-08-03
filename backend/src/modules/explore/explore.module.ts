import { Module } from '@nestjs/common';
import { ExploreController } from './explore.controller.js';
import { ExploreService } from './explore.service.js';
import { TrendingModule } from '../trending/trending.module.js';
import { RecommendationsModule } from '../recommendations/recommendations.module.js';
import { SearchModule } from '../search/search.module.js';

@Module({
  imports: [TrendingModule, RecommendationsModule, SearchModule],
  controllers: [ExploreController],
  providers: [ExploreService],
})
export class ExploreModule {}
