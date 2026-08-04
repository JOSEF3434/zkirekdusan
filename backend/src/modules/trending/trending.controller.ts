import {
  Controller,
  Get,
  Query,
  ParseIntPipe,
  DefaultValuePipe,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { CacheInterceptor, CacheTTL } from '@nestjs/cache-manager';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { TrendingService } from './trending.service.js';
import { OptionalJwtAuthGuard } from '../../common/guards/optional-jwt-auth.guard.js';

@ApiTags('Trending')
@Controller('trending')
@UseInterceptors(CacheInterceptor)
export class TrendingController {
  constructor(private readonly trendingService: TrendingService) {}

  @Get('posts')
  @UseGuards(OptionalJwtAuthGuard)
  @CacheTTL(60000) // Cache for 60 seconds
  @ApiOperation({ summary: 'Get trending posts' })
  async getTrendingPosts(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.trendingService.getTrending('POSTS', page, limit);
  }

  @Get('videos')
  @UseGuards(OptionalJwtAuthGuard)
  @CacheTTL(60000) // Cache for 60 seconds
  @ApiOperation({ summary: 'Get trending videos' })
  async getTrendingVideos(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.trendingService.getTrending('VIDEOS', page, limit);
  }
}
