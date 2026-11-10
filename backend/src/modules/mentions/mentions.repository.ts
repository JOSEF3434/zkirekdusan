// src/modules/mentions/mentions.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { SearchRepository } from '../search/search.repository.js';
import { MentionSuggestionDto } from './dto/mention-suggestion.dto.js';

@Injectable()
export class MentionsRepository {
  constructor(
    private readonly prisma: PrismaService,
    private readonly searchRepository: SearchRepository,
  ) {}

  // ── User autocomplete for @ mentions (reuses SearchRepository) ────────────
  async searchMentionableUsers(
    q: string,
    limit: number,
    requesterId?: string,
  ): Promise<MentionSuggestionDto[]> {
    const users = await this.searchRepository.searchUsers(q, limit, 0, {
      requesterId,
      excludeSelf: false, // allow self if searched explicitly or reorder below
    });

    // Place other users ahead of requester so contacts appear first
    const sorted = [...users].sort((a, b) => {
      if (requesterId) {
        if (a.id === requesterId && b.id !== requesterId) return 1;
        if (b.id === requesterId && a.id !== requesterId) return -1;
      }
      return 0;
    });

    return sorted.slice(0, limit).map((u) => {
      const cleanHandle = (u.username || u.displayName || 'user').replace(/^@+/, '');
      return {
        id: u.id,
        type: 'user' as const,
        username: cleanHandle,
        displayName: u.displayName,
        avatarUrl: u.avatarUrl ?? undefined,
        isVerified: u.isVerified ?? false,
        subtitle: u.username ? `@${u.username.replace(/^@+/, '')}` : 'User',
      };
    });
  }

  // ── Group autocomplete for @ mentions (reuses SearchRepository) ───────────
  async searchMentionableGroups(
    q: string,
    limit: number,
    requesterId?: string,
  ): Promise<MentionSuggestionDto[]> {
    const groups = await this.searchRepository.searchGroups(
      q,
      limit,
      0,
      requesterId,
    );

    return groups.map((g) => {
      const cleanSlug = (g.slug || g.name).replace(/^@+/, '');
      return {
        id: g.id,
        type: 'group' as const,
        username: cleanSlug,
        displayName: g.name,
        avatarUrl: g.avatarUrl ?? undefined,
        subtitle: `${g.membersCount ?? 0} members`,
      };
    });
  }

  // ── Channel autocomplete for @ mentions (reuses SearchRepository) ─────────
  async searchMentionableChannels(
    q: string,
    limit: number,
    requesterId?: string,
  ): Promise<MentionSuggestionDto[]> {
    const channels = await this.searchRepository.searchChannels(
      q,
      limit,
      0,
      requesterId,
    );

    return channels.map((c: any) => {
      const cleanHandle = (c.handle || c.slug || c.name || 'channel').replace(
        /^@+/,
        '',
      );
      return {
        id: c.id,
        type: 'channel' as const,
        username: cleanHandle,
        displayName: c.name,
        avatarUrl: c.avatarFile?.url ?? undefined,
        isVerified: c.isVerified ?? false,
        subtitle: `@${cleanHandle}`,
      };
    });
  }

  // ── Validate user IDs exist, are ACTIVE, and aren't blocked/PRIVATE ───────
  async validateMentionedUsers(
    userIds: string[],
    requesterId?: string,
  ): Promise<string[]> {
    const unique = Array.from(new Set(userIds.filter(Boolean)));
    if (!unique.length) return [];

    const blockedIds = await this.searchRepository.getBlockedUserIds(requesterId);
    const blockedSet = new Set(blockedIds);
    const candidates = unique.filter((id) => !blockedSet.has(id) && id !== requesterId);
    if (!candidates.length) return [];

    const found = await this.prisma.user.findMany({
      where: {
        id: { in: candidates },
        status: 'ACTIVE',
      },
      select: { id: true },
    });

    return found.map((u) => u.id);
  }
}
