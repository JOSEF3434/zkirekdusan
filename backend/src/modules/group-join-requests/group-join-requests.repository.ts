// src/modules/group-join-requests/group-join-requests.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';

const JOIN_REQUEST_INCLUDE = {
  user: {
    select: {
      id: true,
      username: true,
      profile: {
        select: { displayName: true, avatar: { select: { url: true } } },
      },
    },
  },
} as const;

@Injectable()
export class GroupJoinRequestsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(groupId: string, userId: string, note?: string) {
    return this.prisma.groupJoinRequest.create({
      data: { groupId, userId, note },
      include: JOIN_REQUEST_INCLUDE,
    });
  }

  async findPendingByGroupAndUser(groupId: string, userId: string) {
    return this.prisma.groupJoinRequest.findFirst({
      where: { groupId, userId, status: 'PENDING' },
    });
  }

  async findById(id: string) {
    return this.prisma.groupJoinRequest.findUnique({
      where: { id },
      include: JOIN_REQUEST_INCLUDE,
    });
  }

  async findPendingByGroup(groupId: string) {
    return this.prisma.groupJoinRequest.findMany({
      where: { groupId, status: 'PENDING' },
      include: JOIN_REQUEST_INCLUDE,
      orderBy: { createdAt: 'asc' },
    });
  }

  async findByUser(userId: string) {
    return this.prisma.groupJoinRequest.findMany({
      where: { userId },
      include: {
        ...JOIN_REQUEST_INCLUDE,
        group: {
          select: { id: true, name: true, slug: true, avatarUrl: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async approve(id: string) {
    return this.prisma.groupJoinRequest.update({
      where: { id },
      data: { status: 'APPROVED', respondedAt: new Date() },
      include: JOIN_REQUEST_INCLUDE,
    });
  }

  async reject(id: string) {
    return this.prisma.groupJoinRequest.update({
      where: { id },
      data: { status: 'REJECTED', respondedAt: new Date() },
      include: JOIN_REQUEST_INCLUDE,
    });
  }
}
