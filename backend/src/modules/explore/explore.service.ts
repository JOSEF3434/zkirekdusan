import { Injectable } from '@nestjs/common';
import { TrendingService } from '../trending/trending.service.js';

@Injectable()
export class ExploreService {
  constructor(private readonly trendingService: TrendingService) {}

  async getExploreContent() {
    const [
      trendingPosts,
      trendingVideos,
      trendingReels,
      trendingStreams,
      trendingChannels,
    ] = await Promise.all([
      this.trendingService.getTrending('POSTS', 1, 5),
      this.trendingService.getTrending('VIDEOS', 1, 5),
      this.trendingService.getTrending('REELS', 1, 5),
      this.trendingService.getTrending('STREAMS', 1, 5),
      this.trendingService.getTrending('CHANNELS', 1, 5),
    ]);

    return {
      trendingPosts: trendingPosts.data,
      trendingVideos: trendingVideos.data,
      trendingReels: trendingReels.data,
      trendingStreams: trendingStreams.data,
      trendingChannels: trendingChannels.data,
    };
  }
}
