// src/modules/group-join-requests/group-join-requests.service.ts
import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { GroupJoinRequestsRepository } from './group-join-requests.repository.js';
import { GroupsRepository } from '../groups/groups.repository.js';
import { NotificationsService } from '../notifications/notifications.service.js';
import { CreateJoinRequestDto } from './dto/create-join-request.dto.js';
import { JoinRequestResponseDto } from './dto/join-request-response.dto.js';

@Injectable()
export class GroupJoinRequestsService {
  constructor(
    private readonly joinRequestsRepository: GroupJoinRequestsRepository,
    private readonly groupsRepository: GroupsRepository,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ── Request to join a private group ──────────────────────────────────────

  async requestToJoin(
    groupId: string,
    userId: string,
    dto: CreateJoinRequestDto,
  ): Promise<JoinRequestResponseDto> {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) throw new NotFoundException('Group not found');

    if (group.status === 'PENDING_APPROVAL') {
      throw new ForbiddenException(
        'Cannot request to join a pending group. Please wait for admin approval.',
      );
    }

    if (group.status !== 'ACTIVE') {
      throw new BadRequestException('Group is not active');
    }

    if (group.visibility === 'PUBLIC') {
      throw new BadRequestException(
        'This is a public group — you can join directly without a request',
      );
    }

    // Check if already a member
    const existingMember = await this.groupsRepository.getMember(
      groupId,
      userId,
    );
    if (existingMember) {
      throw new BadRequestException('You are already a member of this group');
    }

    // Check for duplicate pending request
    const pending = await this.joinRequestsRepository.findPendingByGroupAndUser(
      groupId,
      userId,
    );
    if (pending) {
      throw new BadRequestException(
        'You already have a pending join request for this group',
      );
    }

    const request = await this.joinRequestsRepository.create(
      groupId,
      userId,
      dto.note,
    );

    // Notify group admins
    const groupAdmins = await this.getGroupAdmins(groupId);
    await Promise.all(
      groupAdmins.map((adminId) =>
        this.notificationsService.notifyGroupJoinRequest(
          adminId,
          request.user.username ?? 'A user',
          groupId,
        ),
      ),
    );

    return this.mapToDto(request);
  }

  // ── List pending requests for a group (group admin only) ──────────────────

  async getPendingRequests(
    groupId: string,
    requestingUserId: string,
  ): Promise<JoinRequestResponseDto[]> {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) throw new NotFoundException('Group not found');

    const member = await this.groupsRepository.getMember(
      groupId,
      requestingUserId,
    );
    if (!member || !['GROUP_ADMIN', 'MODERATOR'].includes(member.role)) {
      throw new ForbiddenException('Only group admins can view join requests');
    }

    const requests =
      await this.joinRequestsRepository.findPendingByGroup(groupId);
    return requests.map((r) => this.mapToDto(r));
  }

  // ── Get my own join requests ───────────────────────────────────────────────

  async getMyRequests(userId: string): Promise<JoinRequestResponseDto[]> {
    const requests = await this.joinRequestsRepository.findByUser(userId);
    return requests.map((r) => this.mapToDto(r));
  }

  // ── Approve a join request ─────────────────────────────────────────────────

  async approveRequest(
    requestId: string,
    approverId: string,
  ): Promise<JoinRequestResponseDto> {
    const request = await this.joinRequestsRepository.findById(requestId);
    if (!request) throw new NotFoundException('Join request not found');
    if (request.status !== 'PENDING') {
      throw new BadRequestException('Request has already been processed');
    }

    // Verify approver is group admin
    const member = await this.groupsRepository.getMember(
      request.groupId,
      approverId,
    );
    if (!member || !['GROUP_ADMIN', 'MODERATOR'].includes(member.role)) {
      throw new ForbiddenException(
        'Only group admins can approve join requests',
      );
    }

    // Add user to the group
    await this.groupsRepository.addMember(request.groupId, request.userId);

    // Update request status
    const approved = await this.joinRequestsRepository.approve(requestId);

    // Notify the user
    const group = await this.groupsRepository.findById(request.groupId);
    await this.notificationsService.notifyGroupApprove(
      request.userId,
      group?.name ?? 'the group',
      request.groupId,
    );

    return this.mapToDto(approved);
  }

  // ── Reject a join request ──────────────────────────────────────────────────

  async rejectRequest(
    requestId: string,
    rejecterId: string,
  ): Promise<JoinRequestResponseDto> {
    const request = await this.joinRequestsRepository.findById(requestId);
    if (!request) throw new NotFoundException('Join request not found');
    if (request.status !== 'PENDING') {
      throw new BadRequestException('Request has already been processed');
    }

    const member = await this.groupsRepository.getMember(
      request.groupId,
      rejecterId,
    );
    if (!member || !['GROUP_ADMIN', 'MODERATOR'].includes(member.role)) {
      throw new ForbiddenException(
        'Only group admins can reject join requests',
      );
    }

    const rejected = await this.joinRequestsRepository.reject(requestId);
    return this.mapToDto(rejected);
  }

  // ── Helper: get group admin user IDs ─────────────────────────────────────

  private async getGroupAdmins(groupId: string): Promise<string[]> {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) return [];
    // createdBy is always an admin
    return [group.createdById];
  }

  // ── Mapper ─────────────────────────────────────────────────────────────────

  private mapToDto(r: any): JoinRequestResponseDto {
    return {
      id: r.id,
      groupId: r.groupId,
      userId: r.userId,
      username: r.user?.username ?? '',
      displayName: r.user?.profile?.displayName ?? undefined,
      avatarUrl: r.user?.profile?.avatar?.url ?? undefined,
      status: r.status,
      note: r.note ?? undefined,
      createdAt: r.createdAt,
      respondedAt: r.respondedAt ?? undefined,
    };
  }
}
