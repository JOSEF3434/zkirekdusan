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

    let results: Record<string, any> = {};

    switch (type) {
      case SearchEntityType.USERS:
        results = {
          users: await this.searchRepository
            .searchUsers(cleanQ, limit, skip)
            .catch((err) => {
              this.logger.error(`Error searching users: ${err.message}`);
              return [];
            }),
        };
        break;
      case SearchEntityType.GROUPS:
        results = {
          groups: await this.searchRepository
            .searchGroups(cleanQ, limit, skip)
            .catch((err) => {
              this.logger.error(`Error searching groups: ${err.message}`);
              return [];
            }),
        };
        break;
      case SearchEntityType.CHANNELS:
        results = {
          channels: await this.searchRepository
            .searchChannels(cleanQ, limit, skip)
            .catch((err) => {
              this.logger.error(`Error searching channels: ${err.message}`);
              return [];
            }),
        };
        break;
      case SearchEntityType.POSTS:
        results = {
          posts: await this.searchRepository
            .searchPosts(cleanQ, limit, skip)
            .catch((err) => {
              this.logger.error(`Error searching posts: ${err.message}`);
              return [];
            }),
        };
        break;
      case SearchEntityType.VIDEOS:
        results = {
          videos: await this.searchRepository
            .searchVideos(cleanQ, limit, skip)
            .catch((err) => {
              this.logger.error(`Error searching videos: ${err.message}`);
              return [];
            }),
        };
        break;
      case SearchEntityType.REELS:
        results = {
          reels: await this.searchRepository
            .searchReels(cleanQ, limit, skip)
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
        // Unified search using allSettled to ensure fault-tolerance across models
        const [
          usersRes,
          groupsRes,
          channelsRes,
          postsRes,
          videosRes,
          reelsRes,
          streamsRes,
        ] = await Promise.allSettled([
          this.searchRepository.searchUsers(cleanQ, 5, 0),
          this.searchRepository.searchGroups(cleanQ, 5, 0),
          this.searchRepository.searchChannels(cleanQ, 5, 0),
          this.searchRepository.searchPosts(cleanQ, 5, 0),
          this.searchRepository.searchVideos(cleanQ, 10, 0),
          this.searchRepository.searchReels(cleanQ, 5, 0),
          this.searchRepository.searchLiveStreams(cleanQ, 5, 0),
        ]);

        results = {
          users: usersRes.status === 'fulfilled' ? usersRes.value : [],
          groups: groupsRes.status === 'fulfilled' ? groupsRes.value : [],
          channels: channelsRes.status === 'fulfilled' ? channelsRes.value : [],
          posts: postsRes.status === 'fulfilled' ? postsRes.value : [],
          videos: videosRes.status === 'fulfilled' ? videosRes.value : [],
          reels: reelsRes.status === 'fulfilled' ? reelsRes.value : [],
          streams: streamsRes.status === 'fulfilled' ? streamsRes.value : [],
        };
      }
    }

    return { results, page, limit };
  }
}
