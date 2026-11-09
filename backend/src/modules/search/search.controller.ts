import {
  Controller,
  Get,
  Query,
  UseGuards,
  ValidationPipe,
  Inject,
  Request,
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

  /**
   * GET /api/search/unified?q=abc&limit=12
   *
   * Flat list of mixed content for the # content picker.
   * Returns items tagged with their `entityType` so the Flutter client
   * knows where to navigate.
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
    const limit = Math.min(query.limit ?? 12, 30);

    const result = await this.searchService.search(userId, {
      ...query,
      q,
      limit: Math.ceil(limit / 4), // distribute among types
      type: undefined,
    });

    const { results } = result;

    // Build a flat array with entityType tag for the Flutter content picker
    const flat: any[] = [];

    (results.videos ?? []).forEach((v: any) =>
      flat.push({ entityType: 'video', ...v }),
    );
    (results.users ?? []).forEach((u: any) =>
      flat.push({ entityType: 'user', ...u }),
    );
    (results.groups ?? []).forEach((g: any) =>
      flat.push({ entityType: 'group', ...g }),
    );
    (results.channels ?? []).forEach((c: any) =>
      flat.push({ entityType: 'channel', ...c }),
    );
    (results.posts ?? []).forEach((p: any) =>
      flat.push({ entityType: 'post', ...p }),
    );
    (results.streams ?? []).forEach((s: any) =>
      flat.push({ entityType: 'stream', ...s }),
    );

    return { items: flat.slice(0, limit), total: flat.length };
  }
}

