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
import { SearchQueryDto, SearchEntityType } from './dto/search-query.dto.js';
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

  /**
   * GET /api/search/unified?q=abc&limit=20
   *
   * Flat list of mixed content for the # content picker.
   * Returns items tagged with their `entityType` so the Flutter client
   * knows where to navigate.
   *
   * Videos are always searched with an independent limit so they are
   * never squeezed out by the limit/N distribution bug.
   */
  @Get('unified')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Flat unified content search for # content picker' })
  async unifiedSearch(
    @CurrentUser('sub') userId: string | undefined,
    @Query(new ValidationPipe({ transform: true })) query: SearchQueryDto,
  ) {
    const q = query.q?.trim() ?? '';
    const totalLimit = Math.min(query.limit ?? 20, 50);

    // Give videos a generous independent limit — they are the most common
    // content reference and must NOT be starved by the per-type distribution.
    const videoLimit = Math.max(10, Math.ceil(totalLimit * 0.5));
    const otherLimit = Math.max(5, Math.ceil(totalLimit * 0.25));

    // Run all searches in parallel — fault-tolerant
    const [
      videosRes,
      usersRes,
      groupsRes,
      channelsRes,
      postsRes,
      streamsRes,
    ] = await Promise.allSettled([
      this.searchService.search(userId, { ...query, q, limit: videoLimit, type: SearchEntityType.VIDEOS }),
      this.searchService.search(userId, { ...query, q, limit: otherLimit, type: SearchEntityType.USERS }),
      this.searchService.search(userId, { ...query, q, limit: otherLimit, type: SearchEntityType.GROUPS }),
      this.searchService.search(userId, { ...query, q, limit: otherLimit, type: SearchEntityType.CHANNELS }),
      this.searchService.search(userId, { ...query, q, limit: otherLimit, type: SearchEntityType.POSTS }),
      this.searchService.search(userId, { ...query, q, limit: otherLimit, type: SearchEntityType.STREAMS }),
    ]);

    const getVal = (res: PromiseSettledResult<any>, key: string) =>
      res.status === 'fulfilled' ? (res.value?.results?.[key] ?? []) : [];

    // Build flat array — videos first so they appear at the top
    const flat: any[] = [
      ...getVal(videosRes, 'videos').map((v: any) => ({ entityType: 'video', ...v })),
      ...getVal(usersRes, 'users').map((u: any) => ({ entityType: 'user', ...u })),
      ...getVal(groupsRes, 'groups').map((g: any) => ({ entityType: 'group', ...g })),
      ...getVal(channelsRes, 'channels').map((c: any) => ({ entityType: 'channel', ...c })),
      ...getVal(postsRes, 'posts').map((p: any) => ({ entityType: 'post', ...p })),
      ...getVal(streamsRes, 'streams').map((s: any) => ({ entityType: 'stream', ...s })),
    ];

    return { items: flat.slice(0, totalLimit), total: flat.length };
  }
}

