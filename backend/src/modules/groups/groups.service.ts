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
import {
  GroupCapabilitiesDto,
  GroupContextResponseDto,
  GroupMemberResponseDto,
  VideoChannelSummaryDto,
} from './dto/group-response.dto.js';
import {
  GroupRole,
  GROUP_ROLE_HIERARCHY,
} from '../../common/constants/group-roles.js';
import { AppRole } from '../../common/constants/roles.js';
import { PERMISSIONS } from '../../common/constants/permissions.js';
import { AuthorizationService } from '../authorization/authorization.service.js';
import { UploadsService } from '../uploads/uploads.service.js';

import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class GroupsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly groupsRepository: GroupsRepository,
    private readonly authorizationService: AuthorizationService,
    private readonly uploadsService: UploadsService,
  ) {}

  /**
   * Create a new group.
   * Status is determined by the backend based on authenticated user's role and permissions:
   *  - SUPER_ADMIN → ACTIVE immediately
   *  - ADMIN → ACTIVE immediately
   *  - USER with 'groups.approve' permission → ACTIVE immediately
   *  - All others → PENDING_APPROVAL
   */
  async createGroup(dto: CreateGroupDto, user: any): Promise<GroupResponseDto> {
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
      (user.role as AppRole) === AppRole.ADMIN ||
      dto.visibility === 'PRIVATE' ||
      dto.visibility === 'INVITE_ONLY'
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

  async getGroupById(
    groupId: string,
    callerId?: string,
    callerRole?: AppRole,
  ): Promise<GroupResponseDto> {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) {
      throw new NotFoundException('Group not found');
    }

    const isGlobalAdmin =
      callerRole === AppRole.SUPER_ADMIN || callerRole === AppRole.ADMIN;
    const isCreator = callerId && group.createdById === callerId;

    if (group.status === 'PENDING_APPROVAL' && !isGlobalAdmin && !isCreator) {
      throw new ForbiddenException(
        'This group is pending approval and is only visible to the owner.',
      );
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

  async getGroupBySlug(
    slug: string,
    callerId?: string,
    callerRole?: AppRole,
  ): Promise<GroupResponseDto> {
    const group = await this.groupsRepository.findBySlug(slug);
    if (!group) {
      throw new NotFoundException(`Group with slug '${slug}' not found`);
    }

    const isGlobalAdmin =
      callerRole === AppRole.SUPER_ADMIN || callerRole === AppRole.ADMIN;
    const isCreator = callerId && group.createdById === callerId;

    if (group.status === 'PENDING_APPROVAL' && !isGlobalAdmin && !isCreator) {
      throw new ForbiddenException(
        'This group is pending approval and is only visible to the owner.',
      );
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
    actorId?: string,
    actorRole?: AppRole,
  ): Promise<GroupResponseDto> {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) {
      throw new NotFoundException('Group not found');
    }

    if (actorId) {
      const isGlobalAdmin =
        actorRole === AppRole.SUPER_ADMIN || actorRole === AppRole.ADMIN;
      const isCreator = group.createdById === actorId;
      let isGroupAdmin = false;
      if (!isGlobalAdmin && !isCreator) {
        const member = await this.groupsRepository.getMember(groupId, actorId);
        isGroupAdmin = member?.role === GroupRole.GROUP_ADMIN;
      }

      if (!isGlobalAdmin && !isCreator && !isGroupAdmin) {
        throw new ForbiddenException(
          'You do not have permission to update this group',
        );
      }
    }

    await this.groupsRepository.updateGroup(groupId, dto);
    return this.getGroupById(groupId, actorId, actorRole);
  }

  async deleteGroup(
    groupId: string,
    actorId: string,
    actorRole?: AppRole,
  ): Promise<{ success: boolean; message: string }> {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) {
      throw new NotFoundException('Group not found');
    }

    const isGlobalAdmin =
      actorRole === AppRole.SUPER_ADMIN || actorRole === AppRole.ADMIN;
    const isCreator = group.createdById === actorId;

    let isGroupAdmin = false;
    if (!isGlobalAdmin && !isCreator) {
      const member = await this.groupsRepository.getMember(groupId, actorId);
      isGroupAdmin = member?.role === GroupRole.GROUP_ADMIN;
    }

    if (!isGlobalAdmin && !isCreator && !isGroupAdmin) {
      throw new ForbiddenException(
        'Only the group creator, group admin, or system administrator can delete this group',
      );
    }

    await this.groupsRepository.softDeleteGroup(groupId);
    return { success: true, message: 'Group deleted successfully' };
  }

  async repairGroup(groupId: string) {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) throw new NotFoundException('Group not found');
    await this.groupsRepository.ensureCreatorMembership(
      group.id,
      group.createdById,
    );
    const withChan = await this.groupsRepository.findWithChannels(group.id);
    if (!withChan?.videoChannels || withChan.videoChannels.length === 0) {
      await this.groupsRepository.createDefaultChannel(
        group.id,
        group.name,
        group.slug,
      );
    }
    return { success: true, message: `Group ${groupId} repaired successfully` };
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
    if (!group) {
      throw new NotFoundException('Group not found');
    }
    if (group.status === 'PENDING_APPROVAL') {
      throw new ForbiddenException(
        'Cannot add or invite members to a pending group. Please wait for admin approval.',
      );
    }
    if (group.status !== 'ACTIVE') {
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

  async getOrCreateShareableInviteLink(groupId: string, userId: string) {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) {
      throw new NotFoundException('Group not found');
    }
    const member = await this.groupsRepository.getMember(groupId, userId);
    if (!member) {
      throw new ForbiddenException(
        'You must be a member to share an invite link',
      );
    }

    const invite = await this.groupsRepository.createInvite(
      groupId,
      userId,
      userId, // self-issued shareable token
      GroupRole.MEMBER,
    );

    return {
      groupId: group.id,
      groupName: group.name,
      inviteToken: invite.token,
      inviteLink: `https://streamhub.app/join/group/${invite.token}`,
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

    // Support both direct invites and shareable links (where recipientId == senderId)
    if (
      invite.recipientId !== userId &&
      invite.recipientId !== invite.senderId
    ) {
      throw new ForbiddenException('This invite token was not issued to you');
    }

    const group = await this.groupsRepository.findById(invite.groupId);
    if (!group || group.status !== 'ACTIVE') {
      throw new ForbiddenException(
        'Cannot join a group that is pending approval or inactive',
      );
    }

    await this.groupsRepository.addMember(
      invite.groupId,
      userId,
      invite.role as GroupRole,
    );
    if (invite.recipientId === userId) {
      await this.groupsRepository.acceptInvite(invite.id);
    }

    return {
      message: 'Successfully joined group',
      groupId: group.id,
      groupName: group.name,
    };
  }

  // ─── Group Context Endpoint ──────────────────────────────────────────────

  /**
   * Returns everything the Flutter Group Channel screen needs in a single call:
   * group metadata, active video channels, caller membership role, and a
   * capability map derived entirely on the backend from the role hierarchy.
   *
   * Important: capabilities are display hints only — every API endpoint
   * enforces its own authorization independently.
   */
  async getGroupContext(
    groupId: string,
    callerId: string | undefined,
  ): Promise<GroupContextResponseDto> {
    const group = await this.groupsRepository.findWithChannels(groupId);
    if (!group) throw new NotFoundException('Group not found');

    // Resolve global platform role of caller (null = unauthenticated)
    let globalRole: AppRole | null = null;
    let callerGroupRole: GroupRole | null = null;

    if (callerId) {
      try {
        const roleStr = await this.authorizationService.getUserRole(callerId);
        globalRole = roleStr as AppRole;
      } catch {
        // Treat as unauthenticated if user lookup fails
      }

      if (globalRole !== AppRole.SUPER_ADMIN && globalRole !== AppRole.ADMIN) {
        const member = await this.groupsRepository.getMember(groupId, callerId);
        callerGroupRole = member ? (member.role as GroupRole) : null;
        if (!callerGroupRole && group.createdById === callerId) {
          callerGroupRole = GroupRole.GROUP_ADMIN;
        }
      } else {
        // Admins are treated as GROUP_ADMIN for capability computation
        callerGroupRole = GroupRole.GROUP_ADMIN;
      }
    }

    // ─── Group visibility enforcement ───────────────────────────────────────────
    const isGlobalAdmin =
      globalRole === AppRole.SUPER_ADMIN || globalRole === AppRole.ADMIN;

    const isCreator = Boolean(callerId && group.createdById === callerId);

    if (group.status === 'PENDING_APPROVAL') {
      if (!isGlobalAdmin && !isCreator) {
        throw new ForbiddenException(
          'This group is pending approval and is only visible to the owner.',
        );
      }
    } else if (
      group.status !== 'ACTIVE' &&
      !isGlobalAdmin &&
      !callerGroupRole
    ) {
      throw new ForbiddenException(
        'This group is not available. It may be suspended or archived.',
      );
    }

    if (
      group.visibility === 'PRIVATE' &&
      !isGlobalAdmin &&
      callerGroupRole === null
    ) {
      throw new ForbiddenException(
        'This is a private group. You must be a member to view it.',
      );
    }

    // ─── Capability map ──────────────────────────────────────────────────────────
    const caps = this.computeCapabilities(callerGroupRole, isGlobalAdmin);

    // ─── Video channel resolution ──────────────────────────────────────────────────
    const channels: VideoChannelSummaryDto[] = (group.videoChannels ?? []).map(
      (ch: any) => ({
        id: ch.id,
        name: ch.name,
        slug: ch.slug,
        handle: ch.handle,
        description: ch.description,
        status: ch.status,
        uploadPermission: ch.uploadPermission,
        subscribersCount: ch.subscribersCount ?? 0,
        videosCount: ch.videosCount ?? 0,
      }),
    );

    // If a legacy group has no video channels, auto-provision one on the fly
    if (channels.length === 0) {
      try {
        const newChan = await this.groupsRepository.createDefaultChannel(
          group.id,
          group.name,
          group.slug,
        );
        channels.push({
          id: newChan.id,
          name: newChan.name,
          slug: newChan.slug,
          handle: newChan.handle,
          description: newChan.description,
          status: newChan.status,
          uploadPermission: newChan.uploadPermission,
          subscribersCount: 0,
          videosCount: 0,
        });
      } catch {
        // Non-fatal if auto-provisioning encounters a transient conflict
      }
    }

    // The primary channel is the oldest active channel (sorted asc by createdAt in repository).
    // This gives deterministic resolution regardless of how many channels exist.
    const defaultChannel =
      channels.find((c) => c.status === 'ACTIVE') ?? channels[0] ?? null;

    return {
      id: group.id,
      name: group.name,
      slug: group.slug,
      description: group.description,
      status: group.status,
      visibility: group.visibility,
      membersCount: group._count?.members ?? 0,
      avatarUrl: (group as any).avatarUrl ?? null,
      coverUrl: (group as any).coverUrl ?? null,
      website: (group as any).website ?? null,
      country: (group as any).country ?? null,
      createdById: group.createdById,
      approvedById: group.approvedById ?? null,
      approvedAt: group.approvedAt ?? null,
      createdAt: group.createdAt,
      callerRole: callerGroupRole,
      capabilities: caps,
      videoChannels: channels,
      defaultVideoChannelId: defaultChannel?.id ?? null,
    };
  }

  /**
   * Derives the capability set for a caller based purely on their role
   * in the group hierarchy. Must match the actual enforcement in guards/services.
   */
  private computeCapabilities(
    role: GroupRole | null,
    isGlobalAdmin: boolean,
  ): GroupCapabilitiesDto {
    if (isGlobalAdmin) {
      return {
        canViewGroup: true,
        canUploadVideo: true,
        canManageVideos: true,
        canCreatePlaylist: true,
        canManagePlaylists: true,
        canViewMembers: true,
        canManageMembers: true,
        canEditGroup: true,
        canUpdateGroup: true,
        canDeleteGroup: true,
        canManagePermissions: true,
        canManageChannels: true,
        canManageSettings: true,
        canModerateChat: true,
        canStartLive: true,
        canApproveGroup: true,
        canArchiveGroup: true,
      };
    }

    const level = role ? GROUP_ROLE_HIERARCHY[role] : 0;
    const isGroupAdmin = level >= GROUP_ROLE_HIERARCHY[GroupRole.GROUP_ADMIN];
    const isModerator = level >= GROUP_ROLE_HIERARCHY[GroupRole.MODERATOR];
    const isMember = level >= GROUP_ROLE_HIERARCHY[GroupRole.MEMBER];
    const isGuest = level >= GROUP_ROLE_HIERARCHY[GroupRole.GUEST];

    return {
      canViewGroup: isGuest || isMember, // any member or guest
      canUploadVideo: isMember,
      canManageVideos: isModerator,
      canCreatePlaylist: isModerator,
      canManagePlaylists: isModerator,
      canViewMembers: isModerator,
      canManageMembers: isGroupAdmin,
      canEditGroup: isGroupAdmin,
      canUpdateGroup: isGroupAdmin,
      canDeleteGroup: isGroupAdmin,
      canManagePermissions: isGroupAdmin,
      canManageChannels: isGroupAdmin,
      canManageSettings: isGroupAdmin,
      canModerateChat: isModerator,
      canStartLive: isModerator,
      canApproveGroup: false,
      canArchiveGroup: isGroupAdmin,
    };
  }

  // ─── Member Management ───────────────────────────────────────────────────

  async listMembers(groupId: string, page = 1, limit = 30) {
    const skip = (page - 1) * limit;
    const group = await this.groupsRepository.findById(groupId);
    if (!group) throw new NotFoundException('Group not found');

    const { items, total } = await this.groupsRepository.findMembers(
      groupId,
      skip,
      limit,
    );

    const data: GroupMemberResponseDto[] = items.map((m: any) => ({
      id: m.id,
      userId: m.userId,
      username: m.user.username,
      displayName: m.user.profile?.displayName ?? null,
      role: m.role,
      joinedAt: m.joinedAt,
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
   * Update a group member's role.
   * Rules:
   * - Acting user must be GROUP_ADMIN (or platform ADMIN/SUPER_ADMIN).
   * - A user cannot modify their own role.
   * - A user cannot assign a role equal to or higher than their own group role
   *   (prevents self-promotion and escalation through proxies).
   * - The sole GROUP_ADMIN (the creator) cannot be demoted unless another GROUP_ADMIN exists.
   */
  async updateMemberRole(
    groupId: string,
    actorId: string,
    targetUserId: string,
    newRole: GroupRole,
    actorGlobalRole: AppRole,
  ) {
    if (actorId === targetUserId) {
      throw new ForbiddenException('You cannot change your own role');
    }

    const group = await this.groupsRepository.findById(groupId);
    if (!group) throw new NotFoundException('Group not found');

    // Resolve actor's effective group role
    let actorGroupRole: GroupRole = GroupRole.MEMBER;
    if (
      actorGlobalRole === AppRole.SUPER_ADMIN ||
      actorGlobalRole === AppRole.ADMIN
    ) {
      actorGroupRole = GroupRole.GROUP_ADMIN; // platform admins act as group admin
    } else {
      const actorMember = await this.groupsRepository.getMember(
        groupId,
        actorId,
      );
      if (!actorMember)
        throw new ForbiddenException('You are not a member of this group');
      actorGroupRole = actorMember.role as GroupRole;
      if (actorGroupRole !== GroupRole.GROUP_ADMIN) {
        throw new ForbiddenException(
          'Only GROUP_ADMIN can update member roles',
        );
      }
    }

    // Resolve target's current role
    const targetMember = await this.groupsRepository.getMember(
      groupId,
      targetUserId,
    );
    if (!targetMember)
      throw new NotFoundException('Target user is not a member of this group');

    const targetCurrentRole = targetMember.role as GroupRole;

    // Prevent escalation: actor cannot assign a role above their own
    // (platform admins are exempt from this check)
    if (
      actorGlobalRole !== AppRole.SUPER_ADMIN &&
      actorGlobalRole !== AppRole.ADMIN &&
      GROUP_ROLE_HIERARCHY[newRole] >= GROUP_ROLE_HIERARCHY[actorGroupRole]
    ) {
      throw new ForbiddenException(
        'You cannot assign a role equal to or higher than your own',
      );
    }

    // Prevent demotion of the only GROUP_ADMIN (group creator)
    if (
      targetCurrentRole === GroupRole.GROUP_ADMIN &&
      newRole !== GroupRole.GROUP_ADMIN
    ) {
      // Check if there is at least one other GROUP_ADMIN
      const { items: allMembers } = await this.groupsRepository.findMembers(
        groupId,
        0,
        1000,
      );
      const adminCount = allMembers.filter(
        (m: any) => m.role === GroupRole.GROUP_ADMIN,
      ).length;
      if (adminCount <= 1) {
        throw new ForbiddenException(
          'Cannot demote the last GROUP_ADMIN. Promote another member first.',
        );
      }
    }

    await this.groupsRepository.updateMemberRole(
      groupId,
      targetUserId,
      newRole,
    );
    return {
      message: 'Member role updated successfully',
      userId: targetUserId,
      newRole,
    };
  }

  /**
   * Remove a member from the group.
   * Rules:
   * - Actor must be GROUP_ADMIN (or platform admin).
   * - Actor cannot remove themselves via this endpoint.
   * - The sole GROUP_ADMIN cannot be removed.
   */
  async removeMember(
    groupId: string,
    actorId: string,
    targetUserId: string,
    actorGlobalRole: AppRole,
  ) {
    if (actorId === targetUserId) {
      throw new ForbiddenException(
        'Cannot remove yourself from the group via this endpoint. Use the leave endpoint.',
      );
    }

    const group = await this.groupsRepository.findById(groupId);
    if (!group) throw new NotFoundException('Group not found');

    let actorGroupRole: GroupRole = GroupRole.MEMBER;
    if (
      actorGlobalRole === AppRole.SUPER_ADMIN ||
      actorGlobalRole === AppRole.ADMIN
    ) {
      actorGroupRole = GroupRole.GROUP_ADMIN;
    } else {
      const actorMember = await this.groupsRepository.getMember(
        groupId,
        actorId,
      );
      if (!actorMember)
        throw new ForbiddenException('You are not a member of this group');
      actorGroupRole = actorMember.role as GroupRole;
      if (actorGroupRole !== GroupRole.GROUP_ADMIN) {
        throw new ForbiddenException('Only GROUP_ADMIN can remove members');
      }
    }

    const targetMember = await this.groupsRepository.getMember(
      groupId,
      targetUserId,
    );
    if (!targetMember)
      throw new NotFoundException('Target user is not a member of this group');

    const targetCurrentRole = targetMember.role as GroupRole;

    // Protect the last GROUP_ADMIN
    if (targetCurrentRole === GroupRole.GROUP_ADMIN) {
      const { items: allMembers } = await this.groupsRepository.findMembers(
        groupId,
        0,
        1000,
      );
      const adminCount = allMembers.filter(
        (m: any) => m.role === GroupRole.GROUP_ADMIN,
      ).length;
      if (adminCount <= 1) {
        throw new ForbiddenException(
          'Cannot remove the last GROUP_ADMIN from the group.',
        );
      }
    }

    await this.groupsRepository.removeMember(groupId, targetUserId);
    return { message: 'Member removed successfully' };
  }

  async uploadAvatar(
    groupId: string,
    userId: string,
    file: Express.Multer.File,
  ) {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) throw new NotFoundException('Group not found');

    const member = await this.groupsRepository.getMember(groupId, userId);
    if (
      member?.role !== GroupRole.GROUP_ADMIN &&
      group.createdById !== userId
    ) {
      throw new ForbiddenException('Only group admins can update group avatar');
    }

    return this.uploadsService.uploadGroupAvatar(groupId, userId, file);
  }

  async deleteAvatar(groupId: string, userId: string) {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) throw new NotFoundException('Group not found');

    const member = await this.groupsRepository.getMember(groupId, userId);
    if (
      member?.role !== GroupRole.GROUP_ADMIN &&
      group.createdById !== userId
    ) {
      throw new ForbiddenException('Only group admins can delete group avatar');
    }

    return this.uploadsService.deleteGroupAvatar(groupId);
  }

  async uploadCover(
    groupId: string,
    userId: string,
    file: Express.Multer.File,
  ) {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) throw new NotFoundException('Group not found');

    const member = await this.groupsRepository.getMember(groupId, userId);
    if (
      member?.role !== GroupRole.GROUP_ADMIN &&
      group.createdById !== userId
    ) {
      throw new ForbiddenException('Only group admins can update group cover');
    }

    return this.uploadsService.uploadGroupCover(groupId, userId, file);
  }

  async deleteCover(groupId: string, userId: string) {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) throw new NotFoundException('Group not found');

    const member = await this.groupsRepository.getMember(groupId, userId);
    if (
      member?.role !== GroupRole.GROUP_ADMIN &&
      group.createdById !== userId
    ) {
      throw new ForbiddenException('Only group admins can delete group cover');
    }

    return this.uploadsService.deleteGroupCover(groupId);
  }

  // ─── Telegram-Style Advanced Community Features ─────────────────────────

  async updateSettings(
    groupId: string,
    userId: string,
    dto: { slowModeSeconds?: number; isForum?: boolean; defaultPermissions?: any },
  ) {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) throw new NotFoundException('Group not found');

    const member = await this.groupsRepository.getMember(groupId, userId);
    if (member?.role !== GroupRole.GROUP_ADMIN && group.createdById !== userId) {
      throw new ForbiddenException('Only group administrators can change group settings');
    }

    const updated = await this.prisma.group.update({
      where: { id: groupId },
      data: {
        ...(dto.slowModeSeconds !== undefined ? { slowModeSeconds: dto.slowModeSeconds } : {}),
        ...(dto.isForum !== undefined ? { isForum: dto.isForum } : {}),
        ...(dto.defaultPermissions !== undefined ? { defaultPermissions: dto.defaultPermissions } : {}),
      },
    });

    await this.prisma.groupAuditLog.create({
      data: {
        groupId,
        actorId: userId,
        action: 'SETTINGS_UPDATED',
        details: dto,
      },
    });

    return updated;
  }

  async transferOwnership(groupId: string, actorId: string, newOwnerId: string) {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) throw new NotFoundException('Group not found');

    if (group.createdById !== actorId) {
      throw new ForbiddenException('Only the current group owner can transfer ownership');
    }

    const targetMember = await this.groupsRepository.getMember(groupId, newOwnerId);
    if (!targetMember) {
      throw new BadRequestException('Target user is not a member of this group');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const g = await tx.group.update({
        where: { id: groupId },
        data: { createdById: newOwnerId },
      });

      await tx.groupMember.update({
        where: { groupId_userId: { groupId, userId: newOwnerId } },
        data: { role: GroupRole.GROUP_ADMIN },
      });

      await tx.groupAuditLog.create({
        data: {
          groupId,
          actorId,
          action: 'OWNERSHIP_TRANSFERRED',
          targetId: newOwnerId,
        },
      });

      return g;
    });

    return { message: 'Ownership transferred successfully', group: updated };
  }

  async createTopic(
    groupId: string,
    userId: string,
    dto: { title: string; iconEmoji?: string; color?: number },
  ) {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) throw new NotFoundException('Group not found');

    const member = await this.groupsRepository.getMember(groupId, userId);
    if (!member) {
      throw new ForbiddenException('You must be a member to create a topic');
    }

    const topic = await this.prisma.groupTopic.create({
      data: {
        groupId,
        createdById: userId,
        title: dto.title,
        iconEmoji: dto.iconEmoji,
        color: dto.color,
      },
      include: {
        createdBy: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true, avatarUrl: true } },
          },
        },
      },
    });

    await this.prisma.groupAuditLog.create({
      data: {
        groupId,
        actorId: userId,
        action: 'TOPIC_CREATED',
        targetId: topic.id,
        details: { title: dto.title },
      },
    });

    return topic;
  }

  async listTopics(groupId: string, userId?: string) {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) throw new NotFoundException('Group not found');

    if (group.visibility === 'PRIVATE' && userId) {
      const member = await this.groupsRepository.getMember(groupId, userId);
      if (!member) throw new ForbiddenException('Group is private');
    }

    const topics = await this.prisma.groupTopic.findMany({
      where: { groupId },
      orderBy: [{ isPinned: 'desc' }, { createdAt: 'desc' }],
      include: {
        createdBy: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true, avatarUrl: true } },
          },
        },
        _count: {
          select: { messages: true },
        },
      },
    });

    return topics;
  }

  async updateTopic(
    groupId: string,
    topicId: string,
    userId: string,
    dto: { title?: string; iconEmoji?: string; isClosed?: boolean; isPinned?: boolean },
  ) {
    const member = await this.groupsRepository.getMember(groupId, userId);
    if (!member || (member.role !== GroupRole.GROUP_ADMIN && member.role !== GroupRole.MODERATOR)) {
      throw new ForbiddenException('Only admins or moderators can manage topics');
    }

    return this.prisma.groupTopic.update({
      where: { id: topicId },
      data: dto,
    });
  }

  async deleteTopic(groupId: string, topicId: string, userId: string) {
    const member = await this.groupsRepository.getMember(groupId, userId);
    if (!member || member.role !== GroupRole.GROUP_ADMIN) {
      throw new ForbiddenException('Only group admins can delete topics');
    }

    await this.prisma.groupTopic.delete({ where: { id: topicId } });
    return { message: 'Topic deleted successfully' };
  }

  async createPoll(
    groupId: string,
    userId: string,
    dto: {
      question: string;
      options: string[];
      conversationId?: string;
      isAnonymous?: boolean;
      allowsMultipleAnswers?: boolean;
    },
  ) {
    const member = await this.groupsRepository.getMember(groupId, userId);
    if (!member) throw new ForbiddenException('You must be a member to create a poll');

    if (!dto.options || dto.options.length < 2) {
      throw new BadRequestException('A poll must have at least 2 options');
    }

    const poll = await this.prisma.groupPoll.create({
      data: {
        groupId,
        conversationId: dto.conversationId,
        question: dto.question,
        isAnonymous: dto.isAnonymous ?? false,
        allowsMultipleAnswers: dto.allowsMultipleAnswers ?? false,
        createdById: userId,
        options: {
          create: dto.options.map((text) => ({ text })),
        },
      },
      include: {
        options: true,
        createdBy: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true, avatarUrl: true } },
          },
        },
      },
    });

    return poll;
  }

  async votePoll(pollId: string, userId: string, optionIds: string[]) {
    const poll = await this.prisma.groupPoll.findUnique({
      where: { id: pollId },
      include: { options: true },
    });
    if (!poll) throw new NotFoundException('Poll not found');
    if (poll.isClosed) throw new BadRequestException('This poll is closed');

    if (!poll.allowsMultipleAnswers && optionIds.length > 1) {
      throw new BadRequestException('Multiple votes are not allowed for this poll');
    }

    // Delete existing votes for this user on this poll
    await this.prisma.groupPollVote.deleteMany({
      where: { pollId, userId },
    });

    // Create new votes
    for (const optionId of optionIds) {
      await this.prisma.groupPollVote.create({
        data: { pollId, optionId, userId },
      });
    }

    // Recount votes
    for (const opt of poll.options) {
      const count = await this.prisma.groupPollVote.count({
        where: { optionId: opt.id },
      });
      await this.prisma.groupPollOption.update({
        where: { id: opt.id },
        data: { votesCount: count },
      });
    }

    return this.prisma.groupPoll.findUnique({
      where: { id: pollId },
      include: {
        options: true,
        votes: {
          where: { userId },
        },
      },
    });
  }

  async closePoll(pollId: string, userId: string) {
    const poll = await this.prisma.groupPoll.findUnique({
      where: { id: pollId },
    });
    if (!poll) throw new NotFoundException('Poll not found');

    const member = await this.groupsRepository.getMember(poll.groupId, userId);
    if (poll.createdById !== userId && member?.role !== GroupRole.GROUP_ADMIN) {
      throw new ForbiddenException('Only the poll creator or group admin can close the poll');
    }

    return this.prisma.groupPoll.update({
      where: { id: pollId },
      data: { isClosed: true },
      include: { options: true },
    });
  }

  async getAuditLog(groupId: string, userId: string, page = 1, limit = 50) {
    const member = await this.groupsRepository.getMember(groupId, userId);
    if (!member || (member.role !== GroupRole.GROUP_ADMIN && member.role !== GroupRole.MODERATOR)) {
      throw new ForbiddenException('Only group administrators or moderators can view audit logs');
    }

    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      this.prisma.groupAuditLog.findMany({
        where: { groupId },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          actor: {
            select: {
              id: true,
              username: true,
              profile: { select: { displayName: true, avatarUrl: true } },
            },
          },
        },
      }),
      this.prisma.groupAuditLog.count({ where: { groupId } }),
    ]);

    return { items, total, page, limit };
  }
}
