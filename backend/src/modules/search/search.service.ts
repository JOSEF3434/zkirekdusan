import { Injectable, Logger } from '@nestjs/common';
import { SearchRepository } from './search.repository.js';
import { SearchQueryDto, SearchEntityType } from './dto/search-query.dto.js';

@Injectable()
export class SearchService {
  private readonly logger = new Logger(SearchService.name);

  constructor(private readonly searchRepository: SearchRepository) {}

  async search(userId: string | undefined, dto: SearchQueryDto) {
    const { q, type, page = 1, limit = 20 } = dto;
    const skip = (page - 1) * limit;

    const emptyResults = {
      users: [],
      groups: [],
      channels: [],
      posts: [],
      books: [],
      videos: [],
      reels: [],
      streams: [],
    };

    if (!q || !q.trim()) {
      return { results: emptyResults, page, limit };
    }

    const cleanQ = q.trim();

    if (userId) {
      this.searchRepository
        .recordSearchHistory(userId, cleanQ, type)
        .catch(() => null);
    }

    const blockedIds = await this.searchRepository
      .getBlockedUserIds(userId)
      .catch(() => [] as string[]);

    let results: Record<string, any> = {};

    switch (type) {
      case SearchEntityType.USERS:
        results = {
          users: await this.searchRepository
            .searchUsers(cleanQ, limit, skip, { requesterId: userId, blockedIds })
            .catch((err) => {
              this.logger.error(`Error searching users: ${err.message}`);
              return [];
            }),
        };
        break;
      case SearchEntityType.GROUPS:
        results = {
          groups: await this.searchRepository
            .searchGroups(cleanQ, limit, skip, userId)
            .catch((err) => {
              this.logger.error(`Error searching groups: ${err.message}`);
              return [];
            }),
        };
        break;
      case SearchEntityType.CHANNELS:
        results = {
          channels: await this.searchRepository
            .searchChannels(cleanQ, limit, skip, userId)
            .catch((err) => {
              this.logger.error(`Error searching channels: ${err.message}`);
              return [];
            }),
        };
        break;
      case SearchEntityType.POSTS:
        results = {
          posts: await this.searchRepository
            .searchPosts(cleanQ, limit, skip, { requesterId: userId, blockedIds })
            .catch((err) => {
              this.logger.error(`Error searching posts: ${err.message}`);
              return [];
            }),
        };
        break;
      case SearchEntityType.BOOKS:
        results = {
          books: await this.searchRepository
            .searchBooks(cleanQ, limit, skip)
            .catch((err) => {
              this.logger.error(`Error searching books: ${err.message}`);
              return [];
            }),
        };
        break;
      case SearchEntityType.VIDEOS:
        results = {
          videos: await this.searchRepository
            .searchVideos(cleanQ, limit, skip, { requesterId: userId, blockedIds })
            .catch((err) => {
              this.logger.error(`Error searching videos: ${err.message}`);
              return [];
            }),
        };
        break;
      case SearchEntityType.REELS:
        results = {
          reels: await this.searchRepository
            .searchReels(cleanQ, limit, skip, { blockedIds })
            .catch((err) => {
              this.logger.error(`Error searching reels: ${err.message}`);
              return [];
            }),
        };
        break;
      case SearchEntityType.STREAMS:
        results = {
          streams: await this.searchRepository
            .searchLiveStreams(cleanQ, limit, skip)
            .catch((err) => {
              this.logger.error(`Error searching streams: ${err.message}`);
              return [];
            }),
        };
        break;
      default: {
        const perTypeLimit = Math.max(5, Math.min(limit, 10));
        const perTypeSkip = page > 1 ? (page - 1) * perTypeLimit : 0;

        // Unified fault-tolerant search across all supported categories
        const [
          usersRes,
          groupsRes,
          channelsRes,
          postsRes,
          booksRes,
          videosRes,
          reelsRes,
          streamsRes,
        ] = await Promise.allSettled([
          this.searchRepository.searchUsers(cleanQ, perTypeLimit, perTypeSkip, {
            requesterId: userId,
            blockedIds,
          }),
          this.searchRepository.searchGroups(cleanQ, perTypeLimit, perTypeSkip, userId),
          this.searchRepository.searchChannels(cleanQ, perTypeLimit, perTypeSkip, userId),
          this.searchRepository.searchPosts(cleanQ, perTypeLimit, perTypeSkip, {
            requesterId: userId,
            blockedIds,
          }),
          this.searchRepository.searchBooks(cleanQ, perTypeLimit, perTypeSkip),
          this.searchRepository.searchVideos(cleanQ, Math.max(10, perTypeLimit), perTypeSkip, {
            requesterId: userId,
            blockedIds,
          }),
          this.searchRepository.searchReels(cleanQ, perTypeLimit, perTypeSkip, {
            blockedIds,
          }),
          this.searchRepository.searchLiveStreams(cleanQ, perTypeLimit, perTypeSkip),
        ]);

        const unwrap = (res: PromiseSettledResult<any[]>, label: string) => {
          if (res.status === 'fulfilled') return res.value;
          this.logger.error(`Unified search [${label}] failed: ${res.reason}`);
          return [];
        };

        results = {
          users: unwrap(usersRes, 'users'),
          groups: unwrap(groupsRes, 'groups'),
          channels: unwrap(channelsRes, 'channels'),
          posts: unwrap(postsRes, 'posts'),
          books: unwrap(booksRes, 'books'),
          videos: unwrap(videosRes, 'videos'),
          reels: unwrap(reelsRes, 'reels'),
          streams: unwrap(streamsRes, 'streams'),
        };
      }
    }

    return { results, page, limit };
  }
}
