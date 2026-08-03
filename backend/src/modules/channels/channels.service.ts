// src/modules/channels/channels.service.ts
import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ChannelsRepository } from './channels.repository.js';
import { CreateChannelDto } from './dto/create-channel.dto.js';
import { UpdateChannelDto } from './dto/update-channel.dto.js';
import { ChannelResponseDto } from './dto/channel-response.dto.js';
import { GroupsRepository } from '../groups/groups.repository.js';

@Injectable()
export class ChannelsService {
  constructor(
    private readonly channelsRepository: ChannelsRepository,
    private readonly groupsRepository: GroupsRepository,
  ) {}

  async createChannel(
    groupId: string,
    dto: CreateChannelDto,
  ): Promise<ChannelResponseDto> {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) {
      throw new NotFoundException('Group not found');
    }

    if (group.status !== 'ACTIVE') {
      throw new ForbiddenException('Group must be ACTIVE to create channels');
    }

    const existingSlug = await this.channelsRepository.findBySlug(
      groupId,
      dto.slug,
    );
    if (existingSlug) {
      throw new BadRequestException(
        `Channel with slug '${dto.slug}' already exists in this group`,
      );
    }

    const channel = await this.channelsRepository.createChannel(groupId, dto);
    return this.mapToDto(channel);
  }

  async getChannelsByGroup(
    groupId: string,
    userId: string,
  ): Promise<ChannelResponseDto[]> {
    const group = await this.groupsRepository.findById(groupId);
    if (!group) {
      throw new NotFoundException('Group not found');
    }

    const member = await this.groupsRepository.getMember(groupId, userId);
    // If not a group member, only show public channels
    const isMember = !!member;
    const channels = await this.channelsRepository.findByGroup(
      groupId,
      isMember ? undefined : false,
    );

    return channels.map((ch) => this.mapToDto(ch));
  }

  async getChannelById(
    channelId: string,
    userId: string,
  ): Promise<ChannelResponseDto> {
    const channel = await this.channelsRepository.findById(channelId);
    if (!channel) {
      throw new NotFoundException('Channel not found');
    }

    if (channel.isPrivate) {
      const member = await this.groupsRepository.getMember(
        channel.groupId,
        userId,
      );
      if (!member) {
        throw new ForbiddenException(
          'Private channel access requires group membership',
        );
      }
    }

    return this.mapToDto(channel);
  }

  async updateChannel(
    channelId: string,
    dto: UpdateChannelDto,
  ): Promise<ChannelResponseDto> {
    const channel = await this.channelsRepository.findById(channelId);
    if (!channel) {
      throw new NotFoundException('Channel not found');
    }

    const updated = await this.channelsRepository.updateChannel(channelId, dto);
    return this.mapToDto(updated);
  }

  async deleteChannel(channelId: string) {
    const channel = await this.channelsRepository.findById(channelId);
    if (!channel) {
      throw new NotFoundException('Channel not found');
    }

    await this.channelsRepository.softDeleteChannel(channelId);
    return { message: 'Channel deleted successfully' };
  }

  private mapToDto(channel: any): ChannelResponseDto {
    return {
      id: channel.id,
      groupId: channel.groupId,
      name: channel.name,
      slug: channel.slug,
      type: channel.type,
      description: channel.description,
      isPrivate: channel.isPrivate,
      conversationId:
        channel.conversations?.[0]?.id ?? channel.conversationId ?? null,
      createdAt: channel.createdAt,
    };
  }
}
