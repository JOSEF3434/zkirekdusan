// src/modules/reels/reels.service.ts
import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ReelsRepository } from './reels.repository.js';
import { CreateReelDto } from './dto/create-reel.dto.js';
import { ReelResponseDto } from './dto/reel-response.dto.js';

@Injectable()
export class ReelsService {
  constructor(private readonly reelsRepository: ReelsRepository) {}

  async createReel(
    authorId: string,
    dto: CreateReelDto,
  ): Promise<ReelResponseDto> {
    const reel = await this.reelsRepository.createReel(authorId, dto);
    return this.mapToDto(reel);
  }

  async getReelById(reelId: string): Promise<ReelResponseDto> {
    const reel = await this.reelsRepository.findById(reelId);
    if (!reel) {
      throw new NotFoundException('Reel not found');
    }
    await this.reelsRepository.incrementViews(reelId);
    return this.mapToDto(reel);
  }

  async getReelsFeed(page = 1, limit = 20, authorId?: string) {
    const skip = (page - 1) * limit;
    const { items, total } = await this.reelsRepository.findFeed(
      skip,
      limit,
      authorId,
    );

    const data = items.map((r) => this.mapToDto(r));

    return {
      data,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1,
      },
    };
  }

  async deleteReel(reelId: string, userId: string) {
    const reel = await this.reelsRepository.findById(reelId);
    if (!reel) {
      throw new NotFoundException('Reel not found');
    }

    if (reel.authorId !== userId) {
      throw new ForbiddenException('You can only delete your own reels');
    }

    await this.reelsRepository.softDelete(reelId);
    return { message: 'Reel deleted successfully' };
  }

  private mapToDto(r: any): ReelResponseDto {
    return {
      id: r.id,
      videoUrl: r.file?.url ?? '',
      thumbnailUrl: r.thumbnailUrl,
      caption: r.caption,
      hashtags: r.hashtags ?? [],
      duration: r.duration,
      likesCount: r.likesCount ?? 0,
      commentsCount: r.commentsCount ?? 0,
      viewsCount: r.viewsCount ?? 0,
      author: {
        id: r.author.id,
        username: r.author.username,
        displayName: r.author.profile?.displayName ?? r.author.username,
        avatarUrl: r.author.profile?.avatar?.url ?? null,
      },
      createdAt: r.createdAt,
    };
  }
}
