import { Injectable } from '@nestjs/common';
import { SearchRepository } from './search.repository.js';
import { SearchQueryDto, SearchEntityType } from './dto/search-query.dto.js';

@Injectable()
export class SearchService {
  constructor(private readonly searchRepository: SearchRepository) {}

  async search(userId: string | undefined, dto: SearchQueryDto) {
    const { q, type, page = 1, limit = 20 } = dto;
    const skip = (page - 1) * limit;

    if (!q) {
      return { results: [], page, limit };
    }

    if (userId) {
      this.searchRepository
        .recordSearchHistory(userId, q, type)
        .catch(() => null);
    }

    let results = {};

    switch (type) {
      case SearchEntityType.USERS:
        results = {
          users: await this.searchRepository.searchUsers(q, limit, skip),
        };
        break;
      case SearchEntityType.GROUPS:
        results = {
          groups: await this.searchRepository.searchGroups(q, limit, skip),
        };
        break;
      case SearchEntityType.POSTS:
        results = {
          posts: await this.searchRepository.searchPosts(q, limit, skip),
        };
        break;
      default: {
        // Unified search
        const [users, groups, posts] = await Promise.all([
          this.searchRepository.searchUsers(q, 5, 0),
          this.searchRepository.searchGroups(q, 5, 0),
          this.searchRepository.searchPosts(q, 5, 0),
        ]);
        results = { users, groups, posts };
      }
    }

    return { results, page, limit };
  }
}
