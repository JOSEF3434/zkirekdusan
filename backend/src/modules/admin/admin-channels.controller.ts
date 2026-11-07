import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { PermissionsGuard } from '../../common/guards/permissions.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { Permissions } from '../../common/decorators/permissions.decorator.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { PrismaService } from '../../prisma/prisma.service.js';
import { AdminAuditService } from './services/admin-audit.service.js';
import { NotificationsService } from '../notifications/notifications.service.js';

@ApiTags('Admin Channels')
@Controller('admin/channels')
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN, AppRole.MODERATOR)
@ApiBearerAuth()
export class AdminChannelsController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AdminAuditService,
    private readonly notificationsService: NotificationsService,
  ) {}

  @Get()
  @Permissions('channels.view')
  @ApiOperation({
    summary: 'List YouTube-style broadcasting channels with pagination, search, and status filters',
  })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['ALL', 'PENDING', 'APPROVED', 'ACTIVE', 'REJECTED', 'SUSPENDED', 'DISABLED'],
  })
  async getChannels(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('search') search?: string,
    @Query('status') status?: string,
  ) {
    const pageNum = Math.max(1, Number(page) || 1);
    const limitNum = Math.min(100, Math.max(1, Number(limit) || 20));
    const skip = (pageNum - 1) * limitNum;

    const where: any = { deletedAt: null };

    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { handle: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (status && status !== 'ALL') {
      where.status = status;
    }

    const [items, total] = await Promise.all([
      this.prisma.videoChannel.findMany({
        where,
        skip,
        take: limitNum,
        orderBy: [
          { createdAt: 'desc' },
        ],
        include: {
          avatarFile: { select: { url: true } },
          bannerFile: { select: { url: true } },
          owner: {
            select: {
              id: true,
              username: true,
              profile: { select: { displayName: true, avatarUrl: true } },
            },
          },
          reviewedBy: {
            select: {
              id: true,
              username: true,
              profile: { select: { displayName: true } },
            },
          },
          group: {
            select: { id: true, name: true, slug: true },
          },
          _count: {
            select: {
              videos: true,
              subscriptions: true,
              liveStreams: true,
              communityPosts: true,
            },
          },
        },
      }),
      this.prisma.videoChannel.count({ where }),
    ]);

    return {
      items: items.map((c) => ({
        id: c.id,
        name: c.name,
        handle: c.handle,
        slug: c.slug,
        description: c.description,
        status: c.status,
        visibility: c.visibility,
        isVerified: c.isVerified,
        subscribersCount: c.subscribersCount,
        videosCount: c.videosCount,
        totalViewsCount: Number(c.totalViewsCount ?? 0),
        avatarUrl: c.avatarFile?.url ?? null,
        bannerUrl: c.bannerFile?.url ?? null,
        owner: c.owner
          ? {
              id: c.owner.id,
              username: c.owner.username,
              displayName: c.owner.profile?.displayName ?? c.owner.username,
              avatarUrl: c.owner.profile?.avatarUrl,
            }
          : null,
        reviewedBy: c.reviewedBy
          ? {
              id: c.reviewedBy.id,
              username: c.reviewedBy.username,
              displayName: c.reviewedBy.profile?.displayName ?? c.reviewedBy.username,
            }
          : null,
        reviewedAt: c.reviewedAt,
        rejectionReason: c.rejectionReason,
        group: c.group,
        counts: c._count,
        createdAt: c.createdAt,
      })),
      total,
      page: pageNum,
      limit: limitNum,
      totalPages: Math.ceil(total / limitNum),
      hasNext: pageNum * limitNum < total,
    };
  }

  @Get(':id')
  @Permissions('channels.view')
  @ApiOperation({ summary: 'Get detailed inspection of a channel for admin' })
  async getChannelDetail(@Param('id') id: string) {
    const channel = await this.prisma.videoChannel.findUnique({
      where: { id },
      include: {
        avatarFile: { select: { url: true } },
        bannerFile: { select: { url: true } },
        owner: {
          select: {
            id: true,
            email: true,
            username: true,
            profile: { select: { displayName: true, avatarUrl: true } },
          },
        },
        reviewedBy: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true } },
          },
        },
        group: { select: { id: true, name: true, slug: true } },
        _count: {
          select: {
            videos: true,
            subscriptions: true,
            liveStreams: true,
            communityPosts: true,
          },
        },
      },
    });

    if (!channel) throw new NotFoundException(`Channel ${id} not found`);

    return {
      ...channel,
      totalViewsCount: Number(channel.totalViewsCount ?? 0),
      avatarUrl: channel.avatarFile?.url ?? null,
      bannerUrl: channel.bannerFile?.url ?? null,
    };
  }

  @Post(':id/approve')
  @Permissions('channels.manage_members')
  @ApiOperation({ summary: 'Approve a pending channel request' })
  async approveChannel(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { notes?: string },
  ) {
    const channel = await this.prisma.videoChannel.findUnique({ where: { id } });
    if (!channel) throw new NotFoundException(`Channel ${id} not found`);

    const updated = await this.prisma.videoChannel.update({
      where: { id },
      data: {
        status: 'APPROVED',
        reviewedById: actorId,
        reviewedAt: new Date(),
        rejectionReason: null,
        reviewNotes: body?.notes,
      },
    });

    await this.auditService.log({
      actorId,
      action: 'CHANNEL_APPROVED',
      targetType: 'CHANNEL',
      targetId: id,
      reason: body?.notes,
    });

    // Notify channel creator/owner
    if (channel.ownerId) {
      await this.notificationsService.notifyChannelStatus(
        channel.ownerId,
        channel.name,
        channel.id,
        'APPROVED',
      );
    }

    return updated;
  }

  @Post(':id/reject')
  @Permissions('channels.manage_members')
  @ApiOperation({ summary: 'Reject a pending channel request with reason' })
  async rejectChannel(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body: { reason: string },
  ) {
    if (!body?.reason || body.reason.trim().length === 0) {
      throw new BadRequestException('Rejection reason is required');
    }

    const channel = await this.prisma.videoChannel.findUnique({ where: { id } });
    if (!channel) throw new NotFoundException(`Channel ${id} not found`);

    const updated = await this.prisma.videoChannel.update({
      where: { id },
      data: {
        status: 'REJECTED',
        reviewedById: actorId,
        reviewedAt: new Date(),
        rejectionReason: body.reason,
      },
    });

    await this.auditService.log({
      actorId,
      action: 'CHANNEL_REJECTED',
      targetType: 'CHANNEL',
      targetId: id,
      reason: body.reason,
    });

    // Notify channel owner
    if (channel.ownerId) {
      await this.notificationsService.notifyChannelStatus(
        channel.ownerId,
        channel.name,
        channel.id,
        'REJECTED',
        body.reason,
      );
    }

    return updated;
  }

  @Post(':id/suspend')
  @Permissions('channels.manage_members')
  @ApiOperation({ summary: 'Suspend an active channel' })
  async suspendChannel(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    const channel = await this.prisma.videoChannel.findUnique({ where: { id } });
    if (!channel) throw new NotFoundException(`Channel ${id} not found`);

    const updated = await this.prisma.videoChannel.update({
      where: { id },
      data: {
        status: 'SUSPENDED',
        reviewedById: actorId,
        reviewedAt: new Date(),
        rejectionReason: body?.reason,
      },
    });

    await this.auditService.log({
      actorId,
      action: 'CHANNEL_SUSPENDED',
      targetType: 'CHANNEL',
      targetId: id,
      reason: body?.reason,
    });

    if (channel.ownerId) {
      await this.notificationsService.notifyChannelStatus(
        channel.ownerId,
        channel.name,
        channel.id,
        'SUSPENDED',
        body?.reason,
      );
    }

    return updated;
  }

  @Post(':id/activate')
  @Permissions('channels.manage_members')
  @ApiOperation({ summary: 'Reactivate or activate a channel' })
  async activateChannel(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
  ) {
    const channel = await this.prisma.videoChannel.findUnique({ where: { id } });
    if (!channel) throw new NotFoundException(`Channel ${id} not found`);

    const updated = await this.prisma.videoChannel.update({
      where: { id },
      data: {
        status: 'ACTIVE',
        reviewedById: actorId,
        reviewedAt: new Date(),
        rejectionReason: null,
      },
    });

    await this.auditService.log({
      actorId,
      action: 'CHANNEL_ACTIVATED',
      targetType: 'CHANNEL',
      targetId: id,
    });

    if (channel.ownerId) {
      await this.notificationsService.notifyChannelStatus(
        channel.ownerId,
        channel.name,
        channel.id,
        'ACTIVE',
      );
    }

    return updated;
  }

  @Delete(':id')
  @Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
  @Permissions('channels.delete')
  @ApiOperation({ summary: 'Delete channel permanently' })
  async deleteChannel(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    const channel = await this.prisma.videoChannel.findUnique({ where: { id } });
    if (!channel) throw new NotFoundException(`Channel ${id} not found`);

    await this.prisma.videoChannel.update({
      where: { id },
      data: { deletedAt: new Date(), status: 'DISABLED' },
    });

    await this.auditService.log({
      actorId,
      action: 'CHANNEL_DELETED',
      targetType: 'CHANNEL',
      targetId: id,
      before: { name: channel.name, handle: channel.handle },
      reason: body?.reason,
    });

    return { success: true, message: 'Channel deleted successfully' };
  }
}
