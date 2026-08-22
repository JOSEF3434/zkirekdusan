// src/modules/groups/groups.controller.ts
import {
  Body,
  Controller,
  DefaultValuePipe,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { GroupsService } from './groups.service.js';
import { CreateGroupDto } from './dto/create-group.dto.js';
import { UpdateGroupDto } from './dto/update-group.dto.js';
import { InviteMemberDto } from './dto/invite-member.dto.js';
import { UpdateMemberRoleDto } from './dto/update-member-role.dto.js';
import { GroupResponseDto, GroupContextResponseDto } from './dto/group-response.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { Public } from '../../common/decorators/public.decorator.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { GroupRoles } from '../../common/decorators/group-roles.decorator.js';
import { GroupMembershipGuard } from '../../common/guards/group-membership.guard.js';
import { AppRole } from '../../common/constants/roles.js';
import { GroupRole } from '../../common/constants/group-roles.js';
import type { JwtPayload } from '../../common/interfaces/jwt-payload.interface.js';


@ApiTags('Groups')
@ApiBearerAuth()
@Controller('groups')
export class GroupsController {
  constructor(private readonly groupsService: GroupsService) {}

  @Post()
  @ApiOperation({
    summary: 'Create a new group',
    description:
      'Creates a new group. SUPER_ADMIN/ADMIN and users with groups.approve permission get ACTIVE status immediately. Others get PENDING_APPROVAL.',
  })
  @ApiResponse({ status: 201, type: GroupResponseDto })
  async createGroup(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateGroupDto,
  ): Promise<GroupResponseDto> {
    return this.groupsService.createGroup(dto, user);
  }

  @Get('my-groups')
  @ApiOperation({ summary: "List authenticated user's own groups (all statuses)" })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 50 })
  async listMyGroups(
    @CurrentUser('sub') userId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number,
  ) {
    return this.groupsService.listMyGroups(userId, page, limit);
  }

  @Public()
  @Get()
  @ApiOperation({ summary: 'List active public groups' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async listActiveGroups(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.groupsService.listPublicActiveGroups(page, limit);
  }

  @Get('pending')
  @Roles(AppRole.ADMIN, AppRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'List groups awaiting approval (Admin only)' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async listPendingGroups(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.groupsService.listPendingGroups(page, limit);
  }

  @Patch(':groupId/approve')
  @Roles(AppRole.ADMIN, AppRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Approve a pending group (Admin only)' })
  @ApiResponse({ status: 200, type: GroupResponseDto })
  async approveGroup(
    @Param('groupId') groupId: string,
    @CurrentUser('sub') adminId: string,
  ): Promise<GroupResponseDto> {
    return this.groupsService.approveGroup(groupId, adminId);
  }

  @Patch(':groupId/reject')
  @Roles(AppRole.ADMIN, AppRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Reject a pending group (Admin only)' })
  @ApiResponse({ status: 200, type: GroupResponseDto })
  async rejectGroup(
    @Param('groupId') groupId: string,
    @CurrentUser('sub') adminId: string,
  ): Promise<GroupResponseDto> {
    return this.groupsService.rejectGroup(groupId, adminId);
  }

  @Get(':groupId')
  @ApiOperation({ summary: 'Get group details by ID' })
  @ApiResponse({ status: 200, type: GroupResponseDto })
  async getGroupById(
    @Param('groupId') groupId: string,
    @CurrentUser() user?: JwtPayload,
  ): Promise<GroupResponseDto> {
    return this.groupsService.getGroupById(
      groupId,
      user?.sub,
      user?.role as AppRole,
    );
  }

  @Patch(':groupId')
  @UseGuards(GroupMembershipGuard)
  @GroupRoles(GroupRole.GROUP_ADMIN)
  @ApiOperation({ summary: 'Update group settings (GROUP_ADMIN or Creator only)' })
  async updateGroup(
    @Param('groupId') groupId: string,
    @CurrentUser() actor: JwtPayload,
    @Body() dto: UpdateGroupDto,
  ): Promise<GroupResponseDto> {
    return this.groupsService.updateGroup(
      groupId,
      dto,
      actor?.sub,
      actor?.role as AppRole,
    );
  }

  @Delete(':groupId')
  @UseGuards(GroupMembershipGuard)
  @GroupRoles(GroupRole.GROUP_ADMIN)
  @ApiOperation({ summary: 'Delete group (GROUP_ADMIN, Creator, or Admin only)' })
  async deleteGroup(
    @Param('groupId') groupId: string,
    @CurrentUser() actor: JwtPayload,
  ) {
    return this.groupsService.deleteGroup(
      groupId,
      actor.sub,
      actor.role as AppRole,
    );
  }

  @Post(':groupId/repair')
  @ApiOperation({ summary: 'Repair group creator membership and channels' })
  async repairGroup(
    @Param('groupId') groupId: string,
  ) {
    return this.groupsService.repairGroup(groupId);
  }

  @Post(':groupId/members/invite')
  @UseGuards(GroupMembershipGuard)
  @GroupRoles(GroupRole.MODERATOR)
  @ApiOperation({
    summary: 'Invite a user to group (MODERATOR or GROUP_ADMIN)',
  })
  async inviteUser(
    @Param('groupId') groupId: string,
    @CurrentUser('sub') senderId: string,
    @Body() dto: InviteMemberDto,
  ) {
    return this.groupsService.inviteUser(
      groupId,
      senderId,
      dto.recipientId,
      dto.role,
    );
  }

  @Post('invites/:token/join')
  @ApiOperation({ summary: 'Join group using an invitation token' })
  async joinByInvite(
    @Param('token') token: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.groupsService.joinByInvite(token, userId);
  }

  // ─── Group Context ───────────────────────────────────────────────────────────

  /**
   * Returns the full group context needed to render the Group Channel screen.
   * Public groups: any authenticated or unauthenticated caller may request.
   * Private groups: caller must be a member.
   * Non-ACTIVE groups: only ADMIN/SUPER_ADMIN.
   */
  @Get(':groupId/context')
  @ApiOperation({
    summary: 'Get full group context (channels, caller capabilities)',
    description:
      'Single call that provides group metadata, available video channels, default channel, caller role, and capability flags. Enforces visibility/status rules on the backend.',
  })
  @ApiResponse({ status: 200, type: GroupContextResponseDto })
  async getGroupContext(
    @Param('groupId') groupId: string,
    @CurrentUser() user: JwtPayload | null,
  ): Promise<GroupContextResponseDto> {
    // callerId may be undefined if the route is accessed without a token
    const callerId = user?.sub ?? undefined;
    return this.groupsService.getGroupContext(groupId, callerId);
  }

  // ─── Member Management ───────────────────────────────────────────────────────

  @Get(':groupId/members')
  @UseGuards(GroupMembershipGuard)
  @GroupRoles(GroupRole.MODERATOR)
  @ApiOperation({ summary: 'List group members (MODERATOR or higher)' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 30 })
  async listMembers(
    @Param('groupId') groupId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(30), ParseIntPipe) limit: number,
  ) {
    return this.groupsService.listMembers(groupId, page, limit);
  }

  @Patch(':groupId/members/:userId/role')
  @ApiOperation({
    summary: 'Update a member role (GROUP_ADMIN only). Prevents privilege escalation.',
  })
  async updateMemberRole(
    @Param('groupId') groupId: string,
    @Param('userId') targetUserId: string,
    @CurrentUser() actor: JwtPayload,
    @Body() dto: UpdateMemberRoleDto,
  ) {
    return this.groupsService.updateMemberRole(
      groupId,
      actor.sub,
      targetUserId,
      dto.role,
      actor.role as AppRole,
    );
  }

  @Delete(':groupId/members/:userId')
  @ApiOperation({
    summary: 'Remove a member from the group (GROUP_ADMIN only).',
  })
  async removeMember(
    @Param('groupId') groupId: string,
    @Param('userId') targetUserId: string,
    @CurrentUser() actor: JwtPayload,
  ) {
    return this.groupsService.removeMember(
      groupId,
      actor.sub,
      targetUserId,
      actor.role as AppRole,
    );
  }
}

