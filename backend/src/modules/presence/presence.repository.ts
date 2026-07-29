// src/modules/presence/presence.repository.ts
import { Injectable } from '@nestjs/common';
import { PresenceStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class PresenceRepository {
  constructor(private readonly prisma: PrismaService) {}

  async upsert(userId: string, status: PresenceStatus, customStatus?: string) {
    return this.prisma.userPresence.upsert({
      where: { userId },
      create: { userId, status, customStatus, lastSeenAt: new Date() },
      update: { status, customStatus, lastSeenAt: new Date() },
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
    return this.prisma.userPresence.upsert({
      where: { userId },
      create: { userId, status: PresenceStatus.OFFLINE, lastSeenAt: new Date() },
      update: { status: PresenceStatus.OFFLINE, lastSeenAt: new Date() },
    });
  }
}
