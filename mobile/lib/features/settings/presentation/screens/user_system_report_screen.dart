// lib/features/settings/presentation/screens/user_system_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/settings/domain/public_system_report_model.dart';
import 'package:mobile/features/settings/presentation/providers/user_system_report_provider.dart';

class UserSystemReportScreen extends ConsumerWidget {
  final PublicSystemReportModel? previewReport;
  final ScrollController? scrollController;

  const UserSystemReportScreen({
    super.key,
    this.previewReport,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);

    if (previewReport != null) {
      return _buildContent(context, previewReport!, tr);
    }

    final reportState = ref.watch(userSystemReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('settings.system_report', {'fallback': 'System Report'})),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(userSystemReportProvider.notifier).refresh(),
          ),
        ],
      ),
      body: reportState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Unable to load system report: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(userSystemReportProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (report) {
          if (report == null || !report.hasContent) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      tr('settings.system_report_unavailable', {
                        'fallback': 'No Public System Report Available',
                      }),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('settings.system_report_unavailable_sub', {
                        'fallback': 'The platform system report has not been published for public visibility yet.',
                      }),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildContent(context, report, tr);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    PublicSystemReportModel report,
    String Function(String, [Map<String, dynamic>?]) tr,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Card ───────────────────────────────────────
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.verified_rounded, color: Colors.blue, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Revision ${report.revision}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(report.publishedAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (report.summary != null && report.summary!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        report.summary!,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Server & Infrastructure ───────────────────────────
            if (report.server != null) ...[
              _buildSectionCard(
                context,
                title: tr('settings.server_infrastructure', {'fallback': 'Server & Infrastructure'}),
                icon: Icons.dns_rounded,
                color: Colors.blue,
                child: Column(
                  children: [
                    if (report.server!.provider != null)
                      _buildInfoRow('Provider', report.server!.provider!),
                    if (report.server!.serviceName != null)
                      _buildInfoRow('Service', report.server!.serviceName!),
                    if (report.server!.location != null)
                      _buildInfoRow('Location', report.server!.location!),
                    if (report.server!.region != null)
                      _buildInfoRow('Region', report.server!.region!),
                    if (report.server!.plan != null)
                      _buildInfoRow('Hosting Plan', report.server!.plan!),
                    if (report.server!.hostingType != null)
                      _buildInfoRow('Hosting Type', report.server!.hostingType!),
                    if (report.server!.cpu != null)
                      _buildInfoRow('CPU Specs', report.server!.cpu!),
                    if (report.server!.ram != null)
                      _buildInfoRow('RAM Memory', report.server!.ram!),
                    if (report.server!.diskCapacity != null)
                      _buildInfoRow('Disk Capacity', report.server!.diskCapacity!),
                    if (report.server!.availableStorage != null)
                      _buildInfoRow('Available Storage', report.server!.availableStorage!),
                    if (report.server!.status != null)
                      _buildStatusRow('Operational Status', report.server!.status!),
                    if (report.server!.health != null)
                      _buildInfoRow('System Health', report.server!.health!),
                    if (report.server!.uptime != null)
                      _buildInfoRow('Uptime', report.server!.uptime!),
                    if (report.server!.maintenanceInfo != null)
                      _buildInfoRow('Maintenance Window', report.server!.maintenanceInfo!),
                    if (report.server!.backupConfig != null)
                      _buildInfoRow('Backup Config', report.server!.backupConfig!),
                    if (report.server!.backupStorage != null)
                      _buildInfoRow('Backup Storage', report.server!.backupStorage!),
                    if (report.server!.monthlyCost != null)
                      _buildCostRow('Monthly Cost', report.server!.monthlyCost!, report.server!.currency),
                    if (report.server!.yearlyCost != null)
                      _buildCostRow('Yearly Cost', report.server!.yearlyCost!, report.server!.currency),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Database ──────────────────────────────────────────
            if (report.database != null) ...[
              _buildSectionCard(
                context,
                title: tr('settings.database_info', {'fallback': 'Database Information'}),
                icon: Icons.storage_rounded,
                color: Colors.deepPurple,
                child: Column(
                  children: [
                    if (report.database!.provider != null)
                      _buildInfoRow('Provider', report.database!.provider!),
                    if (report.database!.engine != null)
                      _buildInfoRow('Engine', report.database!.engine!),
                    if (report.database!.hostingPlan != null)
                      _buildInfoRow('Plan', report.database!.hostingPlan!),
                    if (report.database!.infrastructure != null)
                      _buildInfoRow('Infrastructure', report.database!.infrastructure!),
                    if (report.database!.storageUsage != null)
                      _buildInfoRow('Storage Used', report.database!.storageUsage!),
                    if (report.database!.storageCapacity != null)
                      _buildInfoRow('Total Capacity', report.database!.storageCapacity!),
                    if (report.database!.backupStatus != null)
                      _buildInfoRow('Backup Status', report.database!.backupStatus!),
                    if (report.database!.health != null)
                      _buildInfoRow('Health', report.database!.health!),
                    if (report.database!.availability != null)
                      _buildInfoRow('Availability', report.database!.availability!),
                    if (report.database!.monthlyCost != null)
                      _buildCostRow('Monthly Cost', report.database!.monthlyCost!, report.database!.currency),
                    if (report.database!.yearlyCost != null)
                      _buildCostRow('Yearly Cost', report.database!.yearlyCost!, report.database!.currency),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── API & Backend Services ────────────────────────────
            if (report.api != null) ...[
              _buildSectionCard(
                context,
                title: tr('settings.api_services', {'fallback': 'API & Backend Services'}),
                icon: Icons.api_rounded,
                color: Colors.teal,
                child: Column(
                  children: [
                    if (report.api!.serviceName != null)
                      _buildInfoRow('Service', report.api!.serviceName!),
                    if (report.api!.availability != null)
                      _buildInfoRow('Availability', report.api!.availability!),
                    if (report.api!.status != null)
                      _buildStatusRow('Status', report.api!.status!),
                    if (report.api!.responseTime != null)
                      _buildInfoRow('Response Time', report.api!.responseTime!),
                    if (report.api!.usageStats != null)
                      _buildInfoRow('Usage Stats', report.api!.usageStats!),
                    if (report.api!.hostingCost != null)
                      _buildCostRow('Hosting Cost', report.api!.hostingCost!, report.api!.currency),
                    if (report.api!.externalCost != null)
                      _buildCostRow('External API Cost', report.api!.externalCost!, report.api!.currency),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Deployment Information ────────────────────────────
            if (report.deployment != null) ...[
              _buildSectionCard(
                context,
                title: tr('settings.deployment_info', {'fallback': 'Deployment Information'}),
                icon: Icons.rocket_launch_rounded,
                color: Colors.orange,
                child: Column(
                  children: [
                    if (report.deployment!.provider != null)
                      _buildInfoRow('Deployment Host', report.deployment!.provider!),
                    if (report.deployment!.environment != null)
                      _buildInfoRow('Environment', report.deployment!.environment!),
                    if (report.deployment!.appVersion != null)
                      _buildInfoRow('Deployed Version', report.deployment!.appVersion!),
                    if (report.deployment!.lastDeploymentDate != null)
                      _buildInfoRow('Last Deployed', _formatDate(report.deployment!.lastDeploymentDate!)),
                    if (report.deployment!.buildStatus != null)
                      _buildInfoRow('Build Status', report.deployment!.buildStatus!),
                    if (report.deployment!.environmentInfo != null)
                      _buildInfoRow('Environment Specs', report.deployment!.environmentInfo!),
                    if (report.deployment!.deploymentCost != null)
                      _buildCostRow('Deployment Cost', report.deployment!.deploymentCost!, report.deployment!.currency),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Additional Service Costs ──────────────────────────
            if (report.costs.isNotEmpty) ...[
              _buildSectionCard(
                context,
                title: tr('settings.service_costs', {'fallback': 'Approved Service Costs'}),
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.indigo,
                child: Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: report.costs.length,
                      separatorBuilder: (context, index) => const Divider(height: 16),
                      itemBuilder: (ctx, i) {
                        final cost = report.costs[i];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _categoryIcon(cost.category),
                                size: 18,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cost.serviceName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${cost.category.replaceAll('_', ' ')}${cost.provider != null ? " • ${cost.provider}" : ""} • ${cost.billingPeriod}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${cost.currency} ${cost.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Footer ────────────────────────────────────────────
            Center(
              child: Text(
                'Report Revision ${report.revision} • Published by Administrator',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status) {
    final isOperational = status.toLowerCase().contains('operat') ||
        status.toLowerCase().contains('active') ||
        status.toLowerCase().contains('health');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isOperational
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isOperational ? Colors.green : Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: TextStyle(
                    color: isOperational ? Colors.green.shade800 : Colors.amber.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, double amount, String? currency) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            '${currency ?? "USD"} ${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'SERVER_HOSTING':
        return Icons.dns;
      case 'DATABASE':
        return Icons.storage;
      case 'API_SERVICES':
        return Icons.api;
      case 'STORAGE_CDN':
        return Icons.cloud_queue;
      case 'BANDWIDTH':
        return Icons.speed;
      case 'EMAIL':
        return Icons.email;
      case 'SMS':
        return Icons.sms;
      case 'PUSH_NOTIFICATIONS':
        return Icons.notifications;
      case 'BACKUP':
        return Icons.backup;
      case 'MONITORING':
        return Icons.insights;
      default:
        return Icons.attach_money;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
