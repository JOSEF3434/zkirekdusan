// lib/features/admin/presentation/screens/admin_system_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/domain/system_report_model.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/admin/presentation/providers/admin_system_report_provider.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_status_badge.dart';
import 'package:mobile/features/settings/presentation/screens/user_system_report_screen.dart';
import 'package:mobile/features/settings/presentation/widgets/platform_overview_view.dart';

class AdminSystemReportScreen extends ConsumerStatefulWidget {
  const AdminSystemReportScreen({super.key});

  @override
  ConsumerState<AdminSystemReportScreen> createState() =>
      _AdminSystemReportScreenState();
}

class _AdminSystemReportScreenState
    extends ConsumerState<AdminSystemReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // General & Server Controllers
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _notesController = TextEditingController();

  final _serverProviderController = TextEditingController();
  final _serverServiceNameController = TextEditingController();
  final _serverLocationController = TextEditingController();
  final _serverRegionController = TextEditingController();
  final _serverPlanController = TextEditingController();
  final _serverHostingTypeController = TextEditingController();
  final _serverCpuController = TextEditingController();
  final _serverRamController = TextEditingController();
  final _serverDiskCapacityController = TextEditingController();
  final _serverAvailableStorageController = TextEditingController();
  final _serverStatusController = TextEditingController();
  final _serverHealthController = TextEditingController();
  final _serverUptimeController = TextEditingController();
  final _serverMaintenanceInfoController = TextEditingController();
  final _serverBackupConfigController = TextEditingController();
  final _serverBackupStorageController = TextEditingController();
  final _serverMonthlyCostController = TextEditingController();
  final _serverYearlyCostController = TextEditingController();
  String _serverCurrency = 'USD';

  // Database Controllers
  final _dbProviderController = TextEditingController();
  final _dbEngineController = TextEditingController();
  final _dbHostingPlanController = TextEditingController();
  final _dbInfrastructureController = TextEditingController();
  final _dbStorageUsageController = TextEditingController();
  final _dbStorageCapacityController = TextEditingController();
  final _dbBackupStatusController = TextEditingController();
  final _dbHealthController = TextEditingController();
  final _dbAvailabilityController = TextEditingController();
  final _dbMonthlyCostController = TextEditingController();
  final _dbYearlyCostController = TextEditingController();
  String _dbCurrency = 'USD';

  // API Controllers
  final _apiServiceNameController = TextEditingController();
  final _apiAvailabilityController = TextEditingController();
  final _apiStatusController = TextEditingController();
  final _apiResponseTimeController = TextEditingController();
  final _apiUsageStatsController = TextEditingController();
  final _apiHostingCostController = TextEditingController();
  final _apiExternalCostController = TextEditingController();
  String _apiCurrency = 'USD';

  // Deployment Controllers
  final _deploymentProviderController = TextEditingController();
  final _deploymentEnvController = TextEditingController();
  final _appVersionController = TextEditingController();
  final _buildStatusController = TextEditingController();
  final _deploymentCostController = TextEditingController();
  final _environmentInfoController = TextEditingController();
  String _deploymentCurrency = 'USD';
  DateTime? _lastDeploymentDate;

  // Visibility state
  bool _enableUserVisibility = false;
  String _displayMode = 'SETTINGS_ONLY';

  bool _displayServerInfo = false;
  bool _displayServerCosts = false;
  bool _displayDatabaseInfo = false;
  bool _displayDatabaseCosts = false;
  bool _displayApiInfo = false;
  bool _displayApiCosts = false;
  bool _displayDeploymentInfo = false;
  bool _displayDeploymentCosts = false;
  bool _displayAdditionalCosts = false;

  // Individual Server field switches
  bool _showServerProvider = false;
  bool _showServerServiceName = false;
  bool _showServerLocation = false;
  bool _showServerRegion = false;
  bool _showServerPlan = false;
  bool _showServerHostingType = false;
  bool _showServerCpu = false;
  bool _showServerRam = false;
  bool _showServerDiskCapacity = false;
  bool _showServerAvailableStorage = false;
  bool _showServerStatus = false;
  bool _showServerHealth = false;
  bool _showServerUptime = false;
  bool _showServerMaintenanceInfo = false;
  bool _showServerBackupConfig = false;
  bool _showServerBackupStorage = false;
  bool _showServerMonthlyCost = false;
  bool _showServerYearlyCost = false;

  // Individual Database field switches
  bool _showDbProvider = false;
  bool _showDbEngine = false;
  bool _showDbHostingPlan = false;
  bool _showDbInfrastructure = false;
  bool _showDbStorageUsage = false;
  bool _showDbStorageCapacity = false;
  bool _showDbBackupStatus = false;
  bool _showDbHealth = false;
  bool _showDbAvailability = false;
  bool _showDbMonthlyCost = false;
  bool _showDbYearlyCost = false;

  // Individual API field switches
  bool _showApiServiceName = false;
  bool _showApiAvailability = false;
  bool _showApiStatus = false;
  bool _showApiResponseTime = false;
  bool _showApiUsageStats = false;
  bool _showApiHostingCost = false;
  bool _showApiExternalCost = false;

  // Individual Deployment field switches
  bool _showDeploymentProvider = false;
  bool _showDeploymentEnvironment = false;
  bool _showAppVersion = false;
  bool _showLastDeploymentDate = false;
  bool _showBuildStatus = false;
  bool _showDeploymentCost = false;
  bool _showEnvironmentInfo = false;

  // Platform Overview visibility switches
  bool _displayPlatformOverview = false;
  bool _showUsersOverview = false;
  bool _showGroupsOverview = false;
  bool _showChannelsOverview = false;
  bool _showVideosOverview = false;
  bool _showTopVideosOverview = false;
  bool _showLiveStreamsOverview = false;

  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    _notesController.dispose();

    _serverProviderController.dispose();
    _serverServiceNameController.dispose();
    _serverLocationController.dispose();
    _serverRegionController.dispose();
    _serverPlanController.dispose();
    _serverHostingTypeController.dispose();
    _serverCpuController.dispose();
    _serverRamController.dispose();
    _serverDiskCapacityController.dispose();
    _serverAvailableStorageController.dispose();
    _serverStatusController.dispose();
    _serverHealthController.dispose();
    _serverUptimeController.dispose();
    _serverMaintenanceInfoController.dispose();
    _serverBackupConfigController.dispose();
    _serverBackupStorageController.dispose();
    _serverMonthlyCostController.dispose();
    _serverYearlyCostController.dispose();

    _dbProviderController.dispose();
    _dbEngineController.dispose();
    _dbHostingPlanController.dispose();
    _dbInfrastructureController.dispose();
    _dbStorageUsageController.dispose();
    _dbStorageCapacityController.dispose();
    _dbBackupStatusController.dispose();
    _dbHealthController.dispose();
    _dbAvailabilityController.dispose();
    _dbMonthlyCostController.dispose();
    _dbYearlyCostController.dispose();

    _apiServiceNameController.dispose();
    _apiAvailabilityController.dispose();
    _apiStatusController.dispose();
    _apiResponseTimeController.dispose();
    _apiUsageStatsController.dispose();
    _apiHostingCostController.dispose();
    _apiExternalCostController.dispose();

    _deploymentProviderController.dispose();
    _deploymentEnvController.dispose();
    _appVersionController.dispose();
    _buildStatusController.dispose();
    _deploymentCostController.dispose();
    _environmentInfoController.dispose();
    super.dispose();
  }

  void _populateFromModel(SystemReportAdminModel m) {
    if (_isInitialized) return;
    _isInitialized = true;

    _titleController.text = m.title;
    _summaryController.text = m.summary ?? '';
    _notesController.text = m.notes ?? '';

    // Server
    _serverProviderController.text = m.serverProvider ?? '';
    _serverServiceNameController.text = m.serverServiceName ?? '';
    _serverLocationController.text = m.serverLocation ?? '';
    _serverRegionController.text = m.serverRegion ?? '';
    _serverPlanController.text = m.serverPlan ?? '';
    _serverHostingTypeController.text = m.serverHostingType ?? '';
    _serverCpuController.text = m.serverCpu ?? '';
    _serverRamController.text = m.serverRam ?? '';
    _serverDiskCapacityController.text = m.serverDiskCapacity ?? '';
    _serverAvailableStorageController.text = m.serverAvailableStorage ?? '';
    _serverStatusController.text = m.serverStatus ?? '';
    _serverHealthController.text = m.serverHealth ?? '';
    _serverUptimeController.text = m.serverUptime ?? '';
    _serverMaintenanceInfoController.text = m.serverMaintenanceInfo ?? '';
    _serverBackupConfigController.text = m.serverBackupConfig ?? '';
    _serverBackupStorageController.text = m.serverBackupStorage ?? '';
    _serverMonthlyCostController.text = m.serverMonthlyCost?.toString() ?? '';
    _serverYearlyCostController.text = m.serverYearlyCost?.toString() ?? '';
    _serverCurrency = m.serverCostCurrency;

    // Database
    _dbProviderController.text = m.dbProvider ?? '';
    _dbEngineController.text = m.dbEngine ?? '';
    _dbHostingPlanController.text = m.dbHostingPlan ?? '';
    _dbInfrastructureController.text = m.dbInfrastructure ?? '';
    _dbStorageUsageController.text = m.dbStorageUsage ?? '';
    _dbStorageCapacityController.text = m.dbStorageCapacity ?? '';
    _dbBackupStatusController.text = m.dbBackupStatus ?? '';
    _dbHealthController.text = m.dbHealth ?? '';
    _dbAvailabilityController.text = m.dbAvailability ?? '';
    _dbMonthlyCostController.text = m.dbMonthlyCost?.toString() ?? '';
    _dbYearlyCostController.text = m.dbYearlyCost?.toString() ?? '';
    _dbCurrency = m.dbCostCurrency;

    // API
    _apiServiceNameController.text = m.apiServiceName ?? '';
    _apiAvailabilityController.text = m.apiAvailability ?? '';
    _apiStatusController.text = m.apiStatus ?? '';
    _apiResponseTimeController.text = m.apiResponseTime ?? '';
    _apiUsageStatsController.text = m.apiUsageStats ?? '';
    _apiHostingCostController.text = m.apiHostingCost?.toString() ?? '';
    _apiExternalCostController.text = m.apiExternalCost?.toString() ?? '';
    _apiCurrency = m.apiCostCurrency;

    // Deployment
    _deploymentProviderController.text = m.deploymentProvider ?? '';
    _deploymentEnvController.text = m.deploymentEnvironment ?? '';
    _appVersionController.text = m.appVersion ?? '';
    _buildStatusController.text = m.buildStatus ?? '';
    _deploymentCostController.text = m.deploymentCost?.toString() ?? '';
    _environmentInfoController.text = m.environmentInfo ?? '';
    _deploymentCurrency = m.deploymentCostCurrency;
    _lastDeploymentDate = m.lastDeploymentDate;

    // Visibility
    _enableUserVisibility = m.enableUserVisibility;
    _displayMode = m.displayMode;

    _displayServerInfo = m.displayServerInfo;
    _displayServerCosts = m.displayServerCosts;
    _displayDatabaseInfo = m.displayDatabaseInfo;
    _displayDatabaseCosts = m.displayDatabaseCosts;
    _displayApiInfo = m.displayApiInfo;
    _displayApiCosts = m.displayApiCosts;
    _displayDeploymentInfo = m.displayDeploymentInfo;
    _displayDeploymentCosts = m.displayDeploymentCosts;
    _displayAdditionalCosts = m.displayAdditionalCosts;
    _displayPlatformOverview = m.displayPlatformOverview;
    _showUsersOverview = m.showUsersOverview;
    _showGroupsOverview = m.showGroupsOverview;
    _showChannelsOverview = m.showChannelsOverview;
    _showVideosOverview = m.showVideosOverview;
    _showTopVideosOverview = m.showTopVideosOverview;
    _showLiveStreamsOverview = m.showLiveStreamsOverview;

    _showServerProvider = m.showServerProvider;
    _showServerServiceName = m.showServerServiceName;
    _showServerLocation = m.showServerLocation;
    _showServerRegion = m.showServerRegion;
    _showServerPlan = m.showServerPlan;
    _showServerHostingType = m.showServerHostingType;
    _showServerCpu = m.showServerCpu;
    _showServerRam = m.showServerRam;
    _showServerDiskCapacity = m.showServerDiskCapacity;
    _showServerAvailableStorage = m.showServerAvailableStorage;
    _showServerStatus = m.showServerStatus;
    _showServerHealth = m.showServerHealth;
    _showServerUptime = m.showServerUptime;
    _showServerMaintenanceInfo = m.showServerMaintenanceInfo;
    _showServerBackupConfig = m.showServerBackupConfig;
    _showServerBackupStorage = m.showServerBackupStorage;
    _showServerMonthlyCost = m.showServerMonthlyCost;
    _showServerYearlyCost = m.showServerYearlyCost;

    _showDbProvider = m.showDbProvider;
    _showDbEngine = m.showDbEngine;
    _showDbHostingPlan = m.showDbHostingPlan;
    _showDbInfrastructure = m.showDbInfrastructure;
    _showDbStorageUsage = m.showDbStorageUsage;
    _showDbStorageCapacity = m.showDbStorageCapacity;
    _showDbBackupStatus = m.showDbBackupStatus;
    _showDbHealth = m.showDbHealth;
    _showDbAvailability = m.showDbAvailability;
    _showDbMonthlyCost = m.showDbMonthlyCost;
    _showDbYearlyCost = m.showDbYearlyCost;

    _showApiServiceName = m.showApiServiceName;
    _showApiAvailability = m.showApiAvailability;
    _showApiStatus = m.showApiStatus;
    _showApiResponseTime = m.showApiResponseTime;
    _showApiUsageStats = m.showApiUsageStats;
    _showApiHostingCost = m.showApiHostingCost;
    _showApiExternalCost = m.showApiExternalCost;

    _showDeploymentProvider = m.showDeploymentProvider;
    _showDeploymentEnvironment = m.showDeploymentEnvironment;
    _showAppVersion = m.showAppVersion;
    _showLastDeploymentDate = m.showLastDeploymentDate;
    _showBuildStatus = m.showBuildStatus;
    _showDeploymentCost = m.showDeploymentCost;
    _showEnvironmentInfo = m.showEnvironmentInfo;
  }

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(adminSystemReportProvider.notifier);

      // Save content values
      await notifier.updateReport({
        'title': _titleController.text.trim(),
        'summary': _summaryController.text.trim(),
        'notes': _notesController.text.trim(),
        'serverProvider': _serverProviderController.text.trim(),
        'serverServiceName': _serverServiceNameController.text.trim(),
        'serverLocation': _serverLocationController.text.trim(),
        'serverRegion': _serverRegionController.text.trim(),
        'serverPlan': _serverPlanController.text.trim(),
        'serverHostingType': _serverHostingTypeController.text.trim(),
        'serverCpu': _serverCpuController.text.trim(),
        'serverRam': _serverRamController.text.trim(),
        'serverDiskCapacity': _serverDiskCapacityController.text.trim(),
        'serverAvailableStorage': _serverAvailableStorageController.text.trim(),
        'serverStatus': _serverStatusController.text.trim(),
        'serverHealth': _serverHealthController.text.trim(),
        'serverUptime': _serverUptimeController.text.trim(),
        'serverMaintenanceInfo': _serverMaintenanceInfoController.text.trim(),
        'serverBackupConfig': _serverBackupConfigController.text.trim(),
        'serverBackupStorage': _serverBackupStorageController.text.trim(),
        if (_serverMonthlyCostController.text.isNotEmpty)
          'serverMonthlyCost': double.tryParse(_serverMonthlyCostController.text.trim()),
        if (_serverYearlyCostController.text.isNotEmpty)
          'serverYearlyCost': double.tryParse(_serverYearlyCostController.text.trim()),
        'serverCostCurrency': _serverCurrency,

        'dbProvider': _dbProviderController.text.trim(),
        'dbEngine': _dbEngineController.text.trim(),
        'dbHostingPlan': _dbHostingPlanController.text.trim(),
        'dbInfrastructure': _dbInfrastructureController.text.trim(),
        'dbStorageUsage': _dbStorageUsageController.text.trim(),
        'dbStorageCapacity': _dbStorageCapacityController.text.trim(),
        'dbBackupStatus': _dbBackupStatusController.text.trim(),
        'dbHealth': _dbHealthController.text.trim(),
        'dbAvailability': _dbAvailabilityController.text.trim(),
        if (_dbMonthlyCostController.text.isNotEmpty)
          'dbMonthlyCost': double.tryParse(_dbMonthlyCostController.text.trim()),
        if (_dbYearlyCostController.text.isNotEmpty)
          'dbYearlyCost': double.tryParse(_dbYearlyCostController.text.trim()),
        'dbCostCurrency': _dbCurrency,

        'apiServiceName': _apiServiceNameController.text.trim(),
        'apiAvailability': _apiAvailabilityController.text.trim(),
        'apiStatus': _apiStatusController.text.trim(),
        'apiResponseTime': _apiResponseTimeController.text.trim(),
        'apiUsageStats': _apiUsageStatsController.text.trim(),
        if (_apiHostingCostController.text.isNotEmpty)
          'apiHostingCost': double.tryParse(_apiHostingCostController.text.trim()),
        if (_apiExternalCostController.text.isNotEmpty)
          'apiExternalCost': double.tryParse(_apiExternalCostController.text.trim()),
        'apiCostCurrency': _apiCurrency,

        'deploymentProvider': _deploymentProviderController.text.trim(),
        'deploymentEnvironment': _deploymentEnvController.text.trim(),
        'appVersion': _appVersionController.text.trim(),
        'buildStatus': _buildStatusController.text.trim(),
        if (_deploymentCostController.text.isNotEmpty)
          'deploymentCost': double.tryParse(_deploymentCostController.text.trim()),
        'deploymentCostCurrency': _deploymentCurrency,
        'environmentInfo': _environmentInfoController.text.trim(),
        if (_lastDeploymentDate != null)
          'lastDeploymentDate': _lastDeploymentDate!.toIso8601String(),
      });

      // Save visibility switches
      await notifier.updateVisibility({
        'enableUserVisibility': _enableUserVisibility,
        'displayMode': _displayMode,
        'displayServerInfo': _displayServerInfo,
        'displayServerCosts': _displayServerCosts,
        'displayDatabaseInfo': _displayDatabaseInfo,
        'displayDatabaseCosts': _displayDatabaseCosts,
        'displayApiInfo': _displayApiInfo,
        'displayApiCosts': _displayApiCosts,
        'displayDeploymentInfo': _displayDeploymentInfo,
        'displayDeploymentCosts': _displayDeploymentCosts,
        'displayAdditionalCosts': _displayAdditionalCosts,

        'showServerProvider': _showServerProvider,
        'showServerServiceName': _showServerServiceName,
        'showServerLocation': _showServerLocation,
        'showServerRegion': _showServerRegion,
        'showServerPlan': _showServerPlan,
        'showServerHostingType': _showServerHostingType,
        'showServerCpu': _showServerCpu,
        'showServerRam': _showServerRam,
        'showServerDiskCapacity': _showServerDiskCapacity,
        'showServerAvailableStorage': _showServerAvailableStorage,
        'showServerStatus': _showServerStatus,
        'showServerHealth': _showServerHealth,
        'showServerUptime': _showServerUptime,
        'showServerMaintenanceInfo': _showServerMaintenanceInfo,
        'showServerBackupConfig': _showServerBackupConfig,
        'showServerBackupStorage': _showServerBackupStorage,
        'showServerMonthlyCost': _showServerMonthlyCost,
        'showServerYearlyCost': _showServerYearlyCost,

        'showDbProvider': _showDbProvider,
        'showDbEngine': _showDbEngine,
        'showDbHostingPlan': _showDbHostingPlan,
        'showDbInfrastructure': _showDbInfrastructure,
        'showDbStorageUsage': _showDbStorageUsage,
        'showDbStorageCapacity': _showDbStorageCapacity,
        'showDbBackupStatus': _showDbBackupStatus,
        'showDbHealth': _showDbHealth,
        'showDbAvailability': _showDbAvailability,
        'showDbMonthlyCost': _showDbMonthlyCost,
        'showDbYearlyCost': _showDbYearlyCost,

        'showApiServiceName': _showApiServiceName,
        'showApiAvailability': _showApiAvailability,
        'showApiStatus': _showApiStatus,
        'showApiResponseTime': _showApiResponseTime,
        'showApiUsageStats': _showApiUsageStats,
        'showApiHostingCost': _showApiHostingCost,
        'showApiExternalCost': _showApiExternalCost,

        'showDeploymentProvider': _showDeploymentProvider,
        'showDeploymentEnvironment': _showDeploymentEnvironment,
        'showAppVersion': _showAppVersion,
        'showLastDeploymentDate': _showLastDeploymentDate,
        'showBuildStatus': _showBuildStatus,
        'showDeploymentCost': _showDeploymentCost,
        'showEnvironmentInfo': _showEnvironmentInfo,

        'displayPlatformOverview': _displayPlatformOverview,
        'showUsersOverview': _showUsersOverview,
        'showGroupsOverview': _showGroupsOverview,
        'showChannelsOverview': _showChannelsOverview,
        'showVideosOverview': _showVideosOverview,
        'showTopVideosOverview': _showTopVideosOverview,
        'showLiveStreamsOverview': _showLiveStreamsOverview,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('System report and visibility settings saved successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save draft: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _publishReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish System Report?'),
        content: Text(
          _enableUserVisibility
              ? 'This will increment the report revision and publish approved visible fields to ordinary users via $_displayMode.'
              : 'Global User Visibility is currently OFF. The report will be published as Revision ${ref.read(adminSystemReportProvider).value?.revision ?? 1}, but will remain hidden from ordinary users until Global Visibility is enabled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm & Publish'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        await _saveDraft();
        await ref
            .read(adminSystemReportProvider.notifier)
            .publishReport(displayMode: _displayMode);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('System report published successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to publish report: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _unpublishReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unpublish System Report?'),
        content: const Text(
          'Unpublishing removes the report from active user visibility immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unpublish'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        await ref.read(adminSystemReportProvider.notifier).unpublishReport();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report unpublished.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _previewPublicView() async {
    try {
      final publicReport =
          await ref.read(adminSystemReportProvider.notifier).preview();
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.preview_rounded, color: Colors.blue),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User-Facing Report Preview',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Exact filtered view that ordinary users will see',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: UserSystemReportScreen(
                  previewReport: publicReport,
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate preview: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(adminPermissionsProvider);
    final reportState = ref.watch(adminSystemReportProvider);
    final tr = ref.watch(trProvider);

    if (!perms.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('admin.system_report', {'fallback': 'System Report'}))),
        body: const Center(
          child: Text('Only Administrators can configure the System Report.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.system_report', {'fallback': 'System Report Management'})),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview_outlined),
            tooltip: 'Preview Public View',
            onPressed: _previewPublicView,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save Draft',
            onPressed: _isSaving ? null : _saveDraft,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.visibility_outlined), text: 'Visibility'),
            Tab(icon: Icon(Icons.dns_outlined), text: 'Server'),
            Tab(icon: Icon(Icons.storage_outlined), text: 'Database'),
            Tab(icon: Icon(Icons.api_outlined), text: 'API Services'),
            Tab(icon: Icon(Icons.rocket_launch_outlined), text: 'Deployment'),
            Tab(icon: Icon(Icons.attach_money_outlined), text: 'Service Costs'),
          ],
        ),
      ),
      body: reportState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading report: $err')),
        data: (model) {
          _populateFromModel(model);

          return Column(
            children: [
              _buildStatusBar(model),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildVisibilityTab(model),
                    _buildServerTab(),
                    _buildDatabaseTab(),
                    _buildApiTab(),
                    _buildDeploymentTab(),
                    _buildCostsTab(model),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.preview),
                  label: const Text('Preview'),
                  onPressed: _previewPublicView,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Draft'),
                  onPressed: _isSaving ? null : _saveDraft,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.publish_rounded),
                  label: Text(_isSaving ? 'Processing...' : 'Publish'),
                  onPressed: _isSaving ? null : _publishReport,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(SystemReportAdminModel m) {
    final isPublished = m.status == 'PUBLISHED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        children: [
          AdminStatusBadge(status: m.status),
          const SizedBox(width: 8),
          Chip(
            label: Text('Rev ${m.revision}'),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text(_displayMode.replaceAll('_', ' ')),
            visualDensity: VisualDensity.compact,
          ),
          const Spacer(),
          if (isPublished)
            TextButton.icon(
              icon: const Icon(Icons.unpublished_outlined, color: Colors.orange, size: 18),
              label: const Text('Unpublish', style: TextStyle(color: Colors.orange)),
              onPressed: _isSaving ? null : _unpublishReport,
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 1. Visibility Tab (SECTION 3 REQUIREMENTS)
  // ─────────────────────────────────────────────
  Widget _buildVisibilityTab(SystemReportAdminModel m) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AdminResponsiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── GLOBAL MASTER SWITCH ──
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _enableUserVisibility ? Colors.green : Colors.red.shade300,
                  width: 2,
                ),
              ),
              color: _enableUserVisibility
                  ? Colors.green.withValues(alpha: 0.05)
                  : Colors.red.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _enableUserVisibility
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: _enableUserVisibility ? Colors.green : Colors.red,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable System Report for Users: ${_enableUserVisibility ? "ON" : "OFF"}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _enableUserVisibility
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _enableUserVisibility
                                    ? 'Global visibility is ENABLED. Only individually approved categories and fields below are displayed.'
                                    : 'Global visibility is OFF. Absolutely NO system report information is accessible or displayed to ordinary users.',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _enableUserVisibility,
                          activeThumbColor: Colors.green,
                          onChanged: (val) {
                            setState(() => _enableUserVisibility = val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── USER DISPLAY METHOD (SECTION 4) ──
            AdminSectionCard(
              title: 'User Display Method',
              subtitle: 'Control how eligible users receive and access the report',
              child: RadioGroup<String>(
                groupValue: _displayMode,
                onChanged: (val) {
                  if (val != null) setState(() => _displayMode = val);
                },
                child: const Column(
                  children: [
                    RadioListTile<String>(
                      title: Text('Settings Only'),
                      subtitle: Text(
                        'Users can view the report by navigating to Settings → System Report.',
                      ),
                      value: 'SETTINGS_ONLY',
                    ),
                    RadioListTile<String>(
                      title: Text('First-Open Popup Only'),
                      subtitle: Text(
                        'Display a professional popup when the app opens for a new revision. Once dismissed, it will not reappear.',
                      ),
                      value: 'POPUP_ONLY',
                    ),
                    RadioListTile<String>(
                      title: Text('Both (First-Open Popup + Settings)'),
                      subtitle: Text(
                        'Show first-open popup for new revisions AND keep accessible inside Settings.',
                      ),
                      value: 'BOTH',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── CATEGORY MASTER VISIBILITY SWITCHES ──
            AdminSectionCard(
              title: 'Category Display Controls',
              subtitle:
                  'Each category and every individual field must be deliberately enabled',
              child: Column(
                children: [
                  _buildVisibilitySwitch(
                    title: 'Display Server Information',
                    subtitle: 'Show hosting provider, specs, health & storage',
                    value: _displayServerInfo,
                    onChanged: (v) => setState(() => _displayServerInfo = v),
                  ),
                  _buildVisibilitySwitch(
                    title: 'Display Server Financial Costs',
                    subtitle: 'Show server hosting monthly/yearly costs to users',
                    value: _displayServerCosts,
                    isFinancial: true,
                    onChanged: (v) => setState(() => _displayServerCosts = v),
                  ),
                  const Divider(),
                  _buildVisibilitySwitch(
                    title: 'Display Database Information',
                    subtitle: 'Show database engine, capacity, backups & health',
                    value: _displayDatabaseInfo,
                    onChanged: (v) => setState(() => _displayDatabaseInfo = v),
                  ),
                  _buildVisibilitySwitch(
                    title: 'Display Database Financial Costs',
                    subtitle: 'Show database hosting monthly/yearly costs to users',
                    value: _displayDatabaseCosts,
                    isFinancial: true,
                    onChanged: (v) => setState(() => _displayDatabaseCosts = v),
                  ),
                  const Divider(),
                  _buildVisibilitySwitch(
                    title: 'Display API & Backend Information',
                    subtitle: 'Show API availability, response times & stats',
                    value: _displayApiInfo,
                    onChanged: (v) => setState(() => _displayApiInfo = v),
                  ),
                  _buildVisibilitySwitch(
                    title: 'Display API Financial Costs',
                    subtitle: 'Show backend and external API costs to users',
                    value: _displayApiCosts,
                    isFinancial: true,
                    onChanged: (v) => setState(() => _displayApiCosts = v),
                  ),
                  const Divider(),
                  _buildVisibilitySwitch(
                    title: 'Display Deployment Information',
                    subtitle: 'Show environment, version, build status & dates',
                    value: _displayDeploymentInfo,
                    onChanged: (v) => setState(() => _displayDeploymentInfo = v),
                  ),
                  _buildVisibilitySwitch(
                    title: 'Display Deployment Financial Costs',
                    subtitle: 'Show deployment and CI/CD costs to users',
                    value: _displayDeploymentCosts,
                    isFinancial: true,
                    onChanged: (v) => setState(() => _displayDeploymentCosts = v),
                  ),
                  const Divider(),
                  _buildVisibilitySwitch(
                    title: 'Display Additional Service Costs',
                    subtitle: 'Show individual service cost items (CDN, SMS, etc.)',
                    value: _displayAdditionalCosts,
                    isFinancial: true,
                    onChanged: (v) => setState(() => _displayAdditionalCosts = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── PLATFORM OVERVIEW VISIBILITY SWITCHES ──
            AdminSectionCard(
              title: 'Platform Overview Display Controls',
              subtitle:
                  'Choose whether live platform totals (users, groups, channels, top videos, live streams) appear in the public report (ALL OFF by default)',
              child: Column(
                children: [
                  _buildVisibilitySwitch(
                    title: 'Display Platform Overview Section',
                    subtitle: 'Master toggle for live platform overview statistics',
                    value: _displayPlatformOverview,
                    onChanged: (v) => setState(() => _displayPlatformOverview = v),
                  ),
                  const Divider(),
                  _buildVisibilitySwitch(
                    title: 'Show Users Breakdown (by Role)',
                    subtitle: 'Total users and role distribution',
                    value: _showUsersOverview,
                    onChanged: (v) => setState(() => _showUsersOverview = v),
                  ),
                  _buildVisibilitySwitch(
                    title: 'Show Groups Summary',
                    subtitle: 'Total groups, active/pending counts, members',
                    value: _showGroupsOverview,
                    onChanged: (v) => setState(() => _showGroupsOverview = v),
                  ),
                  _buildVisibilitySwitch(
                    title: 'Show Channels Directory',
                    subtitle: 'Channels with uploaded videos and live stream counts',
                    value: _showChannelsOverview,
                    onChanged: (v) => setState(() => _showChannelsOverview = v),
                  ),
                  _buildVisibilitySwitch(
                    title: 'Show Videos Details & Totals',
                    subtitle: 'Video counts, views, likes, comments, downloads',
                    value: _showVideosOverview,
                    onChanged: (v) => setState(() => _showVideosOverview = v),
                  ),
                  _buildVisibilitySwitch(
                    title: 'Show Top Videos Rankings',
                    subtitle: 'Top videos by likes, comments, views, and downloads',
                    value: _showTopVideosOverview,
                    onChanged: (v) => setState(() => _showTopVideosOverview = v),
                  ),
                  _buildVisibilitySwitch(
                    title: 'Show Live Streams & Viewers',
                    subtitle: 'Live stream counts and viewer metrics',
                    value: _showLiveStreamsOverview,
                    onChanged: (v) => setState(() => _showLiveStreamsOverview = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 0. All-Over System Report Overview Tab
  // ─────────────────────────────────────────────
  Widget _buildOverviewTab() {
    final overviewState = ref.watch(adminPlatformOverviewProvider);

    return overviewState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load platform overview: $err', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () => ref.invalidate(adminPlatformOverviewProvider),
              ),
            ],
          ),
        ),
      ),
      data: (overview) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminPlatformOverviewProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: AdminResponsiveLayout(
            child: PlatformOverviewView(
              overview: overview,
              isAdminView: true,
              onRefresh: () => ref.invalidate(adminPlatformOverviewProvider),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 2. Server & Infrastructure Tab
  // ─────────────────────────────────────────────
  Widget _buildServerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AdminResponsiveLayout(
        child: Column(
          children: [
            AdminSectionCard(
              title: 'Server & Hosting Details',
              subtitle: 'Enter infrastructure and machine specifications',
              child: Column(
                children: [
                  _buildFieldWithSwitch(
                    label: 'Server / Hosting Provider',
                    hint: 'e.g., Render, AWS, Hetzner, GCP',
                    controller: _serverProviderController,
                    showSwitch: _showServerProvider,
                    onSwitchChanged: (v) => setState(() => _showServerProvider = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Service Name',
                    hint: 'e.g., zikre-core-api',
                    controller: _serverServiceNameController,
                    showSwitch: _showServerServiceName,
                    onSwitchChanged: (v) => setState(() => _showServerServiceName = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Server Location',
                    hint: 'e.g., Frankfurt, Germany',
                    controller: _serverLocationController,
                    showSwitch: _showServerLocation,
                    onSwitchChanged: (v) => setState(() => _showServerLocation = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Server Region',
                    hint: 'e.g., eu-central-1',
                    controller: _serverRegionController,
                    showSwitch: _showServerRegion,
                    onSwitchChanged: (v) => setState(() => _showServerRegion = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Hosting Plan',
                    hint: 'e.g., Standard 2GB / Dedicated Node',
                    controller: _serverPlanController,
                    showSwitch: _showServerPlan,
                    onSwitchChanged: (v) => setState(() => _showServerPlan = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Hosting Type',
                    hint: 'e.g., Docker Container / Cloud VPS',
                    controller: _serverHostingTypeController,
                    showSwitch: _showServerHostingType,
                    onSwitchChanged: (v) => setState(() => _showServerHostingType = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'CPU Specifications',
                    hint: 'e.g., 2 vCPU / 2.5 GHz Intel Xeon',
                    controller: _serverCpuController,
                    showSwitch: _showServerCpu,
                    onSwitchChanged: (v) => setState(() => _showServerCpu = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'RAM Capacity',
                    hint: 'e.g., 4 GB LPDDR5',
                    controller: _serverRamController,
                    showSwitch: _showServerRam,
                    onSwitchChanged: (v) => setState(() => _showServerRam = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Disk Capacity',
                    hint: 'e.g., 50 GB NVMe SSD',
                    controller: _serverDiskCapacityController,
                    showSwitch: _showServerDiskCapacity,
                    onSwitchChanged: (v) => setState(() => _showServerDiskCapacity = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Available Storage',
                    hint: 'e.g., 34 GB Free',
                    controller: _serverAvailableStorageController,
                    showSwitch: _showServerAvailableStorage,
                    onSwitchChanged: (v) => setState(() => _showServerAvailableStorage = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Server Status',
                    hint: 'e.g., Operational / Active',
                    controller: _serverStatusController,
                    showSwitch: _showServerStatus,
                    onSwitchChanged: (v) => setState(() => _showServerStatus = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Server Health',
                    hint: 'e.g., 100% Healthy / Normal',
                    controller: _serverHealthController,
                    showSwitch: _showServerHealth,
                    onSwitchChanged: (v) => setState(() => _showServerHealth = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Uptime Information',
                    hint: 'e.g., 99.98% over past 90 days',
                    controller: _serverUptimeController,
                    showSwitch: _showServerUptime,
                    onSwitchChanged: (v) => setState(() => _showServerUptime = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Maintenance Window',
                    hint: 'e.g., Sunday 02:00 - 03:00 UTC',
                    controller: _serverMaintenanceInfoController,
                    showSwitch: _showServerMaintenanceInfo,
                    onSwitchChanged: (v) => setState(() => _showServerMaintenanceInfo = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Backup Configuration',
                    hint: 'e.g., Daily automated snapshots',
                    controller: _serverBackupConfigController,
                    showSwitch: _showServerBackupConfig,
                    onSwitchChanged: (v) => setState(() => _showServerBackupConfig = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Backup Storage',
                    hint: 'e.g., 100 GB S3 Cold Storage',
                    controller: _serverBackupStorageController,
                    showSwitch: _showServerBackupStorage,
                    onSwitchChanged: (v) => setState(() => _showServerBackupStorage = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Server Monthly Cost',
                    hint: 'e.g., 25.00',
                    controller: _serverMonthlyCostController,
                    isNumeric: true,
                    showSwitch: _showServerMonthlyCost,
                    onSwitchChanged: (v) => setState(() => _showServerMonthlyCost = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Server Yearly Cost',
                    hint: 'e.g., 280.00',
                    controller: _serverYearlyCostController,
                    isNumeric: true,
                    showSwitch: _showServerYearlyCost,
                    onSwitchChanged: (v) => setState(() => _showServerYearlyCost = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 3. Database Tab
  // ─────────────────────────────────────────────
  Widget _buildDatabaseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AdminResponsiveLayout(
        child: Column(
          children: [
            AdminSectionCard(
              title: 'Database Infrastructure',
              subtitle: 'PostgreSQL instance and storage information',
              child: Column(
                children: [
                  _buildFieldWithSwitch(
                    label: 'Database Provider',
                    hint: 'e.g., Neon / Supabase / AWS RDS',
                    controller: _dbProviderController,
                    showSwitch: _showDbProvider,
                    onSwitchChanged: (v) => setState(() => _showDbProvider = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Database Engine',
                    hint: 'e.g., PostgreSQL 16.4',
                    controller: _dbEngineController,
                    showSwitch: _showDbEngine,
                    onSwitchChanged: (v) => setState(() => _showDbEngine = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Database Hosting Plan',
                    hint: 'e.g., Serverless Autoscaling',
                    controller: _dbHostingPlanController,
                    showSwitch: _showDbHostingPlan,
                    onSwitchChanged: (v) => setState(() => _showDbHostingPlan = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Infrastructure Details',
                    hint: 'e.g., AWS us-east-1 compute cluster',
                    controller: _dbInfrastructureController,
                    showSwitch: _showDbInfrastructure,
                    onSwitchChanged: (v) => setState(() => _showDbInfrastructure = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Storage Usage',
                    hint: 'e.g., 4.2 GB Used',
                    controller: _dbStorageUsageController,
                    showSwitch: _showDbStorageUsage,
                    onSwitchChanged: (v) => setState(() => _showDbStorageUsage = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Storage Capacity',
                    hint: 'e.g., 50 GB Scalable',
                    controller: _dbStorageCapacityController,
                    showSwitch: _showDbStorageCapacity,
                    onSwitchChanged: (v) => setState(() => _showDbStorageCapacity = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Database Backup Status',
                    hint: 'e.g., Continuous PITR (7-day retention)',
                    controller: _dbBackupStatusController,
                    showSwitch: _showDbBackupStatus,
                    onSwitchChanged: (v) => setState(() => _showDbBackupStatus = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Database Health',
                    hint: 'e.g., Optimal / 0 connection errors',
                    controller: _dbHealthController,
                    showSwitch: _showDbHealth,
                    onSwitchChanged: (v) => setState(() => _showDbHealth = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Availability',
                    hint: 'e.g., 99.99%',
                    controller: _dbAvailabilityController,
                    showSwitch: _showDbAvailability,
                    onSwitchChanged: (v) => setState(() => _showDbAvailability = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Database Monthly Cost',
                    hint: 'e.g., 35.00',
                    controller: _dbMonthlyCostController,
                    isNumeric: true,
                    showSwitch: _showDbMonthlyCost,
                    onSwitchChanged: (v) => setState(() => _showDbMonthlyCost = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Database Yearly Cost',
                    hint: 'e.g., 390.00',
                    controller: _dbYearlyCostController,
                    isNumeric: true,
                    showSwitch: _showDbYearlyCost,
                    onSwitchChanged: (v) => setState(() => _showDbYearlyCost = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 4. API & Backend Services Tab
  // ─────────────────────────────────────────────
  Widget _buildApiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AdminResponsiveLayout(
        child: Column(
          children: [
            AdminSectionCard(
              title: 'API & Backend Services',
              subtitle: 'API gateway, health, and throughput metrics',
              child: Column(
                children: [
                  _buildFieldWithSwitch(
                    label: 'API Service Information',
                    hint: 'e.g., Zikre NestJS REST & WebSocket Gateway',
                    controller: _apiServiceNameController,
                    showSwitch: _showApiServiceName,
                    onSwitchChanged: (v) => setState(() => _showApiServiceName = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'API Availability',
                    hint: 'e.g., 99.95%',
                    controller: _apiAvailabilityController,
                    showSwitch: _showApiAvailability,
                    onSwitchChanged: (v) => setState(() => _showApiAvailability = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Operational Status',
                    hint: 'e.g., All Services Operational',
                    controller: _apiStatusController,
                    showSwitch: _showApiStatus,
                    onSwitchChanged: (v) => setState(() => _showApiStatus = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Response Time',
                    hint: 'e.g., 85ms median p95',
                    controller: _apiResponseTimeController,
                    showSwitch: _showApiResponseTime,
                    onSwitchChanged: (v) => setState(() => _showApiResponseTime = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'API Usage Statistics',
                    hint: 'e.g., ~1.2M API calls / month',
                    controller: _apiUsageStatsController,
                    showSwitch: _showApiUsageStats,
                    onSwitchChanged: (v) => setState(() => _showApiUsageStats = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Backend Hosting Cost',
                    hint: 'e.g., 15.00',
                    controller: _apiHostingCostController,
                    isNumeric: true,
                    showSwitch: _showApiHostingCost,
                    onSwitchChanged: (v) => setState(() => _showApiHostingCost = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'External Services Cost',
                    hint: 'e.g., 10.00',
                    controller: _apiExternalCostController,
                    isNumeric: true,
                    showSwitch: _showApiExternalCost,
                    onSwitchChanged: (v) => setState(() => _showApiExternalCost = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 5. Deployment Information Tab
  // ─────────────────────────────────────────────
  Widget _buildDeploymentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AdminResponsiveLayout(
        child: Column(
          children: [
            AdminSectionCard(
              title: 'Deployment & Build Information',
              subtitle: 'Version control, environments, and CI/CD status',
              child: Column(
                children: [
                  _buildFieldWithSwitch(
                    label: 'Deployment Provider',
                    hint: 'e.g., Render Cloud / GitHub Actions',
                    controller: _deploymentProviderController,
                    showSwitch: _showDeploymentProvider,
                    onSwitchChanged: (v) => setState(() => _showDeploymentProvider = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Deployment Environment',
                    hint: 'e.g., Production',
                    controller: _deploymentEnvController,
                    showSwitch: _showDeploymentEnvironment,
                    onSwitchChanged: (v) => setState(() => _showDeploymentEnvironment = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Deployed Application Version',
                    hint: 'e.g., 2.4.0 (Build 142)',
                    controller: _appVersionController,
                    showSwitch: _showAppVersion,
                    onSwitchChanged: (v) => setState(() => _showAppVersion = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Build Status',
                    hint: 'e.g., Passing / Verified',
                    controller: _buildStatusController,
                    showSwitch: _showBuildStatus,
                    onSwitchChanged: (v) => setState(() => _showBuildStatus = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Environment Details',
                    hint: 'e.g., Node.js 22 LTS, Alpine Linux',
                    controller: _environmentInfoController,
                    showSwitch: _showEnvironmentInfo,
                    onSwitchChanged: (v) => setState(() => _showEnvironmentInfo = v),
                  ),
                  _buildFieldWithSwitch(
                    label: 'Deployment Monthly Cost',
                    hint: 'e.g., 7.00',
                    controller: _deploymentCostController,
                    isNumeric: true,
                    showSwitch: _showDeploymentCost,
                    onSwitchChanged: (v) => setState(() => _showDeploymentCost = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 6. Additional Service Costs Tab
  // ─────────────────────────────────────────────
  Widget _buildCostsTab(SystemReportAdminModel m) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AdminResponsiveLayout(
        child: Column(
          children: [
            AdminSectionCard(
              title: 'Configurable Service Costs',
              subtitle:
                  'Server, DB, CDN, SMS, Push, and third-party service costs',
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Configured Services: ${m.costs.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Service Cost'),
                        onPressed: () => _showCostDialog(context, null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (m.costs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No additional service costs configured.\nTap "Add Service Cost" to add items.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: m.costs.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (ctx, i) {
                        final cost = m.costs[i];
                        return ListTile(
                          title: Text(
                            cost.serviceName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${cost.category.replaceAll('_', ' ')} • ${cost.provider ?? "N/A"} • ${cost.billingPeriod} • ${cost.costType}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${cost.currency} ${cost.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        cost.isVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        size: 14,
                                        color: cost.isVisible
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        cost.isVisible ? 'Visible' : 'Hidden',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: cost.isVisible
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit',
                                onPressed: () => _showCostDialog(context, cost),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () => _deleteCost(cost.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Helper Widgets
  // ─────────────────────────────────────────────

  Widget _buildVisibilitySwitch({
    required String title,
    required String subtitle,
    required bool value,
    bool isFinancial = false,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Row(
        children: [
          Expanded(child: Text(title)),
          if (isFinancial)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'FINANCIAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(subtitle),
      value: value,
      activeThumbColor: isFinancial ? Colors.amber : Colors.blue,
      onChanged: onChanged,
    );
  }

  Widget _buildFieldWithSwitch({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isNumeric = false,
    required bool showSwitch,
    required ValueChanged<bool> onSwitchChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: isNumeric
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Switch(
                value: showSwitch,
                activeThumbColor: Colors.green,
                onChanged: onSwitchChanged,
              ),
              Text(
                showSwitch ? 'Visible' : 'Hidden',
                style: TextStyle(
                  fontSize: 10,
                  color: showSwitch ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCost(String costId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Cost Record?'),
        content: const Text('Are you sure you want to delete this cost record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(adminSystemReportProvider.notifier)
            .deleteCost(costId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showCostDialog(BuildContext context, SystemServiceCostModel? existing) {
    final nameCtrl = TextEditingController(text: existing?.serviceName ?? '');
    final providerCtrl = TextEditingController(text: existing?.provider ?? '');
    final amountCtrl =
        TextEditingController(text: existing?.amount.toString() ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String category = existing?.category ?? 'OTHER';
    String billingPeriod = existing?.billingPeriod ?? 'MONTHLY';
    String costType = existing?.costType ?? 'ACTUAL';
    String currency = existing?.currency ?? 'USD';
    bool isVisible = existing?.isVisible ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Service Cost' : 'Edit Service Cost'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Service Name *',
                      hintText: 'e.g., Cloudinary Media CDN',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category *'),
                    items: const [
                      DropdownMenuItem(value: 'SERVER_HOSTING', child: Text('Server & Hosting')),
                      DropdownMenuItem(value: 'DATABASE', child: Text('Database')),
                      DropdownMenuItem(value: 'API_SERVICES', child: Text('API Services')),
                      DropdownMenuItem(value: 'STORAGE_CDN', child: Text('Storage & CDN')),
                      DropdownMenuItem(value: 'BANDWIDTH', child: Text('Bandwidth')),
                      DropdownMenuItem(value: 'EMAIL', child: Text('Email Services')),
                      DropdownMenuItem(value: 'SMS', child: Text('SMS Services')),
                      DropdownMenuItem(value: 'PUSH_NOTIFICATIONS', child: Text('Push Notifications')),
                      DropdownMenuItem(value: 'BACKUP', child: Text('Backup Services')),
                      DropdownMenuItem(value: 'MONITORING', child: Text('Monitoring & Third-Party')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => category = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: providerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Provider',
                      hintText: 'e.g., Cloudflare, Twilio, Firebase',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Amount *'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: DropdownButtonFormField<String>(
                          initialValue: currency,
                          decoration: const InputDecoration(labelText: 'Curr'),
                          items: const [
                            DropdownMenuItem(value: 'USD', child: Text('USD')),
                            DropdownMenuItem(value: 'ETB', child: Text('ETB')),
                            DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                          ],
                          onChanged: (v) {
                            if (v != null) setDialogState(() => currency = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: billingPeriod,
                          decoration: const InputDecoration(labelText: 'Period'),
                          items: const [
                            DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                            DropdownMenuItem(value: 'YEARLY', child: Text('Yearly')),
                            DropdownMenuItem(value: 'ONE_TIME', child: Text('One-Time')),
                          ],
                          onChanged: (v) {
                            if (v != null) setDialogState(() => billingPeriod = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: costType,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: const [
                            DropdownMenuItem(value: 'ACTUAL', child: Text('Actual')),
                            DropdownMenuItem(value: 'ESTIMATED', child: Text('Estimated')),
                          ],
                          onChanged: (v) {
                            if (v != null) setDialogState(() => costType = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Brief details about this expense',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Visible to Ordinary Users'),
                    subtitle: const Text('Default is OFF. Requires manual approval.'),
                    value: isVisible,
                    activeThumbColor: Colors.amber,
                    onChanged: (v) => setDialogState(() => isVisible = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a service name')),
                  );
                  return;
                }

                Navigator.pop(ctx);
                final notifier = ref.read(adminSystemReportProvider.notifier);

                final costData = {
                  'serviceName': name,
                  'category': category,
                  'provider': providerCtrl.text.trim(),
                  'amount': amount,
                  'currency': currency,
                  'billingPeriod': billingPeriod,
                  'costType': costType,
                  'description': descCtrl.text.trim(),
                  'isVisible': isVisible,
                };

                if (existing == null) {
                  await notifier.addCost(costData);
                } else {
                  await notifier.updateCost(existing.id, costData);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
