// lib/features/settings/domain/public_system_report_model.dart

class PublicServerInfo {
  final String? provider;
  final String? serviceName;
  final String? location;
  final String? region;
  final String? plan;
  final String? hostingType;
  final String? cpu;
  final String? ram;
  final String? diskCapacity;
  final String? availableStorage;
  final String? status;
  final String? health;
  final String? uptime;
  final String? maintenanceInfo;
  final String? backupConfig;
  final String? backupStorage;
  final double? monthlyCost;
  final double? yearlyCost;
  final String? currency;

  const PublicServerInfo({
    this.provider,
    this.serviceName,
    this.location,
    this.region,
    this.plan,
    this.hostingType,
    this.cpu,
    this.ram,
    this.diskCapacity,
    this.availableStorage,
    this.status,
    this.health,
    this.uptime,
    this.maintenanceInfo,
    this.backupConfig,
    this.backupStorage,
    this.monthlyCost,
    this.yearlyCost,
    this.currency,
  });

  factory PublicServerInfo.fromJson(Map<String, dynamic> json) {
    return PublicServerInfo(
      provider: json['provider'] as String?,
      serviceName: json['serviceName'] as String?,
      location: json['location'] as String?,
      region: json['region'] as String?,
      plan: json['plan'] as String?,
      hostingType: json['hostingType'] as String?,
      cpu: json['cpu'] as String?,
      ram: json['ram'] as String?,
      diskCapacity: json['diskCapacity'] as String?,
      availableStorage: json['availableStorage'] as String?,
      status: json['status'] as String?,
      health: json['health'] as String?,
      uptime: json['uptime'] as String?,
      maintenanceInfo: json['maintenanceInfo'] as String?,
      backupConfig: json['backupConfig'] as String?,
      backupStorage: json['backupStorage'] as String?,
      monthlyCost: (json['monthlyCost'] as num?)?.toDouble(),
      yearlyCost: (json['yearlyCost'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );
  }
}

class PublicDatabaseInfo {
  final String? provider;
  final String? engine;
  final String? hostingPlan;
  final String? infrastructure;
  final String? storageUsage;
  final String? storageCapacity;
  final String? backupStatus;
  final String? health;
  final String? availability;
  final double? monthlyCost;
  final double? yearlyCost;
  final String? currency;

  const PublicDatabaseInfo({
    this.provider,
    this.engine,
    this.hostingPlan,
    this.infrastructure,
    this.storageUsage,
    this.storageCapacity,
    this.backupStatus,
    this.health,
    this.availability,
    this.monthlyCost,
    this.yearlyCost,
    this.currency,
  });

  factory PublicDatabaseInfo.fromJson(Map<String, dynamic> json) {
    return PublicDatabaseInfo(
      provider: json['provider'] as String?,
      engine: json['engine'] as String?,
      hostingPlan: json['hostingPlan'] as String?,
      infrastructure: json['infrastructure'] as String?,
      storageUsage: json['storageUsage'] as String?,
      storageCapacity: json['storageCapacity'] as String?,
      backupStatus: json['backupStatus'] as String?,
      health: json['health'] as String?,
      availability: json['availability'] as String?,
      monthlyCost: (json['monthlyCost'] as num?)?.toDouble(),
      yearlyCost: (json['yearlyCost'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );
  }
}

class PublicApiInfo {
  final String? serviceName;
  final String? availability;
  final String? status;
  final String? responseTime;
  final String? usageStats;
  final double? hostingCost;
  final double? externalCost;
  final String? currency;

  const PublicApiInfo({
    this.serviceName,
    this.availability,
    this.status,
    this.responseTime,
    this.usageStats,
    this.hostingCost,
    this.externalCost,
    this.currency,
  });

  factory PublicApiInfo.fromJson(Map<String, dynamic> json) {
    return PublicApiInfo(
      serviceName: json['serviceName'] as String?,
      availability: json['availability'] as String?,
      status: json['status'] as String?,
      responseTime: json['responseTime'] as String?,
      usageStats: json['usageStats'] as String?,
      hostingCost: (json['hostingCost'] as num?)?.toDouble(),
      externalCost: (json['externalCost'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );
  }
}

class PublicDeploymentInfo {
  final String? provider;
  final String? environment;
  final String? appVersion;
  final DateTime? lastDeploymentDate;
  final String? buildStatus;
  final double? deploymentCost;
  final String? currency;
  final String? environmentInfo;

  const PublicDeploymentInfo({
    this.provider,
    this.environment,
    this.appVersion,
    this.lastDeploymentDate,
    this.buildStatus,
    this.deploymentCost,
    this.currency,
    this.environmentInfo,
  });

  factory PublicDeploymentInfo.fromJson(Map<String, dynamic> json) {
    return PublicDeploymentInfo(
      provider: json['provider'] as String?,
      environment: json['environment'] as String?,
      appVersion: json['appVersion'] as String?,
      lastDeploymentDate: json['lastDeploymentDate'] != null
          ? DateTime.tryParse(json['lastDeploymentDate'] as String)
          : null,
      buildStatus: json['buildStatus'] as String?,
      deploymentCost: (json['deploymentCost'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      environmentInfo: json['environmentInfo'] as String?,
    );
  }
}

class PublicCostItem {
  final String id;
  final String serviceName;
  final String category;
  final String? provider;
  final double amount;
  final String currency;
  final String billingPeriod;
  final String costType;
  final String? description;
  final DateTime? lastUpdatedDate;

  const PublicCostItem({
    required this.id,
    required this.serviceName,
    required this.category,
    this.provider,
    required this.amount,
    required this.currency,
    required this.billingPeriod,
    required this.costType,
    this.description,
    this.lastUpdatedDate,
  });

  factory PublicCostItem.fromJson(Map<String, dynamic> json) {
    return PublicCostItem(
      id: json['id'] as String? ?? '',
      serviceName: json['serviceName'] as String? ?? '',
      category: json['category'] as String? ?? 'OTHER',
      provider: json['provider'] as String?,
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      billingPeriod: json['billingPeriod'] as String? ?? 'MONTHLY',
      costType: json['costType'] as String? ?? 'ACTUAL',
      description: json['description'] as String?,
      lastUpdatedDate: json['lastUpdatedDate'] != null
          ? DateTime.tryParse(json['lastUpdatedDate'] as String)
          : null,
    );
  }
}

class RoleCountItem {
  final String role;
  final int count;

  const RoleCountItem({required this.role, required this.count});

  factory RoleCountItem.fromJson(Map<String, dynamic> json) {
    return RoleCountItem(
      role: json['role'] as String? ?? 'USER',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class PlatformUsersOverview {
  final int total;
  final List<RoleCountItem> byRole;
  final Map<String, int> byStatus;

  const PlatformUsersOverview({
    required this.total,
    required this.byRole,
    required this.byStatus,
  });

  factory PlatformUsersOverview.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['byRole'] as List<dynamic>? ?? [];
    final rawStatus = json['byStatus'] as Map<String, dynamic>? ?? {};
    return PlatformUsersOverview(
      total: (json['total'] as num?)?.toInt() ?? 0,
      byRole: rawRoles
          .map((e) => RoleCountItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      byStatus: rawStatus.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
    );
  }
}

class PlatformGroupsOverview {
  final int total;
  final int active;
  final int pending;
  final int suspended;
  final int totalMembers;
  final int messagingChannels;

  const PlatformGroupsOverview({
    required this.total,
    required this.active,
    required this.pending,
    required this.suspended,
    required this.totalMembers,
    required this.messagingChannels,
  });

  factory PlatformGroupsOverview.fromJson(Map<String, dynamic> json) {
    return PlatformGroupsOverview(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      suspended: (json['suspended'] as num?)?.toInt() ?? 0,
      totalMembers: (json['totalMembers'] as num?)?.toInt() ?? 0,
      messagingChannels: (json['messagingChannels'] as num?)?.toInt() ?? 0,
    );
  }
}

class PlatformChannelItem {
  final String id;
  final String name;
  final String handle;
  final String status;
  final bool isVerified;
  final int subscribersCount;
  final int uploadedVideosCount;
  final int liveStreamsCount;
  final int activeLiveStreamsCount;
  final int totalViewsCount;

  const PlatformChannelItem({
    required this.id,
    required this.name,
    required this.handle,
    required this.status,
    required this.isVerified,
    required this.subscribersCount,
    required this.uploadedVideosCount,
    required this.liveStreamsCount,
    required this.activeLiveStreamsCount,
    required this.totalViewsCount,
  });

  factory PlatformChannelItem.fromJson(Map<String, dynamic> json) {
    return PlatformChannelItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      isVerified: json['isVerified'] as bool? ?? false,
      subscribersCount: (json['subscribersCount'] as num?)?.toInt() ?? 0,
      uploadedVideosCount: (json['uploadedVideosCount'] as num?)?.toInt() ?? 0,
      liveStreamsCount: (json['liveStreamsCount'] as num?)?.toInt() ?? 0,
      activeLiveStreamsCount: (json['activeLiveStreamsCount'] as num?)?.toInt() ?? 0,
      totalViewsCount: (json['totalViewsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class PlatformChannelsOverview {
  final int total;
  final int active;
  final int pending;
  final int verified;
  final int totalSubscribers;
  final List<PlatformChannelItem> items;

  const PlatformChannelsOverview({
    required this.total,
    required this.active,
    required this.pending,
    required this.verified,
    required this.totalSubscribers,
    required this.items,
  });

  factory PlatformChannelsOverview.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PlatformChannelsOverview(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      verified: (json['verified'] as num?)?.toInt() ?? 0,
      totalSubscribers: (json['totalSubscribers'] as num?)?.toInt() ?? 0,
      items: rawItems
          .map((e) => PlatformChannelItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PlatformVideosOverview {
  final int total;
  final int ready;
  final int processing;
  final int failed;
  final int publicCount;
  final int totalViews;
  final int totalLikes;
  final int totalDislikes;
  final int totalComments;
  final int totalShares;
  final int totalBookmarks;
  final int totalDownloads;
  final int completedDownloadRecords;
  final int totalDurationSeconds;

  const PlatformVideosOverview({
    required this.total,
    required this.ready,
    required this.processing,
    required this.failed,
    required this.publicCount,
    required this.totalViews,
    required this.totalLikes,
    required this.totalDislikes,
    required this.totalComments,
    required this.totalShares,
    required this.totalBookmarks,
    required this.totalDownloads,
    required this.completedDownloadRecords,
    required this.totalDurationSeconds,
  });

  factory PlatformVideosOverview.fromJson(Map<String, dynamic> json) {
    return PlatformVideosOverview(
      total: (json['total'] as num?)?.toInt() ?? 0,
      ready: (json['ready'] as num?)?.toInt() ?? 0,
      processing: (json['processing'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
      publicCount: (json['publicCount'] as num?)?.toInt() ?? 0,
      totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
      totalLikes: (json['totalLikes'] as num?)?.toInt() ?? 0,
      totalDislikes: (json['totalDislikes'] as num?)?.toInt() ?? 0,
      totalComments: (json['totalComments'] as num?)?.toInt() ?? 0,
      totalShares: (json['totalShares'] as num?)?.toInt() ?? 0,
      totalBookmarks: (json['totalBookmarks'] as num?)?.toInt() ?? 0,
      totalDownloads: (json['totalDownloads'] as num?)?.toInt() ?? 0,
      completedDownloadRecords:
          (json['completedDownloadRecords'] as num?)?.toInt() ?? 0,
      totalDurationSeconds: (json['totalDurationSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}

class PlatformTopVideoItem {
  final String id;
  final String title;
  final String slug;
  final String? thumbnailUrl;
  final String? channelName;
  final String? channelHandle;
  final String status;
  final String visibility;
  final double? duration;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final int downloadsCount;
  final int sharesCount;
  final DateTime? publishedAt;

  const PlatformTopVideoItem({
    required this.id,
    required this.title,
    required this.slug,
    this.thumbnailUrl,
    this.channelName,
    this.channelHandle,
    required this.status,
    required this.visibility,
    this.duration,
    required this.viewsCount,
    required this.likesCount,
    required this.commentsCount,
    required this.downloadsCount,
    required this.sharesCount,
    this.publishedAt,
  });

  factory PlatformTopVideoItem.fromJson(Map<String, dynamic> json) {
    return PlatformTopVideoItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      channelName: json['channelName'] as String?,
      channelHandle: json['channelHandle'] as String?,
      status: json['status'] as String? ?? 'READY',
      visibility: json['visibility'] as String? ?? 'PUBLIC',
      duration: (json['duration'] as num?)?.toDouble(),
      viewsCount: (json['viewsCount'] as num?)?.toInt() ?? 0,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      downloadsCount: (json['downloadsCount'] as num?)?.toInt() ?? 0,
      sharesCount: (json['sharesCount'] as num?)?.toInt() ?? 0,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String)
          : null,
    );
  }
}

class PlatformTopVideosOverview {
  final List<PlatformTopVideoItem> byLikes;
  final List<PlatformTopVideoItem> byComments;
  final List<PlatformTopVideoItem> byViews;
  final List<PlatformTopVideoItem> byDownloads;

  const PlatformTopVideosOverview({
    required this.byLikes,
    required this.byComments,
    required this.byViews,
    required this.byDownloads,
  });

  factory PlatformTopVideosOverview.fromJson(Map<String, dynamic> json) {
    List<PlatformTopVideoItem> parseList(String key) {
      final raw = json[key] as List<dynamic>? ?? [];
      return raw
          .map((e) => PlatformTopVideoItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return PlatformTopVideosOverview(
      byLikes: parseList('byLikes'),
      byComments: parseList('byComments'),
      byViews: parseList('byViews'),
      byDownloads: parseList('byDownloads'),
    );
  }
}

class PlatformLiveStreamItem {
  final String id;
  final String title;
  final String slug;
  final String status;
  final String? channelName;
  final int currentViewerCount;
  final int peakViewerCount;
  final int totalViewerCount;
  final int likesCount;
  final int totalChatMessages;
  final int totalReactions;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const PlatformLiveStreamItem({
    required this.id,
    required this.title,
    required this.slug,
    required this.status,
    this.channelName,
    required this.currentViewerCount,
    required this.peakViewerCount,
    required this.totalViewerCount,
    required this.likesCount,
    required this.totalChatMessages,
    required this.totalReactions,
    this.startedAt,
    this.endedAt,
  });

  factory PlatformLiveStreamItem.fromJson(Map<String, dynamic> json) {
    return PlatformLiveStreamItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      status: json['status'] as String? ?? 'DRAFT',
      channelName: json['channelName'] as String?,
      currentViewerCount: (json['currentViewerCount'] as num?)?.toInt() ?? 0,
      peakViewerCount: (json['peakViewerCount'] as num?)?.toInt() ?? 0,
      totalViewerCount: (json['totalViewerCount'] as num?)?.toInt() ?? 0,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      totalChatMessages: (json['totalChatMessages'] as num?)?.toInt() ?? 0,
      totalReactions: (json['totalReactions'] as num?)?.toInt() ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'] as String)
          : null,
    );
  }
}

class PlatformLiveStreamsOverview {
  final int total;
  final int liveNow;
  final int ended;
  final int scheduled;
  final int currentViewers;
  final int peakViewersMax;
  final int totalViewerJoins;
  final int uniqueViewerRecords;
  final int totalChatMessages;
  final int totalReactions;
  final int totalLikes;
  final List<PlatformLiveStreamItem> recentAndActive;

  const PlatformLiveStreamsOverview({
    required this.total,
    required this.liveNow,
    required this.ended,
    required this.scheduled,
    required this.currentViewers,
    required this.peakViewersMax,
    required this.totalViewerJoins,
    required this.uniqueViewerRecords,
    required this.totalChatMessages,
    required this.totalReactions,
    required this.totalLikes,
    required this.recentAndActive,
  });

  factory PlatformLiveStreamsOverview.fromJson(Map<String, dynamic> json) {
    final rawList = json['recentAndActive'] as List<dynamic>? ?? [];
    return PlatformLiveStreamsOverview(
      total: (json['total'] as num?)?.toInt() ?? 0,
      liveNow: (json['liveNow'] as num?)?.toInt() ?? 0,
      ended: (json['ended'] as num?)?.toInt() ?? 0,
      scheduled: (json['scheduled'] as num?)?.toInt() ?? 0,
      currentViewers: (json['currentViewers'] as num?)?.toInt() ?? 0,
      peakViewersMax: (json['peakViewersMax'] as num?)?.toInt() ?? 0,
      totalViewerJoins: (json['totalViewerJoins'] as num?)?.toInt() ?? 0,
      uniqueViewerRecords: (json['uniqueViewerRecords'] as num?)?.toInt() ?? 0,
      totalChatMessages: (json['totalChatMessages'] as num?)?.toInt() ?? 0,
      totalReactions: (json['totalReactions'] as num?)?.toInt() ?? 0,
      totalLikes: (json['totalLikes'] as num?)?.toInt() ?? 0,
      recentAndActive: rawList
          .map((e) => PlatformLiveStreamItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PlatformTotalsOverview {
  final int totalPosts;
  final int totalStories;
  final int totalBooks;
  final int totalFiles;
  final int totalStorageBytes;
  final int totalAbuseReports;
  final int pendingAbuseReports;

  const PlatformTotalsOverview({
    required this.totalPosts,
    required this.totalStories,
    required this.totalBooks,
    required this.totalFiles,
    required this.totalStorageBytes,
    required this.totalAbuseReports,
    required this.pendingAbuseReports,
  });

  factory PlatformTotalsOverview.fromJson(Map<String, dynamic> json) {
    return PlatformTotalsOverview(
      totalPosts: (json['totalPosts'] as num?)?.toInt() ?? 0,
      totalStories: (json['totalStories'] as num?)?.toInt() ?? 0,
      totalBooks: (json['totalBooks'] as num?)?.toInt() ?? 0,
      totalFiles: (json['totalFiles'] as num?)?.toInt() ?? 0,
      totalStorageBytes: (json['totalStorageBytes'] as num?)?.toInt() ?? 0,
      totalAbuseReports: (json['totalAbuseReports'] as num?)?.toInt() ?? 0,
      pendingAbuseReports: (json['pendingAbuseReports'] as num?)?.toInt() ?? 0,
    );
  }
}

class PlatformOverviewModel {
  final DateTime? generatedAt;
  final PlatformUsersOverview? users;
  final PlatformGroupsOverview? groups;
  final PlatformChannelsOverview? channels;
  final PlatformVideosOverview? videos;
  final PlatformTopVideosOverview? topVideos;
  final PlatformLiveStreamsOverview? liveStreams;
  final PlatformTotalsOverview? platformTotals;

  const PlatformOverviewModel({
    this.generatedAt,
    this.users,
    this.groups,
    this.channels,
    this.videos,
    this.topVideos,
    this.liveStreams,
    this.platformTotals,
  });

  factory PlatformOverviewModel.fromJson(Map<String, dynamic> json) {
    return PlatformOverviewModel(
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'] as String)
          : null,
      users: json['users'] != null
          ? PlatformUsersOverview.fromJson(json['users'] as Map<String, dynamic>)
          : null,
      groups: json['groups'] != null
          ? PlatformGroupsOverview.fromJson(json['groups'] as Map<String, dynamic>)
          : null,
      channels: json['channels'] != null
          ? PlatformChannelsOverview.fromJson(json['channels'] as Map<String, dynamic>)
          : null,
      videos: json['videos'] != null
          ? PlatformVideosOverview.fromJson(json['videos'] as Map<String, dynamic>)
          : null,
      topVideos: json['topVideos'] != null
          ? PlatformTopVideosOverview.fromJson(json['topVideos'] as Map<String, dynamic>)
          : null,
      liveStreams: json['liveStreams'] != null
          ? PlatformLiveStreamsOverview.fromJson(json['liveStreams'] as Map<String, dynamic>)
          : null,
      platformTotals: json['platformTotals'] != null
          ? PlatformTotalsOverview.fromJson(json['platformTotals'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PublicSystemReportModel {
  final String id;
  final String title;
  final String? summary;
  final String? notes;
  final int revision;
  final DateTime publishedAt;
  final String displayMode;
  final PublicServerInfo? server;
  final PublicDatabaseInfo? database;
  final PublicApiInfo? api;
  final PublicDeploymentInfo? deployment;
  final List<PublicCostItem> costs;
  final PlatformOverviewModel? overview;
  final bool hasDismissed;

  const PublicSystemReportModel({
    required this.id,
    required this.title,
    this.summary,
    this.notes,
    required this.revision,
    required this.publishedAt,
    required this.displayMode,
    this.server,
    this.database,
    this.api,
    this.deployment,
    required this.costs,
    this.overview,
    required this.hasDismissed,
  });

  bool get hasContent =>
      server != null ||
      database != null ||
      api != null ||
      deployment != null ||
      costs.isNotEmpty ||
      overview != null;

  factory PublicSystemReportModel.fromJson(Map<String, dynamic> json) {
    final rawCosts = json['costs'] as List<dynamic>? ?? [];
    return PublicSystemReportModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'System Infrastructure & Operations Report',
      summary: json['summary'] as String?,
      notes: json['notes'] as String?,
      revision: (json['revision'] as num?)?.toInt() ?? 1,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      displayMode: json['displayMode'] as String? ?? 'SETTINGS_ONLY',
      server: json['server'] != null
          ? PublicServerInfo.fromJson(json['server'] as Map<String, dynamic>)
          : null,
      database: json['database'] != null
          ? PublicDatabaseInfo.fromJson(json['database'] as Map<String, dynamic>)
          : null,
      api: json['api'] != null
          ? PublicApiInfo.fromJson(json['api'] as Map<String, dynamic>)
          : null,
      deployment: json['deployment'] != null
          ? PublicDeploymentInfo.fromJson(json['deployment'] as Map<String, dynamic>)
          : null,
      costs: rawCosts
          .map((c) => PublicCostItem.fromJson(c as Map<String, dynamic>))
          .toList(),
      overview: json['overview'] != null
          ? PlatformOverviewModel.fromJson(json['overview'] as Map<String, dynamic>)
          : null,
      hasDismissed: json['hasDismissed'] as bool? ?? false,
    );
  }
}
