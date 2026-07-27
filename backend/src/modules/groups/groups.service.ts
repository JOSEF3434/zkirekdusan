// src/modules/groups/groups.service.ts
import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { GroupsRepository } from './groups.repository.js';
import { CreateGroupDto } from './dto/create-group.dto.js';
import { UpdateGroupDto } from './dto/update-group.dto.js';
import { GroupResponseDto } from './dto/group-response.dto.js';
import { GroupRole } from '../../common/constants/group-roles.js';

@Injectable()
export class GroupsService {
  constructor(private readonly groupsRepository: GroupsRepository) {}

  /**
   * Create a new group.
   * NOTE: New groups start with status PENDING_APPROVAL.
   * They must be approved by an ADMIN or SUPER_ADMIN before full functionality is enabled.
   */
  async createGroup(dto: CreateGroupDto, creatorId: string): Promise<GroupResponseDto> {
    const slugExists = await this.groupsRepository.findBySlug(dto.slug);
    if (slugExists) {
      throw new BadRequestException(`Group with slug '${dto.slug}' already exists`);
    }

    const group = await this.groupsRepository.createGroup({
      ...dto,
      createdById: creatorId,
    });

    return {
      id: group.id,
      name: group.name,
      slug: group.slug,
      description: group.description,
      status: group.status,
      visibility: group.visibility,
      createdById: group.createdById,
      approvedById: group.approvedById,
      approvedAt: group.approvedAt,
      membersCount: 1,
      createdAt: group.createdAt,
    };
  }

  /**
   * Approve a pending group — ADMIN / SUPER_ADMIN only
   */
  async approveGroup(groupId: string, adminId: string): Promise<GroupResponseDto> {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) {
      throw new NotFoundException('Group not found');
    }

    if (group.status === 'ACTIVE') {
      throw new BadRequestException('Group is already active');
    }

    const updated = await this.groupsRepository.approveGroup(groupId, adminId);
    const count = group._count?.members ?? 1;

    return {
      id: updated.id,
      name: updated.name,
      slug: updated.slug,
      description: updated.description,
      status: updated.status,
      visibility: updated.visibility,
      createdById: updated.createdById,
      approvedById: updated.approvedById,
      approvedAt: updated.approvedAt,
      membersCount: count,
      createdAt: updated.createdAt,
    };
  }

  async getGroupById(groupId: string): Promise<GroupResponseDto> {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) {
      throw new NotFoundException('Group not found');
    }

    return {
      id: group.id,
      name: group.name,
      slug: group.slug,
      description: group.description,
      status: group.status,
      visibility: group.visibility,
      createdById: group.createdById,
      approvedById: group.approvedById,
      approvedAt: group.approvedAt,
      membersCount: group._count.members,
      createdAt: group.createdAt,
    };
  }

  async getGroupBySlug(slug: string): Promise<GroupResponseDto> {
    const group = await this.groupsRepository.findBySlug(slug);
    if (!group) {
      throw new NotFoundException(`Group with slug '${slug}' not found`);
    }

    return {
      id: group.id,
      name: group.name,
      slug: group.slug,
      description: group.description,
      status: group.status,
      visibility: group.visibility,
      createdById: group.createdById,
      membersCount: group._count.members,
      createdAt: group.createdAt,
    };
  }

  async updateGroup(groupId: string, dto: UpdateGroupDto): Promise<GroupResponseDto> {
    await this.groupsRepository.updateGroup(groupId, dto);
    return this.getGroupById(groupId);
  }

  async listPublicActiveGroups(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const { items, total } = await this.groupsRepository.findPublicActiveGroups(skip, limit);

    const data: GroupResponseDto[] = items.map((g) => ({
      id: g.id,
      name: g.name,
      slug: g.slug,
      description: g.description,
      status: g.status,
      visibility: g.visibility,
      createdById: g.createdById,
      membersCount: g._count.members,
      createdAt: g.createdAt,
    }));

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

  async listPendingGroups(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const { items, total } = await this.groupsRepository.findPendingGroups(skip, limit);

    const data = items.map((g) => ({
      id: g.id,
      name: g.name,
      slug: g.slug,
      description: g.description,
      status: g.status,
      createdById: g.createdById,
      createdByUsername: g.createdBy.username,
      createdAt: g.createdAt,
    }));

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

  async inviteUser(groupId: string, senderId: string, recipientId: string, role = GroupRole.MEMBER) {
    const group = await this.groupsRepository.findById(groupId);
    if (!group || group.status !== 'ACTIVE') {
      throw new ForbiddenException('Group must be active to invite members');
    }

    const existingMember = await this.groupsRepository.getMember(groupId, recipientId);
    if (existingMember) {
      throw new BadRequestException('User is already a member of this group');
    }

    const invite = await this.groupsRepository.createInvite(groupId, senderId, recipientId, role);
    return {
      message: 'Invite sent successfully',
      inviteToken: invite.token,
      expiresAt: invite.expiresAt,
    };
  }

  async joinByInvite(token: string, userId: string) {
    const invite = await this.groupsRepository.findInviteByToken(token);
    if (!invite || invite.status !== 'PENDING' || invite.expiresAt < new Date()) {
      throw new BadRequestException('Invalid or expired invite token');
    }

    if (invite.recipientId !== userId) {
      throw new ForbiddenException('This invite token was not issued to you');
    }

    await this.groupsRepository.addMember(invite.groupId, userId, invite.role as GroupRole);
    await this.groupsRepository.acceptInvite(invite.id);

    return { message: 'Successfully joined group' };
  }
}
