// lib/features/settings/presentation/widgets/system_report_popup_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/data/system_report_repository.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/settings/domain/public_system_report_model.dart';
import 'package:mobile/features/settings/presentation/providers/user_system_report_provider.dart';

class SystemReportPopupDialog extends ConsumerWidget {
  final PublicSystemReportModel report;

  const SystemReportPopupDialog({
    super.key,
    required this.report,
  });

  /// Evaluates whether the first-open popup should be displayed for the active user.
  /// Runs safely on home screen load without disrupting login or onboarding.
  static Future<void> checkAndShow(BuildContext context, WidgetRef ref) async {
    try {
      // Must be authenticated
      final auth = ref.read(authProvider);
      if (auth.status != AuthStatus.authenticated || auth.user == null) {
        return;
      }

      // Check current public report state
      final reportState = ref.read(userSystemReportProvider);
      PublicSystemReportModel? report = reportState.value;

      report ??= await ref.read(systemReportRepositoryProvider).getActivePublicReport();

      if (report == null || !report.hasContent) {
        return;
      }

      // Display mode must allow popup (POPUP_ONLY or BOTH)
      if (report.displayMode != 'POPUP_ONLY' && report.displayMode != 'BOTH') {
        return;
      }

      // Check per-user backend dismissed flag
      if (report.hasDismissed) {
        return;
      }

      // Check local device preferences cache
      final prefs = ref.read(sharedPreferencesProvider);
      final cacheKey = 'system_report_seen_${auth.user!.id}_${report.id}_rev${report.revision}';
      if (prefs.getBool(cacheKey) == true) {
        return;
      }

      // Mark locally seen so it will never show again on this device even if offline
      await prefs.setBool(cacheKey, true);

      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => SystemReportPopupDialog(report: report!),
      );
    } catch (_) {
      // Non-critical background check — fail silently without disrupting the user
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon Badge
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF673AB7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.assessment_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                report.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Revision ${report.revision} • Published',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),

              if (report.summary != null && report.summary!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  report.summary!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 18),

              // Highlights Grid (Operational status, server, etc.)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E2E)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    if (report.server?.status != null)
                      _buildSummaryRow(
                        Icons.check_circle_rounded,
                        Colors.green,
                        'Server Status',
                        report.server!.status!,
                      ),
                    if (report.server?.uptime != null)
                      _buildSummaryRow(
                        Icons.timer_rounded,
                        Colors.blue,
                        'System Uptime',
                        report.server!.uptime!,
                      ),
                    if (report.deployment?.appVersion != null)
                      _buildSummaryRow(
                        Icons.rocket_launch_rounded,
                        Colors.orange,
                        'App Version',
                        report.deployment!.appVersion!,
                      ),
                    if (report.costs.isNotEmpty)
                      _buildSummaryRow(
                        Icons.account_balance_wallet_rounded,
                        Colors.teal,
                        'Services Tracked',
                        '${report.costs.length} verified services',
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ref
                            .read(userSystemReportProvider.notifier)
                            .dismiss(report.id, report.revision);
                      },
                      child: Text(tr('common.close', {'fallback': 'Dismiss'})),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ref
                            .read(userSystemReportProvider.notifier)
                            .dismiss(report.id, report.revision);
                        context.push('/settings/system-report');
                      },
                      child: Text(
                        tr('settings.view_report', {'fallback': 'View Details'}),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    IconData icon,
    Color color,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
