// lib/features/admin/domain/system_report_model.dart

class SystemServiceCostModel {
  final String id;
  final String reportId;
  final String serviceName;
  final String category;
  final String? provider;
  final double amount;
  final String currency;
  final String billingPeriod;
  final String costType;
  final String? description;
  final DateTime? lastUpdatedDate;
  final bool isVisible;

  const SystemServiceCostModel({
    required this.id,
    required this.reportId,
    required this.serviceName,
    required this.category,
    this.provider,
    required this.amount,
    required this.currency,
    required this.billingPeriod,
    required this.costType,
    this.description,
    this.lastUpdatedDate,
    required this.isVisible,
  });

  factory SystemServiceCostModel.fromJson(Map<String, dynamic> json) {
    return SystemServiceCostModel(
      id: json['id'] as String? ?? '',
      reportId: json['reportId'] as String? ?? '',
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
      isVisible: json['isVisible'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'serviceName': serviceName,
      'category': category,
      if (provider != null) 'provider': provider,
      'amount': amount,
      'currency': currency,
      'billingPeriod': billingPeriod,
      'costType': costType,
      if (description != null) 'description': description,
      if (lastUpdatedDate != null)
        'lastUpdatedDate': lastUpdatedDate!.toIso8601String(),
      'isVisible': isVisible,
    };
  }
}

class SystemReportAdminModel {
  final String id;
  final String title;
  final String? summary;
  final String? notes;
  final String status;
  final int revision;
  final DateTime? publishedAt;
  final DateTime? unpublishedAt;
  final String? createdById;
  final String? updatedById;

  // Global Visibility Control
  final bool enableUserVisibility;
  final String displayMode;

  // Category Visibility Flags
  final bool displayServerInfo;
  final bool displayServerCosts;
  final bool displayDatabaseInfo;
  final bool displayDatabaseCosts;
  final bool displayApiInfo;
  final bool displayApiCosts;
  final bool displayDeploymentInfo;
  final bool displayDeploymentCosts;
  final bool displayStorageInfo;
  final bool displayBackupInfo;
  final bool displayMaintenanceInfo;
  final bool displayUptimeInfo;
  final bool displayAdditionalCosts;

  // Server Fields
  final String? serverProvider;
  final String? serverServiceName;
  final String? serverLocation;
  final String? serverRegion;
  final String? serverPlan;
  final String? serverHostingType;
  final String? serverCpu;
  final String? serverRam;
  final String? serverDiskCapacity;
  final String? serverAvailableStorage;
  final String? serverStatus;
  final String? serverHealth;
  final String? serverUptime;
  final String? serverMaintenanceInfo;
  final String? serverBackupConfig;
  final String? serverBackupStorage;
  final double? serverMonthlyCost;
  final double? serverYearlyCost;
  final String serverCostCurrency;

  // Server Field Visibility Flags
  final bool showServerProvider;
  final bool showServerServiceName;
  final bool showServerLocation;
  final bool showServerRegion;
  final bool showServerPlan;
  final bool showServerHostingType;
  final bool showServerCpu;
  final bool showServerRam;
  final bool showServerDiskCapacity;
  final bool showServerAvailableStorage;
  final bool showServerStatus;
  final bool showServerHealth;
  final bool showServerUptime;
  final bool showServerMaintenanceInfo;
  final bool showServerBackupConfig;
  final bool showServerBackupStorage;
  final bool showServerMonthlyCost;
  final bool showServerYearlyCost;

  // Database Fields
  final String? dbProvider;
  final String? dbEngine;
  final String? dbHostingPlan;
  final String? dbInfrastructure;
  final String? dbStorageUsage;
  final String? dbStorageCapacity;
  final String? dbBackupStatus;
  final String? dbHealth;
  final String? dbAvailability;
  final double? dbMonthlyCost;
  final double? dbYearlyCost;
  final String dbCostCurrency;

  // Database Field Visibility Flags
  final bool showDbProvider;
  final bool showDbEngine;
  final bool showDbHostingPlan;
  final bool showDbInfrastructure;
  final bool showDbStorageUsage;
  final bool showDbStorageCapacity;
  final bool showDbBackupStatus;
  final bool showDbHealth;
  final bool showDbAvailability;
  final bool showDbMonthlyCost;
  final bool showDbYearlyCost;

  // API Fields
  final String? apiServiceName;
  final String? apiAvailability;
  final String? apiStatus;
  final String? apiResponseTime;
  final String? apiUsageStats;
  final double? apiHostingCost;
  final double? apiExternalCost;
  final String apiCostCurrency;

  // API Field Visibility Flags
  final bool showApiServiceName;
  final bool showApiAvailability;
  final bool showApiStatus;
  final bool showApiResponseTime;
  final bool showApiUsageStats;
  final bool showApiHostingCost;
  final bool showApiExternalCost;

  // Deployment Fields
  final String? deploymentProvider;
  final String? deploymentEnvironment;
  final String? appVersion;
  final DateTime? lastDeploymentDate;
  final String? buildStatus;
  final double? deploymentCost;
  final String deploymentCostCurrency;
  final String? environmentInfo;

  // Deployment Field Visibility Flags
  final bool showDeploymentProvider;
  final bool showDeploymentEnvironment;
  final bool showAppVersion;
  final bool showLastDeploymentDate;
  final bool showBuildStatus;
  final bool showDeploymentCost;
  final bool showEnvironmentInfo;

  // Costs
  final List<SystemServiceCostModel> costs;

  const SystemReportAdminModel({
    required this.id,
    required this.title,
    this.summary,
    this.notes,
    required this.status,
    required this.revision,
    this.publishedAt,
    this.unpublishedAt,
    this.createdById,
    this.updatedById,
    required this.enableUserVisibility,
    required this.displayMode,
    required this.displayServerInfo,
    required this.displayServerCosts,
    required this.displayDatabaseInfo,
    required this.displayDatabaseCosts,
    required this.displayApiInfo,
    required this.displayApiCosts,
    required this.displayDeploymentInfo,
    required this.displayDeploymentCosts,
    required this.displayStorageInfo,
    required this.displayBackupInfo,
    required this.displayMaintenanceInfo,
    required this.displayUptimeInfo,
    required this.displayAdditionalCosts,
    this.serverProvider,
    this.serverServiceName,
    this.serverLocation,
    this.serverRegion,
    this.serverPlan,
    this.serverHostingType,
    this.serverCpu,
    this.serverRam,
    this.serverDiskCapacity,
    this.serverAvailableStorage,
    this.serverStatus,
    this.serverHealth,
    this.serverUptime,
    this.serverMaintenanceInfo,
    this.serverBackupConfig,
    this.serverBackupStorage,
    this.serverMonthlyCost,
    this.serverYearlyCost,
    required this.serverCostCurrency,
    required this.showServerProvider,
    required this.showServerServiceName,
    required this.showServerLocation,
    required this.showServerRegion,
    required this.showServerPlan,
    required this.showServerHostingType,
    required this.showServerCpu,
    required this.showServerRam,
    required this.showServerDiskCapacity,
    required this.showServerAvailableStorage,
    required this.showServerStatus,
    required this.showServerHealth,
    required this.showServerUptime,
    required this.showServerMaintenanceInfo,
    required this.showServerBackupConfig,
    required this.showServerBackupStorage,
    required this.showServerMonthlyCost,
    required this.showServerYearlyCost,
    this.dbProvider,
    this.dbEngine,
    this.dbHostingPlan,
    this.dbInfrastructure,
    this.dbStorageUsage,
    this.dbStorageCapacity,
    this.dbBackupStatus,
    this.dbHealth,
    this.dbAvailability,
    this.dbMonthlyCost,
    this.dbYearlyCost,
    required this.dbCostCurrency,
    required this.showDbProvider,
    required this.showDbEngine,
    required this.showDbHostingPlan,
    required this.showDbInfrastructure,
    required this.showDbStorageUsage,
    required this.showDbStorageCapacity,
    required this.showDbBackupStatus,
    required this.showDbHealth,
    required this.showDbAvailability,
    required this.showDbMonthlyCost,
    required this.showDbYearlyCost,
    this.apiServiceName,
    this.apiAvailability,
    this.apiStatus,
    this.apiResponseTime,
    this.apiUsageStats,
    this.apiHostingCost,
    this.apiExternalCost,
    required this.apiCostCurrency,
    required this.showApiServiceName,
    required this.showApiAvailability,
    required this.showApiStatus,
    required this.showApiResponseTime,
    required this.showApiUsageStats,
    required this.showApiHostingCost,
    required this.showApiExternalCost,
    this.deploymentProvider,
    this.deploymentEnvironment,
    this.appVersion,
    this.lastDeploymentDate,
    this.buildStatus,
    this.deploymentCost,
    required this.deploymentCostCurrency,
    this.environmentInfo,
    required this.showDeploymentProvider,
    required this.showDeploymentEnvironment,
    required this.showAppVersion,
    required this.showLastDeploymentDate,
    required this.showBuildStatus,
    required this.showDeploymentCost,
    required this.showEnvironmentInfo,
    required this.costs,
  });

  factory SystemReportAdminModel.fromJson(Map<String, dynamic> json) {
    final rawCosts = json['costs'] as List<dynamic>? ?? [];
    return SystemReportAdminModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'System Infrastructure & Operations Report',
      summary: json['summary'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      revision: (json['revision'] as num?)?.toInt() ?? 1,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String)
          : null,
      unpublishedAt: json['unpublishedAt'] != null
          ? DateTime.tryParse(json['unpublishedAt'] as String)
          : null,
      createdById: json['createdById'] as String?,
      updatedById: json['updatedById'] as String?,
      enableUserVisibility: json['enableUserVisibility'] as bool? ?? false,
      displayMode: json['displayMode'] as String? ?? 'SETTINGS_ONLY',
      displayServerInfo: json['displayServerInfo'] as bool? ?? false,
      displayServerCosts: json['displayServerCosts'] as bool? ?? false,
      displayDatabaseInfo: json['displayDatabaseInfo'] as bool? ?? false,
      displayDatabaseCosts: json['displayDatabaseCosts'] as bool? ?? false,
      displayApiInfo: json['displayApiInfo'] as bool? ?? false,
      displayApiCosts: json['displayApiCosts'] as bool? ?? false,
      displayDeploymentInfo: json['displayDeploymentInfo'] as bool? ?? false,
      displayDeploymentCosts: json['displayDeploymentCosts'] as bool? ?? false,
      displayStorageInfo: json['displayStorageInfo'] as bool? ?? false,
      displayBackupInfo: json['displayBackupInfo'] as bool? ?? false,
      displayMaintenanceInfo: json['displayMaintenanceInfo'] as bool? ?? false,
      displayUptimeInfo: json['displayUptimeInfo'] as bool? ?? false,
      displayAdditionalCosts: json['displayAdditionalCosts'] as bool? ?? false,

      // Server
      serverProvider: json['serverProvider'] as String?,
      serverServiceName: json['serverServiceName'] as String?,
      serverLocation: json['serverLocation'] as String?,
      serverRegion: json['serverRegion'] as String?,
      serverPlan: json['serverPlan'] as String?,
      serverHostingType: json['serverHostingType'] as String?,
      serverCpu: json['serverCpu'] as String?,
      serverRam: json['serverRam'] as String?,
      serverDiskCapacity: json['serverDiskCapacity'] as String?,
      serverAvailableStorage: json['serverAvailableStorage'] as String?,
      serverStatus: json['serverStatus'] as String?,
      serverHealth: json['serverHealth'] as String?,
      serverUptime: json['serverUptime'] as String?,
      serverMaintenanceInfo: json['serverMaintenanceInfo'] as String?,
      serverBackupConfig: json['serverBackupConfig'] as String?,
      serverBackupStorage: json['serverBackupStorage'] as String?,
      serverMonthlyCost: (json['serverMonthlyCost'] as num?)?.toDouble(),
      serverYearlyCost: (json['serverYearlyCost'] as num?)?.toDouble(),
      serverCostCurrency: json['serverCostCurrency'] as String? ?? 'USD',

      showServerProvider: json['showServerProvider'] as bool? ?? false,
      showServerServiceName: json['showServerServiceName'] as bool? ?? false,
      showServerLocation: json['showServerLocation'] as bool? ?? false,
      showServerRegion: json['showServerRegion'] as bool? ?? false,
      showServerPlan: json['showServerPlan'] as bool? ?? false,
      showServerHostingType: json['showServerHostingType'] as bool? ?? false,
      showServerCpu: json['showServerCpu'] as bool? ?? false,
      showServerRam: json['showServerRam'] as bool? ?? false,
      showServerDiskCapacity: json['showServerDiskCapacity'] as bool? ?? false,
      showServerAvailableStorage: json['showServerAvailableStorage'] as bool? ?? false,
      showServerStatus: json['showServerStatus'] as bool? ?? false,
      showServerHealth: json['showServerHealth'] as bool? ?? false,
      showServerUptime: json['showServerUptime'] as bool? ?? false,
      showServerMaintenanceInfo: json['showServerMaintenanceInfo'] as bool? ?? false,
      showServerBackupConfig: json['showServerBackupConfig'] as bool? ?? false,
      showServerBackupStorage: json['showServerBackupStorage'] as bool? ?? false,
      showServerMonthlyCost: json['showServerMonthlyCost'] as bool? ?? false,
      showServerYearlyCost: json['showServerYearlyCost'] as bool? ?? false,

      // Database
      dbProvider: json['dbProvider'] as String?,
      dbEngine: json['dbEngine'] as String?,
      dbHostingPlan: json['dbHostingPlan'] as String?,
      dbInfrastructure: json['dbInfrastructure'] as String?,
      dbStorageUsage: json['dbStorageUsage'] as String?,
      dbStorageCapacity: json['dbStorageCapacity'] as String?,
      dbBackupStatus: json['dbBackupStatus'] as String?,
      dbHealth: json['dbHealth'] as String?,
      dbAvailability: json['dbAvailability'] as String?,
      dbMonthlyCost: (json['dbMonthlyCost'] as num?)?.toDouble(),
      dbYearlyCost: (json['dbYearlyCost'] as num?)?.toDouble(),
      dbCostCurrency: json['dbCostCurrency'] as String? ?? 'USD',

      showDbProvider: json['showDbProvider'] as bool? ?? false,
      showDbEngine: json['showDbEngine'] as bool? ?? false,
      showDbHostingPlan: json['showDbHostingPlan'] as bool? ?? false,
      showDbInfrastructure: json['showDbInfrastructure'] as bool? ?? false,
      showDbStorageUsage: json['showDbStorageUsage'] as bool? ?? false,
      showDbStorageCapacity: json['showDbStorageCapacity'] as bool? ?? false,
      showDbBackupStatus: json['showDbBackupStatus'] as bool? ?? false,
      showDbHealth: json['showDbHealth'] as bool? ?? false,
      showDbAvailability: json['showDbAvailability'] as bool? ?? false,
      showDbMonthlyCost: json['showDbMonthlyCost'] as bool? ?? false,
      showDbYearlyCost: json['showDbYearlyCost'] as bool? ?? false,

      // API
      apiServiceName: json['apiServiceName'] as String?,
      apiAvailability: json['apiAvailability'] as String?,
      apiStatus: json['apiStatus'] as String?,
      apiResponseTime: json['apiResponseTime'] as String?,
      apiUsageStats: json['apiUsageStats'] as String?,
      apiHostingCost: (json['apiHostingCost'] as num?)?.toDouble(),
      apiExternalCost: (json['apiExternalCost'] as num?)?.toDouble(),
      apiCostCurrency: json['apiCostCurrency'] as String? ?? 'USD',

      showApiServiceName: json['showApiServiceName'] as bool? ?? false,
      showApiAvailability: json['showApiAvailability'] as bool? ?? false,
      showApiStatus: json['showApiStatus'] as bool? ?? false,
      showApiResponseTime: json['showApiResponseTime'] as bool? ?? false,
      showApiUsageStats: json['showApiUsageStats'] as bool? ?? false,
      showApiHostingCost: json['showApiHostingCost'] as bool? ?? false,
      showApiExternalCost: json['showApiExternalCost'] as bool? ?? false,

      // Deployment
      deploymentProvider: json['deploymentProvider'] as String?,
      deploymentEnvironment: json['deploymentEnvironment'] as String?,
      appVersion: json['appVersion'] as String?,
      lastDeploymentDate: json['lastDeploymentDate'] != null
          ? DateTime.tryParse(json['lastDeploymentDate'] as String)
          : null,
      buildStatus: json['buildStatus'] as String?,
      deploymentCost: (json['deploymentCost'] as num?)?.toDouble(),
      deploymentCostCurrency: json['deploymentCostCurrency'] as String? ?? 'USD',
      environmentInfo: json['environmentInfo'] as String?,

      showDeploymentProvider: json['showDeploymentProvider'] as bool? ?? false,
      showDeploymentEnvironment: json['showDeploymentEnvironment'] as bool? ?? false,
      showAppVersion: json['showAppVersion'] as bool? ?? false,
      showLastDeploymentDate: json['showLastDeploymentDate'] as bool? ?? false,
      showBuildStatus: json['showBuildStatus'] as bool? ?? false,
      showDeploymentCost: json['showDeploymentCost'] as bool? ?? false,
      showEnvironmentInfo: json['showEnvironmentInfo'] as bool? ?? false,

      costs: rawCosts
          .map((c) => SystemServiceCostModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
