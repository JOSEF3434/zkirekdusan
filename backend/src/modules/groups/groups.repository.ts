// src/modules/groups/groups.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CreateGroupDto } from './dto/create-group.dto.js';
import { UpdateGroupDto } from './dto/update-group.dto.js';
import { GroupRole } from '../../common/constants/group-roles.js';

@Injectable()
export class GroupsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createGroup(data: CreateGroupDto & { createdById: string }) {
    // Create group with PENDING_APPROVAL status and add creator as GROUP_ADMIN
    return this.prisma.$transaction(async (tx) => {
      const group = await tx.group.create({
        data: {
          name: data.name,
          slug: data.slug,
          description: data.description,
          visibility: data.visibility ?? 'PUBLIC',
          status: 'PENDING_APPROVAL',
          createdById: data.createdById,
        },
      });

      await tx.groupMember.create({
        data: {
          groupId: group.id,
          userId: data.createdById,
          role: 'GROUP_ADMIN',
        },
      });

      return group;
    });
  }

  async findById(id: string) {
    return this.prisma.group.findFirst({
      where: { id, deletedAt: null },
      include: {
        _count: { select: { members: { where: { removedAt: null } } } },
        createdBy: { select: { id: true, username: true, email: true } },
      },
    });
  }

  async findBySlug(slug: string) {
    return this.prisma.group.findFirst({
      where: { slug, deletedAt: null },
      include: {
        _count: { select: { members: { where: { removedAt: null } } } },
      },
    });
  }

  async updateGroup(id: string, data: UpdateGroupDto) {
    return this.prisma.group.update({
      where: { id },
      data,
    });
  }

  async approveGroup(id: string, adminId: string) {
    return this.prisma.group.update({
      where: { id },
      data: {
        status: 'ACTIVE',
        approvedById: adminId,
        approvedAt: new Date(),
      },
    });
  }

  async softDeleteGroup(id: string) {
    return this.prisma.group.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  async findPublicActiveGroups(skip = 0, take = 20) {
    const where = {
      status: 'ACTIVE' as const,
      visibility: 'PUBLIC' as const,
      deletedAt: null,
    };
    const [items, total] = await Promise.all([
      this.prisma.group.findMany({
        where,
        skip,
        take,
        include: {
          _count: { select: { members: { where: { removedAt: null } } } },
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.group.count({ where }),
    ]);
    return { items, total };
  }

  async findPendingGroups(skip = 0, take = 20) {
    const where = { status: 'PENDING_APPROVAL' as const, deletedAt: null };
    const [items, total] = await Promise.all([
      this.prisma.group.findMany({
        where,
        skip,
        take,
        include: {
          createdBy: { select: { id: true, username: true, email: true } },
        },
        orderBy: { createdAt: 'asc' },
      }),
      this.prisma.group.count({ where }),
    ]);
    return { items, total };
  }

  async getMember(groupId: string, userId: string) {
    return this.prisma.groupMember.findUnique({
      where: { groupId_userId: { groupId, userId }, removedAt: null },
      include: { user: { select: { id: true, username: true } } },
    });
  }

  async addMember(
    groupId: string,
    userId: string,
    role: GroupRole = GroupRole.MEMBER,
  ) {
    return this.prisma.groupMember.upsert({
      where: { groupId_userId: { groupId, userId } },
      create: { groupId, userId, role },
      update: { role, removedAt: null, joinedAt: new Date() },
    });
  }

  async removeMember(groupId: string, userId: string) {
    return this.prisma.groupMember.update({
      where: { groupId_userId: { groupId, userId } },
      data: { removedAt: new Date() },
    });
  }

  async updateMemberRole(groupId: string, userId: string, role: GroupRole) {
    return this.prisma.groupMember.update({
      where: { groupId_userId: { groupId, userId } },
      data: { role },
    });
  }

  async createInvite(
    groupId: string,
    senderId: string,
    recipientId: string,
    role: GroupRole,
  ) {
    return this.prisma.groupInvite.create({
      data: {
        groupId,
        senderId,
        recipientId,
        role,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });
  }

  async findInviteByToken(token: string) {
    return this.prisma.groupInvite.findUnique({
      where: { token },
      include: { group: true },
    });
  }

  async acceptInvite(inviteId: string) {
    return this.prisma.groupInvite.update({
      where: { id: inviteId },
      data: { status: 'ACCEPTED', respondedAt: new Date() },
    });
  }
}
