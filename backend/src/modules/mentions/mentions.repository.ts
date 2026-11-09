// src/modules/mentions/mentions.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { MentionSuggestionDto } from './dto/mention-suggestion.dto.js';

@Injectable()
export class MentionsRepository {
  constructor(private readonly prisma: PrismaService) {}

  // ── User autocomplete for @ mentions ──────────────────────────────────────
  async searchMentionableUsers(
    q: string,
    limit: number,
    requesterId?: string,
  ): Promise<MentionSuggestionDto[]> {
    const cleanQ = q.trim();

    const where: any = {
      status: 'ACTIVE',
      username: { not: null },
    };

    if (cleanQ) {
      where.OR = [
        { username: { contains: cleanQ } },
        {
          profile: {
            displayName: { contains: cleanQ, mode: 'insensitive' },
          },
        },
      ];
    }

    // Exclude the requester themselves
    if (requesterId) {
      where.id = { not: requesterId };
    }

    const users = await this.prisma.user.findMany({
      where,
      take: limit,
      select: {
        id: true,
        username: true,
        profile: {
          select: {
            displayName: true,
            isVerified: true,
            avatar: { select: { url: true } },
          },
        },
      },
      orderBy: [{ username: 'asc' }],
    });

    return users
      .filter((u) => u.username)
      .map((u) => ({
        id: u.id,
        type: 'user' as const,
        username: u.username!,
        displayName:
          u.profile?.displayName ?? u.username ?? 'Unknown',
        avatarUrl: u.profile?.avatar?.url ?? undefined,
        isVerified: u.profile?.isVerified ?? false,
      }));
  }

  // ── Group autocomplete for @ mentions ─────────────────────────────────────
  async searchMentionableGroups(
    q: string,
    limit: number,
  ): Promise<MentionSuggestionDto[]> {
    const cleanQ = q.trim();

    const where: any = {
      status: 'ACTIVE',
      visibility: 'PUBLIC',
    };

    if (cleanQ) {
      where.OR = [
        { slug: { contains: cleanQ, mode: 'insensitive' } },
        { name: { contains: cleanQ, mode: 'insensitive' } },
      ];
    }

    const groups = await this.prisma.group.findMany({
      where,
      take: limit,
      select: {
        id: true,
        name: true,
        slug: true,
        avatarUrl: true,
      },
      orderBy: [{ name: 'asc' }],
    });

    return groups.map((g) => ({
      id: g.id,
      type: 'group' as const,
      username: g.slug,
      displayName: g.name,
      avatarUrl: g.avatarUrl ?? undefined,
    }));
  }

  // ── Channel (VideoChannel) autocomplete for @ mentions ────────────────────
  async searchMentionableChannels(
    q: string,
    limit: number,
  ): Promise<MentionSuggestionDto[]> {
    const cleanQ = q.trim();

    const where: any = {
      isActive: true,
    };

    if (cleanQ) {
      where.OR = [
        { handle: { contains: cleanQ, mode: 'insensitive' } },
        { name: { contains: cleanQ, mode: 'insensitive' } },
      ];
    }

    // Check which fields exist on VideoChannel
    const channels = await (this.prisma as any).videoChannel.findMany({
      where,
      take: limit,
      select: {
        id: true,
        name: true,
        handle: true,
        avatar: { select: { url: true } },
      },
      orderBy: [{ name: 'asc' }],
    }).catch(() => []);

    return channels.map((c: any) => ({
      id: c.id,
      type: 'channel' as const,
      username: c.handle ?? c.name,
      displayName: c.name,
      avatarUrl: c.avatar?.url ?? undefined,
    }));
  }

  // ── Validate entity IDs exist (called on message/post save) ───────────────
  async validateMentionedUsers(userIds: string[]): Promise<string[]> {
    if (!userIds.length) return [];
    const found = await this.prisma.user.findMany({
      where: { id: { in: userIds }, status: 'ACTIVE' },
      select: { id: true },
    });
    return found.map((u) => u.id);
  }
}
