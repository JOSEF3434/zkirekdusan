// src/modules/presence/presence.repository.ts
import { Injectable } from '@nestjs/common';
import { PresenceStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class PresenceRepository {
  constructor(private readonly prisma: PrismaService) {}

  async upsert(userId: string, status: PresenceStatus, customStatus?: string) {
    // Only record lastSeenAt when transitioning to OFFLINE so the timestamp
    // accurately reflects the last moment the user was actually present.
    // Updating it on every ONLINE upsert would cause "last seen just now"
    // to appear for users who are currently connected.
    const updateData: {
      status: PresenceStatus;
      customStatus?: string;
      lastSeenAt?: Date;
    } = { status, customStatus };

    if (status === PresenceStatus.OFFLINE) {
      updateData.lastSeenAt = new Date();
    }

    return this.prisma.userPresence.upsert({
      where: { userId },
      create: { userId, status, customStatus, lastSeenAt: new Date() },
      update: updateData,
    });
  }

  async findByUserId(userId: string) {
    return this.prisma.userPresence.findUnique({ where: { userId } });
  }

  async findManyByUserIds(userIds: string[]) {
    return this.prisma.userPresence.findMany({
      where: { userId: { in: userIds } },
    });
  }

  async setOffline(userId: string) {
    // Always record lastSeenAt when explicitly setting a user offline
    return this.prisma.userPresence.upsert({
      where: { userId },
      create: {
        userId,
        status: PresenceStatus.OFFLINE,
        lastSeenAt: new Date(),
      },
      update: { status: PresenceStatus.OFFLINE, lastSeenAt: new Date() },
    });
  }
}
