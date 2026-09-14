import {
  Controller,
  Get,
  Query,
  UseGuards,
  ValidationPipe,
  Inject,
} from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from '@nestjs/swagger';
import { SearchService } from './search.service.js';
import { SearchQueryDto } from './dto/search-query.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { OptionalJwtAuthGuard } from '../../common/guards/optional-jwt-auth.guard.js';

@ApiTags('Search')
@Controller('search')
export class SearchController {
  constructor(
    private readonly searchService: SearchService,
    @Inject(CACHE_MANAGER) private readonly cacheManager: Cache,
  ) {}

  @Get()
  @UseGuards(OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Global search across all public entities' })
  @ApiResponse({ status: 200, description: 'Search results' })
  async search(
    @CurrentUser('sub') userId: string | undefined,
    @Query(new ValidationPipe({ transform: true })) query: SearchQueryDto,
  ) {
    const cacheKey = `search:user:${userId || 'anon'}:q:${JSON.stringify(query)}`;
    try {
      const cached = await this.cacheManager.get(cacheKey);
      if (cached) return cached;
    } catch (_) {}

    const result = await this.searchService.search(userId, query);

    try {
      await this.cacheManager.set(cacheKey, result, 60000); // 60s TTL
    } catch (_) {}

    return result;
  }
}
