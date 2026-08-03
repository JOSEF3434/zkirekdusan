import { Injectable } from '@nestjs/common';
import { TrendingService } from '../trending/trending.service.js';

@Injectable()
export class ExploreService {
  constructor(private readonly trendingService: TrendingService) {}

  async getExploreContent() {
    const [trendingPosts, trendingVideos] = await Promise.all([
      this.trendingService.getTrending('POSTS', 1, 5),
      this.trendingService.getTrending('VIDEOS', 1, 5),
    ]);

    return {
      trendingPosts: trendingPosts.data,
      trendingVideos: trendingVideos.data,
      // In a real app we'd fetch categories, hashtags, live streams, etc.
    };
  }
}
