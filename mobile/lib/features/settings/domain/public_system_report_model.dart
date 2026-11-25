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
    required this.hasDismissed,
  });

  bool get hasContent =>
      server != null ||
      database != null ||
      api != null ||
      deployment != null ||
      costs.isNotEmpty;

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
      hasDismissed: json['hasDismissed'] as bool? ?? false,
    );
  }
}
