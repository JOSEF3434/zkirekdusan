import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SystemReportDisplayMode, CostCategory, CostBillingPeriod, CostType } from '@prisma/client';

export class PublicServerInfoDto {
  @ApiPropertyOptional() provider?: string;
  @ApiPropertyOptional() serviceName?: string;
  @ApiPropertyOptional() location?: string;
  @ApiPropertyOptional() region?: string;
  @ApiPropertyOptional() plan?: string;
  @ApiPropertyOptional() hostingType?: string;
  @ApiPropertyOptional() cpu?: string;
  @ApiPropertyOptional() ram?: string;
  @ApiPropertyOptional() diskCapacity?: string;
  @ApiPropertyOptional() availableStorage?: string;
  @ApiPropertyOptional() status?: string;
  @ApiPropertyOptional() health?: string;
  @ApiPropertyOptional() uptime?: string;
  @ApiPropertyOptional() maintenanceInfo?: string;
  @ApiPropertyOptional() backupConfig?: string;
  @ApiPropertyOptional() backupStorage?: string;
  @ApiPropertyOptional() monthlyCost?: number;
  @ApiPropertyOptional() yearlyCost?: number;
  @ApiPropertyOptional() currency?: string;
}

export class PublicDatabaseInfoDto {
  @ApiPropertyOptional() provider?: string;
  @ApiPropertyOptional() engine?: string;
  @ApiPropertyOptional() hostingPlan?: string;
  @ApiPropertyOptional() infrastructure?: string;
  @ApiPropertyOptional() storageUsage?: string;
  @ApiPropertyOptional() storageCapacity?: string;
  @ApiPropertyOptional() backupStatus?: string;
  @ApiPropertyOptional() health?: string;
  @ApiPropertyOptional() availability?: string;
  @ApiPropertyOptional() monthlyCost?: number;
  @ApiPropertyOptional() yearlyCost?: number;
  @ApiPropertyOptional() currency?: string;
}

export class PublicApiInfoDto {
  @ApiPropertyOptional() serviceName?: string;
  @ApiPropertyOptional() availability?: string;
  @ApiPropertyOptional() status?: string;
  @ApiPropertyOptional() responseTime?: string;
  @ApiPropertyOptional() usageStats?: string;
  @ApiPropertyOptional() hostingCost?: number;
  @ApiPropertyOptional() externalCost?: number;
  @ApiPropertyOptional() currency?: string;
}

export class PublicDeploymentInfoDto {
  @ApiPropertyOptional() provider?: string;
  @ApiPropertyOptional() environment?: string;
  @ApiPropertyOptional() appVersion?: string;
  @ApiPropertyOptional() lastDeploymentDate?: string;
  @ApiPropertyOptional() buildStatus?: string;
  @ApiPropertyOptional() deploymentCost?: number;
  @ApiPropertyOptional() currency?: string;
  @ApiPropertyOptional() environmentInfo?: string;
}

export class PublicCostItemDto {
  @ApiProperty() id!: string;
  @ApiProperty() serviceName!: string;
  @ApiProperty({ enum: CostCategory }) category!: CostCategory;
  @ApiPropertyOptional() provider?: string;
  @ApiProperty() amount!: number;
  @ApiProperty() currency!: string;
  @ApiProperty({ enum: CostBillingPeriod }) billingPeriod!: CostBillingPeriod;
  @ApiProperty({ enum: CostType }) costType!: CostType;
  @ApiPropertyOptional() description?: string;
  @ApiPropertyOptional() lastUpdatedDate?: string;
}

export class PlatformOverviewChannelDto {
  @ApiProperty() id!: string;
  @ApiProperty() name!: string;
  @ApiProperty() handle!: string;
  @ApiProperty() status!: string;
  @ApiProperty() isVerified!: boolean;
  @ApiProperty() subscribersCount!: number;
  @ApiProperty() uploadedVideosCount!: number;
  @ApiProperty() liveStreamsCount!: number;
  @ApiProperty() activeLiveStreamsCount!: number;
  @ApiProperty() totalViewsCount!: number;
}

export class PlatformOverviewTopVideoDto {
  @ApiProperty() id!: string;
  @ApiProperty() title!: string;
  @ApiProperty() slug!: string;
  @ApiPropertyOptional() thumbnailUrl?: string;
  @ApiPropertyOptional() channelName?: string;
  @ApiPropertyOptional() channelHandle?: string;
  @ApiProperty() status!: string;
  @ApiProperty() visibility!: string;
  @ApiPropertyOptional() duration?: number;
  @ApiProperty() viewsCount!: number;
  @ApiProperty() likesCount!: number;
  @ApiProperty() commentsCount!: number;
  @ApiProperty() downloadsCount!: number;
  @ApiProperty() sharesCount!: number;
  @ApiPropertyOptional() publishedAt?: string;
}

export class PlatformOverviewLiveStreamDto {
  @ApiProperty() id!: string;
  @ApiProperty() title!: string;
  @ApiProperty() slug!: string;
  @ApiProperty() status!: string;
  @ApiPropertyOptional() channelName?: string;
  @ApiProperty() currentViewerCount!: number;
  @ApiProperty() peakViewerCount!: number;
  @ApiProperty() totalViewerCount!: number;
  @ApiProperty() likesCount!: number;
  @ApiProperty() totalChatMessages!: number;
  @ApiProperty() totalReactions!: number;
  @ApiPropertyOptional() startedAt?: string;
  @ApiPropertyOptional() endedAt?: string;
}

export class PlatformOverviewDto {
  @ApiPropertyOptional() generatedAt?: string;
  @ApiPropertyOptional() users?: {
    total: number;
    byRole: Array<{ role: string; count: number }>;
    byStatus: Record<string, number>;
  };
  @ApiPropertyOptional() groups?: {
    total: number;
    active: number;
    pending: number;
    suspended: number;
    totalMembers: number;
    messagingChannels: number;
  };
  @ApiPropertyOptional() channels?: {
    total: number;
    active: number;
    pending: number;
    verified: number;
    totalSubscribers: number;
    items: PlatformOverviewChannelDto[];
  };
  @ApiPropertyOptional() videos?: {
    total: number;
    ready: number;
    processing: number;
    failed: number;
    publicCount: number;
    totalViews: number;
    totalLikes: number;
    totalDislikes: number;
    totalComments: number;
    totalShares: number;
    totalBookmarks: number;
    totalDownloads: number;
    completedDownloadRecords: number;
    totalDurationSeconds: number;
  };
  @ApiPropertyOptional() topVideos?: {
    byLikes: PlatformOverviewTopVideoDto[];
    byComments: PlatformOverviewTopVideoDto[];
    byViews: PlatformOverviewTopVideoDto[];
    byDownloads: PlatformOverviewTopVideoDto[];
  };
  @ApiPropertyOptional() liveStreams?: {
    total: number;
    liveNow: number;
    ended: number;
    scheduled: number;
    currentViewers: number;
    peakViewersMax: number;
    totalViewerJoins: number;
    uniqueViewerRecords: number;
    totalChatMessages: number;
    totalReactions: number;
    totalLikes: number;
    recentAndActive: PlatformOverviewLiveStreamDto[];
  };
  @ApiPropertyOptional() platformTotals?: {
    totalPosts: number;
    totalStories: number;
    totalBooks: number;
    totalFiles: number;
    totalStorageBytes: number;
    totalAbuseReports: number;
    pendingAbuseReports: number;
  };
}

export class PublicSystemReportDto {
  @ApiProperty() id!: string;
  @ApiProperty() title!: string;
  @ApiPropertyOptional() summary?: string;
  @ApiPropertyOptional() notes?: string;
  @ApiProperty() revision!: number;
  @ApiProperty() publishedAt!: string;
  @ApiProperty({ enum: SystemReportDisplayMode }) displayMode!: SystemReportDisplayMode;
  @ApiPropertyOptional() server?: PublicServerInfoDto;
  @ApiPropertyOptional() database?: PublicDatabaseInfoDto;
  @ApiPropertyOptional() api?: PublicApiInfoDto;
  @ApiPropertyOptional() deployment?: PublicDeploymentInfoDto;
  @ApiProperty({ type: [PublicCostItemDto] }) costs!: PublicCostItemDto[];
  @ApiPropertyOptional() overview?: PlatformOverviewDto;
  @ApiPropertyOptional({ description: 'Whether the current authenticated user has viewed/dismissed this revision' })
  hasDismissed?: boolean;
}
