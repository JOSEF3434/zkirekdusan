// src/modules/presence/presence.service.ts
import { Injectable } from '@nestjs/common';
import { PresenceStatus } from '@prisma/client';
import { PresenceRepository } from './presence.repository.js';

export class PresenceResponseDto {
  userId!: string;
  status!: string;
  customStatus?: string;
  lastSeenAt!: Date;
}

@Injectable()
export class PresenceService {
  constructor(private readonly presenceRepository: PresenceRepository) {}

  async setStatus(
    userId: string,
    status: PresenceStatus,
    customStatus?: string,
  ): Promise<PresenceResponseDto> {
    const p = await this.presenceRepository.upsert(userId, status, customStatus);
    return this.mapToDto(p);
  }

  async getPresence(userId: string): Promise<PresenceResponseDto | null> {
    const p = await this.presenceRepository.findByUserId(userId);
    return p ? this.mapToDto(p) : null;
  }

  async getBulkPresence(userIds: string[]): Promise<PresenceResponseDto[]> {
    const presences = await this.presenceRepository.findManyByUserIds(userIds);
    return presences.map((p) => this.mapToDto(p));
  }

  async setOffline(userId: string): Promise<void> {
    await this.presenceRepository.setOffline(userId);
  }

  private mapToDto(p: any): PresenceResponseDto {
    const dto = new PresenceResponseDto();
    dto.userId = p.userId;
    dto.status = p.status;
    dto.customStatus = p.customStatus ?? undefined;
    dto.lastSeenAt = p.lastSeenAt;
    return dto;
  }
}
