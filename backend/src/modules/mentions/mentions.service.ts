// src/modules/mentions/mentions.service.ts
import { Injectable } from '@nestjs/common';
import { MentionsRepository } from './mentions.repository.js';
import { MentionQueryDto } from './dto/mention-suggestion.dto.js';

@Injectable()
export class MentionsService {
  constructor(private readonly mentionsRepository: MentionsRepository) {}

  async suggestUsers(dto: MentionQueryDto, requesterId?: string) {
    const limit = dto.limit ?? 8;
    const q = dto.q ?? '';
    return this.mentionsRepository.searchMentionableUsers(q, limit, requesterId);
  }

  async suggestGroups(dto: MentionQueryDto) {
    const limit = dto.limit ?? 8;
    const q = dto.q ?? '';
    return this.mentionsRepository.searchMentionableGroups(q, limit);
  }

  async suggestChannels(dto: MentionQueryDto) {
    const limit = dto.limit ?? 8;
    const q = dto.q ?? '';
    return this.mentionsRepository.searchMentionableChannels(q, limit);
  }

  // Combined: users + groups + channels in one call (sorted by type priority)
  async suggestAll(dto: MentionQueryDto, requesterId?: string) {
    const limit = dto.limit ?? 8;
    const q = dto.q ?? '';

    const [users, groups, channels] = await Promise.all([
      this.mentionsRepository.searchMentionableUsers(q, limit, requesterId),
      this.mentionsRepository.searchMentionableGroups(q, Math.ceil(limit / 2)),
      this.mentionsRepository.searchMentionableChannels(q, Math.ceil(limit / 2)),
    ]);

    // users first, then groups, then channels — total capped at limit
    return [...users, ...groups, ...channels].slice(0, limit);
  }

  async validateMentionedUsers(userIds: string[]): Promise<string[]> {
    return this.mentionsRepository.validateMentionedUsers(userIds);
  }
}
