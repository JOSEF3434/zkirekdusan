// src/modules/group-join-requests/group-join-requests.controller.ts
import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { GroupJoinRequestsService } from './group-join-requests.service.js';
import { CreateJoinRequestDto } from './dto/create-join-request.dto.js';
import { JoinRequestResponseDto } from './dto/join-request-response.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Group Join Requests')
@ApiBearerAuth()
@Controller()
export class GroupJoinRequestsController {
  constructor(
    private readonly groupJoinRequestsService: GroupJoinRequestsService,
  ) {}

  // ── Request to join a group ───────────────────────────────────────────────
  @Post('groups/:groupId/join-requests')
  @ApiOperation({ summary: 'Request to join a private group' })
  @ApiResponse({ status: 201, type: JoinRequestResponseDto })
  async requestToJoin(
    @Param('groupId') groupId: string,
    @Body() dto: CreateJoinRequestDto,
    @CurrentUser('sub') userId: string,
  ): Promise<JoinRequestResponseDto> {
    return this.groupJoinRequestsService.requestToJoin(groupId, userId, dto);
  }

  // ── List pending requests (group admin) ───────────────────────────────────
  @Get('groups/:groupId/join-requests')
  @ApiOperation({ summary: 'List pending join requests for a group (GROUP_ADMIN/MODERATOR)' })
  @ApiResponse({ status: 200, type: [JoinRequestResponseDto] })
  async getPendingRequests(
    @Param('groupId') groupId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<JoinRequestResponseDto[]> {
    return this.groupJoinRequestsService.getPendingRequests(groupId, userId);
  }

  // ── My own requests ────────────────────────────────────────────────────────
  @Get('join-requests/my')
  @ApiOperation({ summary: 'Get my own join requests' })
  @ApiResponse({ status: 200, type: [JoinRequestResponseDto] })
  async getMyRequests(
    @CurrentUser('sub') userId: string,
  ): Promise<JoinRequestResponseDto[]> {
    return this.groupJoinRequestsService.getMyRequests(userId);
  }

  // ── Approve ────────────────────────────────────────────────────────────────
  @Patch('join-requests/:requestId/approve')
  @ApiOperation({ summary: 'Approve a join request (GROUP_ADMIN/MODERATOR)' })
  @ApiResponse({ status: 200, type: JoinRequestResponseDto })
  async approveRequest(
    @Param('requestId') requestId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<JoinRequestResponseDto> {
    return this.groupJoinRequestsService.approveRequest(requestId, userId);
  }

  // ── Reject ─────────────────────────────────────────────────────────────────
  @Patch('join-requests/:requestId/reject')
  @ApiOperation({ summary: 'Reject a join request (GROUP_ADMIN/MODERATOR)' })
  @ApiResponse({ status: 200, type: JoinRequestResponseDto })
  async rejectRequest(
    @Param('requestId') requestId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<JoinRequestResponseDto> {
    return this.groupJoinRequestsService.rejectRequest(requestId, userId);
  }
}
