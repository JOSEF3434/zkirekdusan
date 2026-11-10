// src/modules/mentions/mentions.service.ts
import { Injectable } from '@nestjs/common';
import { MentionsRepository } from './mentions.repository.js';
import { MentionQueryDto, MentionSuggestionDto } from './dto/mention-suggestion.dto.js';

const AT_USER_TOKEN_REGEX = /@\[user:([0-9a-f-]{36}):([^\]]+)\]/gi;

@Injectable()
export class MentionsService {
  constructor(private readonly mentionsRepository: MentionsRepository) {}

  async suggestUsers(dto: MentionQueryDto, requesterId?: string) {
    const limit = dto.limit ?? 10;
    const q = dto.q ?? '';
    return this.mentionsRepository.searchMentionableUsers(q, limit, requesterId);
  }

  async suggestGroups(dto: MentionQueryDto, requesterId?: string) {
    const limit = dto.limit ?? 10;
    const q = dto.q ?? '';
    return this.mentionsRepository.searchMentionableGroups(q, limit, requesterId);
  }

  async suggestChannels(dto: MentionQueryDto, requesterId?: string) {
    const limit = dto.limit ?? 10;
    const q = dto.q ?? '';
    return this.mentionsRepository.searchMentionableChannels(q, limit, requesterId);
  }

  /**
   * Combined autocomplete across users, groups, and channels.
   * Ensures all three categories can surface even when users alone fill `limit`.
   */
  async suggestAll(
    dto: MentionQueryDto,
    requesterId?: string,
  ): Promise<MentionSuggestionDto[]> {
    const limit = Math.min(dto.limit ?? 10, 25);
    const q = dto.q ?? '';

    const perType = Math.max(4, Math.ceil(limit * 0.6));
    const [users, groups, channels] = await Promise.all([
      this.mentionsRepository.searchMentionableUsers(q, perType, requesterId),
      this.mentionsRepository.searchMentionableGroups(q, perType, requesterId),
      this.mentionsRepository.searchMentionableChannels(q, perType, requesterId),
    ]);

    // Balanced merge: prioritize direct match feel (users first, then groups,
    // then channels) while reserving room so groups & channels aren't starved.
    const result: MentionSuggestionDto[] = [];
    const seen = new Set<string>();
    const pushItem = (item: MentionSuggestionDto) => {
      const key = `${item.type}:${item.id}`;
      if (!seen.has(key) && result.length < limit) {
        seen.add(key);
        result.push(item);
      }
    };

    // Round-robin top 3 from each category so mixed types appear immediately,
    // then fill remaining capacity starting with users.
    const maxLen = Math.max(users.length, groups.length, channels.length);
    for (let i = 0; i < Math.min(3, maxLen); i++) {
      if (i < users.length) pushItem(users[i]);
      if (i < groups.length) pushItem(groups[i]);
      if (i < channels.length) pushItem(channels[i]);
    }
    for (const u of users) pushItem(u);
    for (const g of groups) pushItem(g);
    for (const c of channels) pushItem(c);

    return result;
  }

  /**
   * Extracts user IDs ONLY from explicit `@[user:UUID:...]` mention tokens
   * (deliberately ignoring `#[user:UUID:...]` content references so picking
   * a user via `#` global search does not send mention notifications),
   * and validates all IDs against active, non-blocked database records.
   */
  async extractAndValidateAtMentionUserIds(
    content: string | null | undefined,
    extraIds: string[] = [],
    requesterId?: string,
  ): Promise<string[]> {
    const extracted = new Set<string>();
    if (content) {
      for (const match of content.matchAll(AT_USER_TOKEN_REGEX)) {
        if (match[1]) extracted.add(match[1]);
      }
    }
    for (const id of extraIds) {
      if (id) extracted.add(id);
    }
    if (extracted.size === 0) return [];
    return this.mentionsRepository.validateMentionedUsers(
      Array.from(extracted),
      requesterId,
    );
  }

  async validateMentionedUsers(
    userIds: string[],
    requesterId?: string,
  ): Promise<string[]> {
    return this.mentionsRepository.validateMentionedUsers(userIds, requesterId);
  }

  /**
   * Strips raw mention/reference token wrappers to produce human-readable
   * text (e.g. `@[user:uuid:jj]` -> `@jj`, `#[video:uuid:Test]` -> `#Test`)
   * for notification previews and plain-text summaries.
   */
  stripTokensToReadableText(content: string | null | undefined): string {
    if (!content) return '';
    return content.replace(
      /([@#])\[([a-z]+):([0-9a-f-]{36}):([^\]]+)\]/gi,
      '$1$4',
    );
  }

  /**
   * Neutralizes dangerous HTML/script injections in user-supplied text
   * while leaving inline mention/reference tokens and Unicode untouched.
   */
  sanitizePlainText(text: string | null | undefined): string | undefined {
    if (text === undefined || text === null) return undefined;
    return text.replace(/<\/?script[^>]*>/gi, '');
  }
}
