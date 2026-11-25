import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { AdminAuditService } from '../admin/services/admin-audit.service.js';
import {
  CreateSystemReportDto,
  ServiceCostItemDto,
} from './dto/create-system-report.dto.js';
import { UpdateSystemReportDto } from './dto/update-system-report.dto.js';
import { UpdateVisibilityDto } from './dto/update-visibility.dto.js';
import {
  CreateServiceCostDto,
  UpdateServiceCostDto,
} from './dto/service-cost.dto.js';
import {
  PublicSystemReportDto,
  PublicServerInfoDto,
  PublicDatabaseInfoDto,
  PublicApiInfoDto,
  PublicDeploymentInfoDto,
  PublicCostItemDto,
  PlatformOverviewDto,
  PlatformOverviewTopVideoDto,
} from './dto/public-system-report.dto.js';
import {
  SystemReport,
  SystemReportStatus,
  SystemReportDisplayMode,
  SystemServiceCost,
} from '@prisma/client';

@Injectable()
export class SystemReportService {
  private readonly logger = new Logger(SystemReportService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AdminAuditService,
  ) {}

  /**
   * Retrieves the most recent report or automatically initializes a default draft
   * if no report has been created yet.
   */
  async getLatestOrCreate(adminId?: string): Promise<SystemReport & { costs: SystemServiceCost[] }> {
    let report = await this.prisma.systemReport.findFirst({
      orderBy: { createdAt: 'desc' },
      include: {
        costs: {
          orderBy: { createdAt: 'asc' },
        },
        createdBy: {
          select: { id: true, username: true, email: true },
        },
        updatedBy: {
          select: { id: true, username: true, email: true },
        },
      },
    });

    if (!report) {
      this.logger.log('No system report found. Initializing initial draft report.');
      report = await this.prisma.systemReport.create({
        data: {
          title: 'Zikre Kedusan Infrastructure & System Report',
          summary: 'Platform infrastructure, hosting details, and service operational status.',
          status: SystemReportStatus.DRAFT,
          revision: 1,
          enableUserVisibility: false,
          displayMode: SystemReportDisplayMode.SETTINGS_ONLY,
          createdById: adminId,
          updatedById: adminId,
        },
        include: {
          costs: true,
          createdBy: {
            select: { id: true, username: true, email: true },
          },
          updatedBy: {
            select: { id: true, username: true, email: true },
          },
        },
      });

      if (adminId) {
        await this.audit.emit({
          actorId: adminId,
          action: 'SYSTEM_REPORT_INITIALIZED',
          resource: 'SYSTEM_REPORT',
          targetType: 'SYSTEM_REPORT',
          targetId: report.id,
          after: { title: report.title, status: report.status },
        });
      }
    }

    return report;
  }

  /**
   * Retrieves a specific report by ID for administrative management.
   */
  async getAdminReportById(id: string): Promise<SystemReport & { costs: SystemServiceCost[] }> {
    const report = await this.prisma.systemReport.findUnique({
      where: { id },
      include: {
        costs: {
          orderBy: { createdAt: 'asc' },
        },
        createdBy: {
          select: { id: true, username: true, email: true },
        },
        updatedBy: {
          select: { id: true, username: true, email: true },
        },
      },
    });

    if (!report) {
      throw new NotFoundException(`System report with ID ${id} not found`);
    }

    return report;
  }

  /**
   * Lists all system reports (history / revisions).
   */
  async getAllReports() {
    return this.prisma.systemReport.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        costs: true,
        createdBy: {
          select: { id: true, username: true, email: true },
        },
        updatedBy: {
          select: { id: true, username: true, email: true },
        },
      },
    });
  }

  /**
   * Creates a new draft system report.
   */
  async createReport(adminId: string, dto: CreateSystemReportDto) {
    const { costs, lastDeploymentDate, ...data } = dto;

    const report = await this.prisma.systemReport.create({
      data: {
        ...data,
        lastDeploymentDate: lastDeploymentDate ? new Date(lastDeploymentDate) : undefined,
        status: SystemReportStatus.DRAFT,
        revision: 1,
        enableUserVisibility: false, // MANDATORY: default false!
        createdById: adminId,
        updatedById: adminId,
        costs: costs && costs.length > 0
          ? {
              create: costs.map((c) => ({
                serviceName: c.serviceName,
                category: c.category,
                provider: c.provider,
                amount: c.amount,
                currency: c.currency ?? 'USD',
                billingPeriod: c.billingPeriod,
                costType: c.costType,
                description: c.description,
                lastUpdatedDate: c.lastUpdatedDate ? new Date(c.lastUpdatedDate) : new Date(),
                isVisible: false, // MANDATORY: default false!
              })),
            }
          : undefined,
      },
      include: {
        costs: true,
      },
    });

    await this.audit.emit({
      actorId: adminId,
      action: 'SYSTEM_REPORT_CREATED',
      resource: 'SYSTEM_REPORT',
      targetType: 'SYSTEM_REPORT',
      targetId: report.id,
      after: { title: report.title, status: report.status },
    });

    return report;
  }

  /**
   * Updates an existing report data fields.
   */
  async updateReport(adminId: string, id: string, dto: UpdateSystemReportDto) {
    const existing = await this.getAdminReportById(id);
    const { costs, lastDeploymentDate, ...data } = dto;

    const updated = await this.prisma.systemReport.update({
      where: { id },
      data: {
        ...data,
        lastDeploymentDate: lastDeploymentDate ? new Date(lastDeploymentDate) : undefined,
        updatedById: adminId,
      },
      include: {
        costs: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    await this.audit.emit({
      actorId: adminId,
      action: 'SYSTEM_REPORT_UPDATED',
      resource: 'SYSTEM_REPORT',
      targetType: 'SYSTEM_REPORT',
      targetId: id,
      before: { title: existing.title, status: existing.status },
      after: { title: updated.title, status: updated.status },
    });

    return updated;
  }

  /**
   * Updates visibility and display settings with strict audit logging.
   */
  async updateVisibility(adminId: string, id: string, dto: UpdateVisibilityDto) {
    const existing = await this.getAdminReportById(id);

    const updated = await this.prisma.systemReport.update({
      where: { id },
      data: {
        ...dto,
        updatedById: adminId,
      },
      include: {
        costs: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    await this.audit.emit({
      actorId: adminId,
      action: 'SYSTEM_REPORT_VISIBILITY_CHANGED',
      resource: 'SYSTEM_REPORT',
      targetType: 'SYSTEM_REPORT',
      targetId: id,
      before: {
        enableUserVisibility: existing.enableUserVisibility,
        displayMode: existing.displayMode,
        displayServerInfo: existing.displayServerInfo,
        displayDatabaseInfo: existing.displayDatabaseInfo,
        displayApiInfo: existing.displayApiInfo,
        displayDeploymentInfo: existing.displayDeploymentInfo,
        displayAdditionalCosts: existing.displayAdditionalCosts,
      },
      after: {
        enableUserVisibility: updated.enableUserVisibility,
        displayMode: updated.displayMode,
        displayServerInfo: updated.displayServerInfo,
        displayDatabaseInfo: updated.displayDatabaseInfo,
        displayApiInfo: updated.displayApiInfo,
        displayDeploymentInfo: updated.displayDeploymentInfo,
        displayAdditionalCosts: updated.displayAdditionalCosts,
      },
    });

    return updated;
  }

  /**
   * Publishes the system report.
   * Increments the revision number and stamps publishedAt timestamp.
   */
  async publishReport(adminId: string, id: string, displayMode?: SystemReportDisplayMode) {
    const existing = await this.getAdminReportById(id);

    const newRevision = (existing.revision ?? 0) + 1;

    const published = await this.prisma.systemReport.update({
      where: { id },
      data: {
        status: SystemReportStatus.PUBLISHED,
        revision: newRevision,
        publishedAt: new Date(),
        unpublishedAt: null,
        displayMode: displayMode ?? existing.displayMode,
        updatedById: adminId,
      },
      include: {
        costs: true,
      },
    });

    await this.audit.emit({
      actorId: adminId,
      action: 'SYSTEM_REPORT_PUBLISHED',
      resource: 'SYSTEM_REPORT',
      targetType: 'SYSTEM_REPORT',
      targetId: id,
      before: { status: existing.status, revision: existing.revision },
      after: {
        status: published.status,
        revision: published.revision,
        enableUserVisibility: published.enableUserVisibility,
        publishedAt: published.publishedAt,
      },
    });

    return published;
  }

  /**
   * Unpublishes the system report.
   */
  async unpublishReport(adminId: string, id: string) {
    const existing = await this.getAdminReportById(id);

    const unpublished = await this.prisma.systemReport.update({
      where: { id },
      data: {
        status: SystemReportStatus.UNPUBLISHED,
        unpublishedAt: new Date(),
        updatedById: adminId,
      },
      include: {
        costs: true,
      },
    });

    await this.audit.emit({
      actorId: adminId,
      action: 'SYSTEM_REPORT_UNPUBLISHED',
      resource: 'SYSTEM_REPORT',
      targetType: 'SYSTEM_REPORT',
      targetId: id,
      before: { status: existing.status },
      after: { status: unpublished.status, unpublishedAt: unpublished.unpublishedAt },
    });

    return unpublished;
  }

  /**
   * Adds an additional service cost item to a report.
   */
  async addCostItem(adminId: string, reportId: string, dto: CreateServiceCostDto) {
    await this.getAdminReportById(reportId);

    const cost = await this.prisma.systemServiceCost.create({
      data: {
        reportId,
        serviceName: dto.serviceName,
        category: dto.category,
        provider: dto.provider,
        amount: dto.amount,
        currency: dto.currency ?? 'USD',
        billingPeriod: dto.billingPeriod,
        costType: dto.costType,
        description: dto.description,
        lastUpdatedDate: dto.lastUpdatedDate ? new Date(dto.lastUpdatedDate) : new Date(),
        isVisible: dto.isVisible ?? false, // MANDATORY: default false!
      },
    });

    await this.audit.emit({
      actorId: adminId,
      action: 'SYSTEM_REPORT_COST_ADDED',
      resource: 'SYSTEM_SERVICE_COST',
      targetType: 'SYSTEM_SERVICE_COST',
      targetId: cost.id,
      after: { serviceName: cost.serviceName, amount: Number(cost.amount) },
    });

    return cost;
  }

  /**
   * Updates an existing service cost item.
   */
  async updateCostItem(adminId: string, costId: string, dto: UpdateServiceCostDto) {
    const existing = await this.prisma.systemServiceCost.findUnique({
      where: { id: costId },
    });
    if (!existing) {
      throw new NotFoundException(`Cost item with ID ${costId} not found`);
    }

    const { lastUpdatedDate, ...data } = dto;

    const updated = await this.prisma.systemServiceCost.update({
      where: { id: costId },
      data: {
        ...data,
        lastUpdatedDate: lastUpdatedDate ? new Date(lastUpdatedDate) : undefined,
      },
    });

    await this.audit.emit({
      actorId: adminId,
      action: 'SYSTEM_REPORT_COST_UPDATED',
      resource: 'SYSTEM_SERVICE_COST',
      targetType: 'SYSTEM_SERVICE_COST',
      targetId: costId,
      before: { serviceName: existing.serviceName, amount: Number(existing.amount), isVisible: existing.isVisible },
      after: { serviceName: updated.serviceName, amount: Number(updated.amount), isVisible: updated.isVisible },
    });

    return updated;
  }

  /**
   * Deletes a service cost item.
   */
  async deleteCostItem(adminId: string, costId: string) {
    const existing = await this.prisma.systemServiceCost.findUnique({
      where: { id: costId },
    });
    if (!existing) {
      throw new NotFoundException(`Cost item with ID ${costId} not found`);
    }

    await this.prisma.systemServiceCost.delete({
      where: { id: costId },
    });

    await this.audit.emit({
      actorId: adminId,
      action: 'SYSTEM_REPORT_COST_DELETED',
      resource: 'SYSTEM_SERVICE_COST',
      targetType: 'SYSTEM_SERVICE_COST',
      targetId: costId,
      before: { serviceName: existing.serviceName, amount: Number(existing.amount) },
    });

    return { success: true };
  }

  /**
   * Computes live all-over platform statistics directly from PostgreSQL:
   * - Total users broken down by role and status
   * - Total groups & messaging channels
   * - Video channels with uploaded video count & live stream count
   * - Total videos with full engagement & storage/duration breakdown
   * - Top videos ranked by likes, comments, views, and downloads
   * - Total live streams with viewer metrics and recent/active list
   * - Platform-wide content & storage totals
   */
  async getPlatformOverview(): Promise<PlatformOverviewDto> {
    const [
      rolesWithCounts,
      usersByStatus,
      groupsByStatus,
      totalGroupMembers,
      messagingChannelsCount,
      videoChannelsList,
      totalVideoChannels,
      activeVideoChannels,
      pendingVideoChannels,
      verifiedVideoChannels,
      channelSubscribersAgg,
      videosByStatus,
      publicVideosCount,
      videoAggregates,
      completedDownloadsCount,
      topByLikes,
      topByComments,
      topByViews,
      topByDownloads,
      streamsByStatus,
      streamAggregates,
      uniqueStreamViewersCount,
      recentStreams,
      totalPosts,
      totalStories,
      totalBooks,
      fileStats,
      totalReports,
      pendingReports,
    ] = await Promise.all([
      this.prisma.role.findMany({
        select: {
          name: true,
          _count: { select: { users: true } },
        },
        orderBy: { name: 'asc' },
      }),
      this.prisma.user.groupBy({
        by: ['status'],
        _count: { id: true },
      }),
      this.prisma.group.groupBy({
        by: ['status'],
        _count: { id: true },
      }),
      this.prisma.groupMember.count({ where: { removedAt: null } }),
      this.prisma.channel.count({ where: { deletedAt: null } }),
      this.prisma.videoChannel.findMany({
        where: { deletedAt: null },
        orderBy: [{ totalViewsCount: 'desc' }, { subscribersCount: 'desc' }],
        take: 50,
        select: {
          id: true,
          name: true,
          handle: true,
          status: true,
          isVerified: true,
          subscribersCount: true,
          totalViewsCount: true,
          _count: {
            select: {
              videos: { where: { deletedAt: null, status: { not: 'DELETED' } } },
              liveStreams: { where: { deletedAt: null } },
            },
          },
          liveStreams: {
            where: { deletedAt: null, status: 'LIVE' },
            select: { id: true },
          },
        },
      }),
      this.prisma.videoChannel.count({ where: { deletedAt: null } }),
      this.prisma.videoChannel.count({ where: { deletedAt: null, status: 'ACTIVE' } }),
      this.prisma.videoChannel.count({ where: { deletedAt: null, status: 'PENDING' } }),
      this.prisma.videoChannel.count({ where: { deletedAt: null, isVerified: true } }),
      this.prisma.videoChannel.aggregate({
        where: { deletedAt: null },
        _sum: { subscribersCount: true },
      }),
      this.prisma.video.groupBy({
        by: ['status'],
        where: { deletedAt: null, status: { not: 'DELETED' } },
        _count: { id: true },
      }),
      this.prisma.video.count({
        where: { deletedAt: null, status: { not: 'DELETED' }, visibility: 'PUBLIC' },
      }),
      this.prisma.video.aggregate({
        where: { deletedAt: null, status: { not: 'DELETED' } },
        _sum: {
          viewsCount: true,
          likesCount: true,
          dislikesCount: true,
          commentsCount: true,
          sharesCount: true,
          bookmarksCount: true,
          downloadsCount: true,
          duration: true,
        },
      }),
      this.prisma.downloadRecord.count({ where: { status: 'COMPLETED' } }),
      this.queryTopVideos({ likesCount: 'desc' }),
      this.queryTopVideos({ commentsCount: 'desc' }),
      this.queryTopVideos({ viewsCount: 'desc' }),
      this.queryTopVideos({ downloadsCount: 'desc' }),
      this.prisma.liveStream.groupBy({
        by: ['status'],
        where: { deletedAt: null },
        _count: { id: true },
      }),
      this.prisma.liveStream.aggregate({
        where: { deletedAt: null },
        _sum: {
          currentViewerCount: true,
          totalViewerCount: true,
          totalChatMessages: true,
          totalReactions: true,
          likesCount: true,
        },
        _max: {
          peakViewerCount: true,
        },
      }),
      this.prisma.streamViewer.count(),
      this.prisma.liveStream.findMany({
        where: { deletedAt: null },
        orderBy: [
          { currentViewerCount: 'desc' },
          { peakViewerCount: 'desc' },
          { createdAt: 'desc' },
        ],
        take: 20,
        select: {
          id: true,
          title: true,
          slug: true,
          status: true,
          currentViewerCount: true,
          peakViewerCount: true,
          totalViewerCount: true,
          likesCount: true,
          totalChatMessages: true,
          totalReactions: true,
          startedAt: true,
          endedAt: true,
          videoChannel: { select: { name: true } },
        },
      }),
      this.prisma.post.count({ where: { deletedAt: null } }),
      this.prisma.story.count(),
      this.prisma.book.count(),
      this.prisma.file.aggregate({
        _count: { id: true },
        _sum: { size: true },
      }),
      this.prisma.report.count(),
      this.prisma.report.count({ where: { status: 'PENDING' } }),
    ]);

    const userStatusMap: Record<string, number> = {};
    let totalUsers = 0;
    for (const row of usersByStatus) {
      userStatusMap[row.status] = row._count.id;
      totalUsers += row._count.id;
    }

    const groupStatusMap: Record<string, number> = {};
    let totalGroups = 0;
    for (const row of groupsByStatus) {
      groupStatusMap[row.status] = row._count.id;
      totalGroups += row._count.id;
    }

    const videoStatusMap: Record<string, number> = {};
    let totalVideos = 0;
    for (const row of videosByStatus) {
      videoStatusMap[row.status] = row._count.id;
      totalVideos += row._count.id;
    }

    const streamStatusMap: Record<string, number> = {};
    let totalStreams = 0;
    for (const row of streamsByStatus) {
      streamStatusMap[row.status] = row._count.id;
      totalStreams += row._count.id;
    }

    return {
      generatedAt: new Date().toISOString(),
      users: {
        total: totalUsers,
        byRole: rolesWithCounts.map((r) => ({
          role: r.name,
          count: r._count.users,
        })),
        byStatus: userStatusMap,
      },
      groups: {
        total: totalGroups,
        active: groupStatusMap['ACTIVE'] ?? 0,
        pending: groupStatusMap['PENDING_APPROVAL'] ?? 0,
        suspended: groupStatusMap['SUSPENDED'] ?? 0,
        totalMembers: totalGroupMembers,
        messagingChannels: messagingChannelsCount,
      },
      channels: {
        total: totalVideoChannels,
        active: activeVideoChannels,
        pending: pendingVideoChannels,
        verified: verifiedVideoChannels,
        totalSubscribers: channelSubscribersAgg._sum.subscribersCount ?? 0,
        items: videoChannelsList.map((ch) => ({
          id: ch.id,
          name: ch.name,
          handle: ch.handle,
          status: ch.status,
          isVerified: ch.isVerified,
          subscribersCount: ch.subscribersCount,
          uploadedVideosCount: ch._count.videos,
          liveStreamsCount: ch._count.liveStreams,
          activeLiveStreamsCount: ch.liveStreams.length,
          totalViewsCount: Number(ch.totalViewsCount ?? 0),
        })),
      },
      videos: {
        total: totalVideos,
        ready: videoStatusMap['READY'] ?? 0,
        processing: (videoStatusMap['PROCESSING'] ?? 0) + (videoStatusMap['UPLOADING'] ?? 0),
        failed: videoStatusMap['FAILED'] ?? 0,
        publicCount: publicVideosCount,
        totalViews: Number(videoAggregates._sum.viewsCount ?? 0),
        totalLikes: videoAggregates._sum.likesCount ?? 0,
        totalDislikes: videoAggregates._sum.dislikesCount ?? 0,
        totalComments: videoAggregates._sum.commentsCount ?? 0,
        totalShares: videoAggregates._sum.sharesCount ?? 0,
        totalBookmarks: videoAggregates._sum.bookmarksCount ?? 0,
        totalDownloads: videoAggregates._sum.downloadsCount ?? 0,
        completedDownloadRecords: completedDownloadsCount,
        totalDurationSeconds: Math.round(videoAggregates._sum.duration ?? 0),
      },
      topVideos: {
        byLikes: topByLikes,
        byComments: topByComments,
        byViews: topByViews,
        byDownloads: topByDownloads,
      },
      liveStreams: {
        total: totalStreams,
        liveNow: streamStatusMap['LIVE'] ?? 0,
        ended: streamStatusMap['ENDED'] ?? 0,
        scheduled: streamStatusMap['SCHEDULED'] ?? 0,
        currentViewers: streamAggregates._sum.currentViewerCount ?? 0,
        peakViewersMax: streamAggregates._max.peakViewerCount ?? 0,
        totalViewerJoins: streamAggregates._sum.totalViewerCount ?? 0,
        uniqueViewerRecords: uniqueStreamViewersCount,
        totalChatMessages: streamAggregates._sum.totalChatMessages ?? 0,
        totalReactions: streamAggregates._sum.totalReactions ?? 0,
        totalLikes: streamAggregates._sum.likesCount ?? 0,
        recentAndActive: recentStreams.map((s) => ({
          id: s.id,
          title: s.title,
          slug: s.slug,
          status: s.status,
          channelName: s.videoChannel?.name,
          currentViewerCount: s.currentViewerCount,
          peakViewerCount: s.peakViewerCount,
          totalViewerCount: s.totalViewerCount,
          likesCount: s.likesCount,
          totalChatMessages: s.totalChatMessages,
          totalReactions: s.totalReactions,
          startedAt: s.startedAt?.toISOString(),
          endedAt: s.endedAt?.toISOString(),
        })),
      },
      platformTotals: {
        totalPosts,
        totalStories,
        totalBooks,
        totalFiles: fileStats._count.id,
        totalStorageBytes: Number(fileStats._sum.size ?? 0),
        totalAbuseReports: totalReports,
        pendingAbuseReports: pendingReports,
      },
    };
  }

  private async queryTopVideos(
    orderBy: Record<string, 'asc' | 'desc'>,
  ): Promise<PlatformOverviewTopVideoDto[]> {
    const rows = await this.prisma.video.findMany({
      where: { deletedAt: null, status: { not: 'DELETED' } },
      orderBy: [orderBy, { createdAt: 'desc' }],
      take: 5,
      select: {
        id: true,
        title: true,
        slug: true,
        thumbnailUrl: true,
        status: true,
        visibility: true,
        duration: true,
        viewsCount: true,
        likesCount: true,
        commentsCount: true,
        downloadsCount: true,
        sharesCount: true,
        publishedAt: true,
        videoChannel: {
          select: { name: true, handle: true },
        },
      },
    });

    return rows.map((v) => ({
      id: v.id,
      title: v.title,
      slug: v.slug,
      thumbnailUrl: v.thumbnailUrl ?? undefined,
      channelName: v.videoChannel?.name,
      channelHandle: v.videoChannel?.handle,
      status: v.status,
      visibility: v.visibility,
      duration: v.duration ?? undefined,
      viewsCount: Number(v.viewsCount ?? 0),
      likesCount: v.likesCount,
      commentsCount: v.commentsCount,
      downloadsCount: v.downloadsCount,
      sharesCount: v.sharesCount,
      publishedAt: v.publishedAt?.toISOString(),
    }));
  }

  private filterOverviewForPublic(
    report: SystemReport,
    fullOverview?: PlatformOverviewDto,
  ): PlatformOverviewDto | undefined {
    if (!report.displayPlatformOverview || !fullOverview) {
      return undefined;
    }

    const filtered: PlatformOverviewDto = {
      generatedAt: fullOverview.generatedAt,
    };

    if (report.showUsersOverview && fullOverview.users) {
      filtered.users = fullOverview.users;
    }
    if (report.showGroupsOverview && fullOverview.groups) {
      filtered.groups = fullOverview.groups;
    }
    if (report.showChannelsOverview && fullOverview.channels) {
      filtered.channels = fullOverview.channels;
    }
    if (report.showVideosOverview && fullOverview.videos) {
      filtered.videos = fullOverview.videos;
    }
    if (report.showTopVideosOverview && fullOverview.topVideos) {
      filtered.topVideos = fullOverview.topVideos;
    }
    if (report.showLiveStreamsOverview && fullOverview.liveStreams) {
      filtered.liveStreams = fullOverview.liveStreams;
    }

    const hasAnySection =
      filtered.users ||
      filtered.groups ||
      filtered.channels ||
      filtered.videos ||
      filtered.topVideos ||
      filtered.liveStreams;

    return hasAnySection ? filtered : undefined;
  }

  /**
   * Previews what an ordinary user will see for the specified report.
   * Ignores the global enableUserVisibility flag so the admin can inspect the filtered output.
   */
  async previewPublicReport(id: string): Promise<PublicSystemReportDto> {
    const report = await this.getAdminReportById(id);
    const overview = report.displayPlatformOverview
      ? await this.getPlatformOverview()
      : undefined;
    return this.buildSanitizedReport(report, false, overview);
  }

  /**
   * Retrieves the active published system report for ordinary users.
   * If global user visibility is disabled or no report is published, returns available: false.
   * All hidden categories, fields, and cost items are completely stripped at the server level.
   */
  async getActivePublicReport(userId?: string): Promise<{ available: boolean; report: PublicSystemReportDto | null }> {
    const report = await this.prisma.systemReport.findFirst({
      where: {
        status: SystemReportStatus.PUBLISHED,
        enableUserVisibility: true, // MANDATORY: Must be explicitly enabled!
      },
      orderBy: { publishedAt: 'desc' },
      include: {
        costs: {
          where: { isVisible: true }, // Only visible cost items queried
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    if (!report) {
      return { available: false, report: null };
    }

    let hasDismissed = false;
    if (userId) {
      const view = await this.prisma.userSystemReportView.findUnique({
        where: {
          userId_reportId_revision: {
            userId,
            reportId: report.id,
            revision: report.revision,
          },
        },
      });
      hasDismissed = !!(view && view.dismissedAt);
    }

    const overview = report.displayPlatformOverview
      ? await this.getPlatformOverview()
      : undefined;
    const sanitized = this.buildSanitizedReport(report, hasDismissed, overview);
    return { available: true, report: sanitized };
  }

  /**
   * Records that an authenticated user viewed and dismissed a specific revision of the report.
   */
  async recordUserDismissal(userId: string, reportId: string, revision: number) {
    const report = await this.prisma.systemReport.findUnique({
      where: { id: reportId },
      select: { id: true, revision: true },
    });

    if (!report) {
      throw new NotFoundException(`Report ${reportId} not found`);
    }

    return this.prisma.userSystemReportView.upsert({
      where: {
        userId_reportId_revision: {
          userId,
          reportId,
          revision,
        },
      },
      create: {
        userId,
        reportId,
        revision,
        viewedAt: new Date(),
        dismissedAt: new Date(),
      },
      update: {
        dismissedAt: new Date(),
      },
    });
  }

  /**
   * Strict server-side field-level filter.
   * Ensures that unapproved or unconfigured fields are NEVER exposed to the public API.
   */
  private buildSanitizedReport(
    report: SystemReport & { costs?: SystemServiceCost[] },
    hasDismissed: boolean,
    fullOverview?: PlatformOverviewDto,
  ): PublicSystemReportDto {
    // 1. Server info filtering
    let server: PublicServerInfoDto | undefined = undefined;
    if (report.displayServerInfo) {
      const serverData: PublicServerInfoDto = {};
      if (report.showServerProvider && report.serverProvider) serverData.provider = report.serverProvider;
      if (report.showServerServiceName && report.serverServiceName) serverData.serviceName = report.serverServiceName;
      if (report.showServerLocation && report.serverLocation) serverData.location = report.serverLocation;
      if (report.showServerRegion && report.serverRegion) serverData.region = report.serverRegion;
      if (report.showServerPlan && report.serverPlan) serverData.plan = report.serverPlan;
      if (report.showServerHostingType && report.serverHostingType) serverData.hostingType = report.serverHostingType;
      if (report.showServerCpu && report.serverCpu) serverData.cpu = report.serverCpu;
      if (report.showServerRam && report.serverRam) serverData.ram = report.serverRam;
      if (report.showServerDiskCapacity && report.serverDiskCapacity) serverData.diskCapacity = report.serverDiskCapacity;
      if (report.showServerAvailableStorage && report.serverAvailableStorage) serverData.availableStorage = report.serverAvailableStorage;
      if (report.showServerStatus && report.serverStatus) serverData.status = report.serverStatus;
      if (report.showServerHealth && report.serverHealth) serverData.health = report.serverHealth;
      if (report.showServerUptime && report.serverUptime) serverData.uptime = report.serverUptime;
      if (report.showServerMaintenanceInfo && report.serverMaintenanceInfo) serverData.maintenanceInfo = report.serverMaintenanceInfo;
      if (report.showServerBackupConfig && report.serverBackupConfig) serverData.backupConfig = report.serverBackupConfig;
      if (report.showServerBackupStorage && report.serverBackupStorage) serverData.backupStorage = report.serverBackupStorage;

      // Server Costs: Only if displayServerCosts is ON and field is ON
      if (report.displayServerCosts) {
        if (report.showServerMonthlyCost && report.serverMonthlyCost !== null) {
          serverData.monthlyCost = Number(report.serverMonthlyCost);
        }
        if (report.showServerYearlyCost && report.serverYearlyCost !== null) {
          serverData.yearlyCost = Number(report.serverYearlyCost);
        }
        if (serverData.monthlyCost !== undefined || serverData.yearlyCost !== undefined) {
          serverData.currency = report.serverCostCurrency;
        }
      }

      if (Object.keys(serverData).length > 0) {
        server = serverData;
      }
    }

    // 2. Database info filtering
    let database: PublicDatabaseInfoDto | undefined = undefined;
    if (report.displayDatabaseInfo) {
      const dbData: PublicDatabaseInfoDto = {};
      if (report.showDbProvider && report.dbProvider) dbData.provider = report.dbProvider;
      if (report.showDbEngine && report.dbEngine) dbData.engine = report.dbEngine;
      if (report.showDbHostingPlan && report.dbHostingPlan) dbData.hostingPlan = report.dbHostingPlan;
      if (report.showDbInfrastructure && report.dbInfrastructure) dbData.infrastructure = report.dbInfrastructure;
      if (report.showDbStorageUsage && report.dbStorageUsage) dbData.storageUsage = report.dbStorageUsage;
      if (report.showDbStorageCapacity && report.dbStorageCapacity) dbData.storageCapacity = report.dbStorageCapacity;
      if (report.showDbBackupStatus && report.dbBackupStatus) dbData.backupStatus = report.dbBackupStatus;
      if (report.showDbHealth && report.dbHealth) dbData.health = report.dbHealth;
      if (report.showDbAvailability && report.dbAvailability) dbData.availability = report.dbAvailability;

      // DB Costs
      if (report.displayDatabaseCosts) {
        if (report.showDbMonthlyCost && report.dbMonthlyCost !== null) {
          dbData.monthlyCost = Number(report.dbMonthlyCost);
        }
        if (report.showDbYearlyCost && report.dbYearlyCost !== null) {
          dbData.yearlyCost = Number(report.dbYearlyCost);
        }
        if (dbData.monthlyCost !== undefined || dbData.yearlyCost !== undefined) {
          dbData.currency = report.dbCostCurrency;
        }
      }

      if (Object.keys(dbData).length > 0) {
        database = dbData;
      }
    }

    // 3. API info filtering
    let api: PublicApiInfoDto | undefined = undefined;
    if (report.displayApiInfo) {
      const apiData: PublicApiInfoDto = {};
      if (report.showApiServiceName && report.apiServiceName) apiData.serviceName = report.apiServiceName;
      if (report.showApiAvailability && report.apiAvailability) apiData.availability = report.apiAvailability;
      if (report.showApiStatus && report.apiStatus) apiData.status = report.apiStatus;
      if (report.showApiResponseTime && report.apiResponseTime) apiData.responseTime = report.apiResponseTime;
      if (report.showApiUsageStats && report.apiUsageStats) apiData.usageStats = report.apiUsageStats;

      // API Costs
      if (report.displayApiCosts) {
        if (report.showApiHostingCost && report.apiHostingCost !== null) {
          apiData.hostingCost = Number(report.apiHostingCost);
        }
        if (report.showApiExternalCost && report.apiExternalCost !== null) {
          apiData.externalCost = Number(report.apiExternalCost);
        }
        if (apiData.hostingCost !== undefined || apiData.externalCost !== undefined) {
          apiData.currency = report.apiCostCurrency;
        }
      }

      if (Object.keys(apiData).length > 0) {
        api = apiData;
      }
    }

    // 4. Deployment info filtering
    let deployment: PublicDeploymentInfoDto | undefined = undefined;
    if (report.displayDeploymentInfo) {
      const depData: PublicDeploymentInfoDto = {};
      if (report.showDeploymentProvider && report.deploymentProvider) depData.provider = report.deploymentProvider;
      if (report.showDeploymentEnvironment && report.deploymentEnvironment) depData.environment = report.deploymentEnvironment;
      if (report.showAppVersion && report.appVersion) depData.appVersion = report.appVersion;
      if (report.showLastDeploymentDate && report.lastDeploymentDate) depData.lastDeploymentDate = report.lastDeploymentDate.toISOString();
      if (report.showBuildStatus && report.buildStatus) depData.buildStatus = report.buildStatus;
      if (report.showEnvironmentInfo && report.environmentInfo) depData.environmentInfo = report.environmentInfo;

      // Deployment Costs
      if (report.displayDeploymentCosts) {
        if (report.showDeploymentCost && report.deploymentCost !== null) {
          depData.deploymentCost = Number(report.deploymentCost);
          depData.currency = report.deploymentCostCurrency;
        }
      }

      if (Object.keys(depData).length > 0) {
        deployment = depData;
      }
    }

    // 5. Additional service costs filtering
    const costs: PublicCostItemDto[] = [];
    if (report.displayAdditionalCosts && report.costs) {
      for (const cost of report.costs) {
        if (cost.isVisible) {
          costs.push({
            id: cost.id,
            serviceName: cost.serviceName,
            category: cost.category,
            provider: cost.provider ?? undefined,
            amount: Number(cost.amount),
            currency: cost.currency,
            billingPeriod: cost.billingPeriod,
            costType: cost.costType,
            description: cost.description ?? undefined,
            lastUpdatedDate: cost.lastUpdatedDate ? cost.lastUpdatedDate.toISOString() : undefined,
          });
        }
      }
    }

    return {
      id: report.id,
      title: report.title,
      summary: report.summary ?? undefined,
      notes: report.notes ?? undefined,
      revision: report.revision,
      publishedAt: report.publishedAt ? report.publishedAt.toISOString() : new Date().toISOString(),
      displayMode: report.displayMode,
      server,
      database,
      api,
      deployment,
      costs,
      overview: this.filterOverviewForPublic(report, fullOverview),
      hasDismissed,
    };
  }
}
