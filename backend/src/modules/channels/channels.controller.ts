// src/modules/channels/channels.controller.ts
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { ChannelsService } from './channels.service.js';
import { CreateChannelDto } from './dto/create-channel.dto.js';
import { UpdateChannelDto } from './dto/update-channel.dto.js';
import { ChannelResponseDto } from './dto/channel-response.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { GroupMembershipGuard } from '../../common/guards/group-membership.guard.js';
import { GroupRoles } from '../../common/decorators/group-roles.decorator.js';
import { GroupRole } from '../../common/constants/group-roles.js';

@ApiTags('Group Channels')
@ApiBearerAuth()
@Controller('groups/:groupId/channels')
export class ChannelsController {
  constructor(private readonly channelsService: ChannelsService) {}

  @Post()
  @UseGuards(GroupMembershipGuard)
  @GroupRoles(GroupRole.GROUP_ADMIN, GroupRole.MODERATOR)
  @ApiOperation({
    summary: 'Create a channel in a group (GROUP_ADMIN or MODERATOR)',
  })
  @ApiResponse({ status: 201, type: ChannelResponseDto })
  async createChannel(
    @Param('groupId') groupId: string,
    @Body() dto: CreateChannelDto,
  ): Promise<ChannelResponseDto> {
    return this.channelsService.createChannel(groupId, dto);
  }

  @Get()
  @ApiOperation({ summary: 'List all channels in a group' })
  @ApiResponse({ status: 200, type: [ChannelResponseDto] })
  async getChannelsByGroup(
    @Param('groupId') groupId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<ChannelResponseDto[]> {
    return this.channelsService.getChannelsByGroup(groupId, userId);
  }

  @Get(':channelId')
  @ApiOperation({ summary: 'Get channel details' })
  @ApiResponse({ status: 200, type: ChannelResponseDto })
  async getChannelById(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<ChannelResponseDto> {
    return this.channelsService.getChannelById(channelId, userId);
  }

  @Patch(':channelId')
  @UseGuards(GroupMembershipGuard)
  @GroupRoles(GroupRole.GROUP_ADMIN, GroupRole.MODERATOR)
  @ApiOperation({ summary: 'Update channel (GROUP_ADMIN or MODERATOR)' })
  @ApiResponse({ status: 200, type: ChannelResponseDto })
  async updateChannel(
    @Param('channelId') channelId: string,
    @Body() dto: UpdateChannelDto,
  ): Promise<ChannelResponseDto> {
    return this.channelsService.updateChannel(channelId, dto);
  }

  @Delete(':channelId')
  @UseGuards(GroupMembershipGuard)
  @GroupRoles(GroupRole.GROUP_ADMIN)
  @ApiOperation({ summary: 'Delete channel (GROUP_ADMIN only)' })
  @ApiResponse({ status: 200, description: 'Channel deleted' })
  async deleteChannel(@Param('channelId') channelId: string) {
    return this.channelsService.deleteChannel(channelId);
  }
}
