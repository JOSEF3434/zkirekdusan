// src/modules/groups/groups.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CreateGroupDto } from './dto/create-group.dto.js';
import { UpdateGroupDto } from './dto/update-group.dto.js';
import { GroupRole } from '../../common/constants/group-roles.js';
import { VideoChannelStatus } from '@prisma/client';

@Injectable()
export class GroupsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createGroup(data: CreateGroupDto & { createdById: string; status?: import('@prisma/client').GroupStatus }) {
    // Create group with provided status (or PENDING_APPROVAL) and add creator as GROUP_ADMIN
    return this.prisma.$transaction(async (tx) => {
      const group = await tx.group.create({
        data: {
          name: data.name,
          slug: data.slug,
          description: data.description,
          visibility: data.visibility ?? 'PUBLIC',
          status: data.status ?? 'PENDING_APPROVAL',
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

      // Automatically provision the primary video channel for the group
      const baseHandle = data.slug.replace(/[^a-zA-Z0-9_]/g, '_').toLowerCase();
      const channelHandle = baseHandle.length > 0 ? baseHandle.substring(0, 30) : `channel_${group.id.substring(0, 8)}`;
      await tx.videoChannel.create({
        data: {
          groupId: group.id,
          name: `${data.name} Channel`,
          slug: data.slug,
          handle: channelHandle,
          description: `Official video channel for ${data.name}`,
          status: 'ACTIVE',
          uploadPermission: 'MEMBER',
          downloadPermission: 'PUBLIC',
        },
      });

      return group;
    });
  }

  async createDefaultChannel(groupId: string, name: string, slug: string) {
    const baseHandle = slug.replace(/[^a-zA-Z0-9_]/g, '_').toLowerCase();
    const channelHandle = baseHandle.length > 0 ? baseHandle.substring(0, 30) : `channel_${groupId.substring(0, 8)}`;
    return this.prisma.videoChannel.create({
      data: {
        groupId,
        name: `${name} Channel`,
        slug: `${slug}-${Date.now().toString().slice(-4)}`,
        handle: `${channelHandle}_${Date.now().toString().slice(-4)}`.substring(0, 30),
        description: `Official video channel for ${name}`,
        status: 'ACTIVE',
        uploadPermission: 'MEMBER',
        downloadPermission: 'PUBLIC',
      },
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
  /**
   * Fetch full group data including non-archived video channels and member count.
   * Used exclusively by the Group Context endpoint.
   */
  async findWithChannels(id: string) {
    return this.prisma.group.findFirst({
      where: { id, deletedAt: null },
      include: {
        _count: { select: { members: { where: { removedAt: null } } } },
        videoChannels: {
          where: {
            deletedAt: null,
            status: { not: VideoChannelStatus.ARCHIVED },
          },
          select: {
            id: true,
            name: true,
            slug: true,
            handle: true,
            description: true,
            status: true,
            uploadPermission: true,
            subscribersCount: true,
            videosCount: true,
            createdAt: true,
          },
          orderBy: { createdAt: 'asc' }, // oldest first = primary
        },
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

  async rejectGroup(id: string, adminId: string) {
    return this.prisma.group.update({
      where: { id },
      data: {
        status: 'REJECTED',
        approvedById: adminId,
        approvedAt: new Date(),
      },
    });
  }

  async findMyGroups(userId: string, skip = 0, take = 50) {
    const where = { createdById: userId, deletedAt: null };
    const [items, total] = await Promise.all([
      this.prisma.group.findMany({
        where,
        skip,
        take,
        include: {
          _count: { select: { members: { where: { removedAt: null } } } },
          createdBy: { select: { id: true, username: true, email: true } },
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.group.count({ where }),
    ]);
    return { items, total };
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
    return this.prisma.groupMember.findFirst({
      where: { groupId, userId, removedAt: null },
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

  // ─── Member Management ─────────────────────────────────────────────────────

  async findMembers(
    groupId: string,
    skip = 0,
    take = 30,
  ) {
    const where = { groupId, removedAt: null };
    const [items, total] = await Promise.all([
      this.prisma.groupMember.findMany({
        where,
        skip,
        take,
        include: {
          user: {
            select: {
              id: true,
              username: true,
              profile: { select: { displayName: true, avatarFileId: true } },
            },
          },
        },
        orderBy: { joinedAt: 'asc' },
      }),
      this.prisma.groupMember.count({ where }),
    ]);
    return { items, total };
  }

  async updateMemberRole(groupId: string, userId: string, role: GroupRole) {
    return this.prisma.groupMember.update({
      where: { groupId_userId: { groupId, userId } },
      data: { role },
    });
  }

  async removeMember(groupId: string, userId: string) {
    return this.prisma.groupMember.update({
      where: { groupId_userId: { groupId, userId } },
      data: { removedAt: new Date() },
    });
  }

  async ensureCreatorMembership(groupId: string, createdById: string) {
    const existing = await this.prisma.groupMember.findFirst({
      where: { groupId, userId: createdById, removedAt: null },
    });
    if (!existing) {
      await this.prisma.groupMember.create({
        data: {
          groupId,
          userId: createdById,
          role: 'GROUP_ADMIN',
        },
      });
    }
  }
}

