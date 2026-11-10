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
    const cacheKey = `search:v2:user:${userId || 'anon'}:q:${JSON.stringify(query)}`;
    try {
      const cached = await this.cacheManager.get(cacheKey);
      if (cached) return cached;
    } catch (_) {}

    const result = await this.searchService.search(userId, query);

    try {
      await this.cacheManager.set(cacheKey, result, 30000); // 30s TTL
    } catch (_) {}

    return result;
  }

  /**
   * GET /api/search/unified?q=abc&limit=20
   *
   * Flat list view backed directly by SearchService.search() for backward
   * compatibility with callers expecting { items, total }.
   */
  @Get('unified')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Flat unified content search backed by Global Search' })
  async unifiedSearch(
    @CurrentUser('sub') userId: string | undefined,
    @Query(new ValidationPipe({ transform: true })) query: SearchQueryDto,
  ) {
    const q = query.q?.trim() ?? '';
    const totalLimit = Math.min(query.limit ?? 20, 50);

    const { results } = await this.searchService.search(userId, {
      q,
      page: query.page ?? 1,
      limit: Math.max(10, totalLimit),
      type: query.type,
    });

    const flat: any[] = [
      ...(results.videos ?? []).map((v: any) => ({ entityType: 'video', ...v })),
      ...(results.books ?? []).map((b: any) => ({ entityType: 'book', ...b })),
      ...(results.channels ?? []).map((c: any) => ({ entityType: 'channel', ...c })),
      ...(results.groups ?? []).map((g: any) => ({ entityType: 'group', ...g })),
      ...(results.users ?? []).map((u: any) => ({ entityType: 'user', ...u })),
      ...(results.posts ?? []).map((p: any) => ({ entityType: 'post', ...p })),
      ...(results.streams ?? []).map((s: any) => ({ entityType: 'stream', ...s })),
      ...(results.reels ?? []).map((r: any) => ({ entityType: 'reel', ...r })),
    ];

    return { items: flat.slice(0, totalLimit), total: flat.length };
  }
}
