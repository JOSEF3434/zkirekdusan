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
import { AppRole } from '../../common/constants/roles.js';
import { PERMISSIONS } from '../../common/constants/permissions.js';
import { AuthorizationService } from '../authorization/authorization.service.js';

@Injectable()
export class GroupsService {
  constructor(
    private readonly groupsRepository: GroupsRepository,
    private readonly authorizationService: AuthorizationService,
  ) {}

  /**
   * Create a new group.
   * Status is determined by the backend based on authenticated user's role and permissions:
   *  - SUPER_ADMIN → ACTIVE immediately
   *  - ADMIN → ACTIVE immediately
   *  - USER with 'groups.approve' permission → ACTIVE immediately
   *  - All others → PENDING_APPROVAL
   */
  async createGroup(
    dto: CreateGroupDto,
    user: any,
  ): Promise<GroupResponseDto> {
    const slugExists = await this.groupsRepository.findBySlug(dto.slug);
    if (slugExists) {
      throw new BadRequestException(
        `Group with slug '${dto.slug}' already exists`,
      );
    }

    const userId = user.sub ?? user.id;

    // Determine status entirely on the backend — client cannot influence this
    let status: 'ACTIVE' | 'PENDING_APPROVAL' = 'PENDING_APPROVAL';

    if (
      (user.role as AppRole) === AppRole.SUPER_ADMIN ||
      (user.role as AppRole) === AppRole.ADMIN
    ) {
      status = 'ACTIVE';
    } else {
      // Check if user has the explicit auto-approve permission (via role-based permission system)
      const canAutoApprove = await this.authorizationService.hasPermission(
        userId,
        PERMISSIONS.GROUPS.APPROVE,
      );
      if (canAutoApprove) {
        status = 'ACTIVE';
      }
    }

    const group = await this.groupsRepository.createGroup({
      ...dto,
      createdById: userId,
      status,
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
  async approveGroup(
    groupId: string,
    adminId: string,
  ): Promise<GroupResponseDto> {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) {
      throw new NotFoundException('Group not found');
    }

    if (group.status === 'ACTIVE') {
      throw new BadRequestException('Group is already active');
    }

    if (group.status === 'REJECTED') {
      throw new BadRequestException(
        'Cannot approve a rejected group. Please contact a Super Admin.',
      );
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

  /**
   * Reject a pending group — ADMIN / SUPER_ADMIN only
   */
  async rejectGroup(
    groupId: string,
    adminId: string,
  ): Promise<GroupResponseDto> {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) {
      throw new NotFoundException('Group not found');
    }

    if (group.status === 'ACTIVE') {
      throw new BadRequestException(
        'Cannot reject an already active group. Suspend it instead.',
      );
    }

    if (group.status === 'REJECTED') {
      throw new BadRequestException('Group is already rejected');
    }

    const updated = await this.groupsRepository.rejectGroup(groupId, adminId);
    const count = group._count?.members ?? 0;

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

  async updateGroup(
    groupId: string,
    dto: UpdateGroupDto,
  ): Promise<GroupResponseDto> {
    await this.groupsRepository.updateGroup(groupId, dto);
    return this.getGroupById(groupId);
  }

  async listPublicActiveGroups(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const { items, total } = await this.groupsRepository.findPublicActiveGroups(
      skip,
      limit,
    );

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
    const { items, total } = await this.groupsRepository.findPendingGroups(
      skip,
      limit,
    );

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

  /**
   * Returns all groups created by the authenticated user, in all statuses.
   * Used by the Flutter Creator Workspace to display accurate group state.
   */
  async listMyGroups(userId: string, page = 1, limit = 50) {
    const skip = (page - 1) * limit;
    const { items, total } = await this.groupsRepository.findMyGroups(
      userId,
      skip,
      limit,
    );

    const data: GroupResponseDto[] = items.map((g) => ({
      id: g.id,
      name: g.name,
      slug: g.slug,
      description: g.description,
      status: g.status,
      visibility: g.visibility,
      createdById: g.createdById,
      approvedById: g.approvedById ?? undefined,
      approvedAt: g.approvedAt ?? undefined,
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

  async inviteUser(
    groupId: string,
    senderId: string,
    recipientId: string,
    role = GroupRole.MEMBER,
  ) {
    const group = await this.groupsRepository.findById(groupId);
    if (!group || group.status !== 'ACTIVE') {
      throw new ForbiddenException('Group must be active to invite members');
    }

    const existingMember = await this.groupsRepository.getMember(
      groupId,
      recipientId,
    );
    if (existingMember) {
      throw new BadRequestException('User is already a member of this group');
    }

    const invite = await this.groupsRepository.createInvite(
      groupId,
      senderId,
      recipientId,
      role,
    );
    return {
      message: 'Invite sent successfully',
      inviteToken: invite.token,
      expiresAt: invite.expiresAt,
    };
  }

  async joinByInvite(token: string, userId: string) {
    const invite = await this.groupsRepository.findInviteByToken(token);
    if (
      !invite ||
      invite.status !== 'PENDING' ||
      invite.expiresAt < new Date()
    ) {
      throw new BadRequestException('Invalid or expired invite token');
    }

    if (invite.recipientId !== userId) {
      throw new ForbiddenException('This invite token was not issued to you');
    }

    await this.groupsRepository.addMember(
      invite.groupId,
      userId,
      invite.role as GroupRole,
    );
    await this.groupsRepository.acceptInvite(invite.id);

    return { message: 'Successfully joined group' };
  }
}
