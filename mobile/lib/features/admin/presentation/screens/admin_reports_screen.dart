// lib/features/admin/presentation/screens/admin_reports_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/admin/presentation/providers/admin_reports_provider.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeFilter = ref.watch(adminReportsFilterProvider);
    final reportsAsync = ref.watch(adminReportsProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1621) : Colors.grey[100],
      appBar: AppBar(
        title: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('settings.admin.reports_moderation'))),
        backgroundColor: isDark ? const Color(0xFF0E1621) : Colors.grey[100],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(adminReportsProvider.notifier).loadReports(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('PENDING', 'Pending', activeFilter),
                const SizedBox(width: 8),
                _buildFilterChip('ALL', 'All Reports', activeFilter),
                const SizedBox(width: 8),
                _buildFilterChip('RESOLVED', 'Resolved', activeFilter),
                const SizedBox(width: 8),
                _buildFilterChip('DISMISSED', 'Dismissed', activeFilter),
              ],
            ),
          ),

          // Reports List
          Expanded(
            child: reportsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF00C6FF)),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load reports: $err',
                      style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.read(adminReportsProvider.notifier).loadReports(),
                      child: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('common.retry'))),
                    ),
                  ],
                ),
              ),
              data: (reports) {
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            size: 44,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No $activeFilter reports',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'All clean! No user reports currently match this filter.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFF00C6FF),
                  onRefresh: () => ref.read(adminReportsProvider.notifier).loadReports(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return _buildReportCard(context, report, isDark);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, String activeKey) {
    final isSelected = activeKey == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(adminReportsFilterProvider.notifier).state = key;
        }
      },
      selectedColor: const Color(0xFF00C6FF),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    AdminReportItemDto report,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF17212B) : Colors.white;
    final isPending = report.status == 'PENDING';
    final targetUser = report.targetUser;
    final isTargetUserBanned = targetUser?.status == 'BANNED';
    final isTargetUserInactive = targetUser?.status == 'INACTIVE';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isPending
              ? Colors.redAccent.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Target Type + Date + Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C6FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.targetType,
                  style: const TextStyle(
                    color: Color(0xFF00C6FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getReasonColor(report.reason).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.reason.replaceAll('_', ' '),
                  style: TextStyle(
                    color: _getReasonColor(report.reason),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              _buildStatusBadge(report.status),
            ],
          ),
          const SizedBox(height: 14),

          // Reported Target Entity Info Card
          if (targetUser != null)
            InkWell(
              onTap: targetUser.username != null
                  ? () => context.push('/profile/user/${targetUser.username}')
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0E1621)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF00C6FF).withValues(alpha: 0.2),
                      backgroundImage: targetUser.avatarUrl != null &&
                              targetUser.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(targetUser.avatarUrl!)
                          : null,
                      child: targetUser.avatarUrl == null
                          ? Text(
                              (targetUser.displayName ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00C6FF),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                targetUser.displayName ?? 'Unknown User',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (isTargetUserBanned)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'BANNED',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (isTargetUserInactive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'INACTIVE',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            targetUser.username != null
                                ? '@${targetUser.username}'
                                : 'ID: ${report.targetId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0E1621)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Target ID: ${report.targetId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Reporter & Date
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Reported by: ${report.reporterDisplayName ?? report.reporterUsername ?? "Anonymous"}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, h:mm a').format(report.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
            ],
          ),

          // Optional comment from reporter
          if (report.comment != null && report.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF232E3C)
                    : Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '"${report.comment}"',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Admin Action Buttons
          if (isPending)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 1. Ban User
                FilledButton.icon(
                  onPressed: () => _confirmBanUser(report),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.block_rounded, size: 16),
                  label: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('admin.actions.ban'), style: const TextStyle(fontSize: 12.5))),
                ),

                // 2. Deactivate User
                FilledButton.tonalIcon(
                  onPressed: () => _confirmDeactivateUser(report),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.pause_circle_outline_rounded, size: 16, color: Colors.orange),
                  label: const Text(
                    'Deactivate',
                    style: TextStyle(fontSize: 12.5, color: Colors.orange),
                  ),
                ),

                // 3. Dismiss Report
                OutlinedButton.icon(
                  onPressed: () => ref
                      .read(adminReportsProvider.notifier)
                      .dismissReport(report.id),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('common.dismiss'), style: const TextStyle(fontSize: 12.5))),
                ),

                // 4. Mark Resolved
                TextButton.icon(
                  onPressed: () => ref
                      .read(adminReportsProvider.notifier)
                      .resolveReport(report.id),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('admin.actions.restore'), style: const TextStyle(fontSize: 12.5))),
                ),
              ],
            )
          else if (report.actionTaken != null)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Action taken: ${report.actionTaken}',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getReasonColor(String reason) {
    switch (reason) {
      case 'HATE_SPEECH':
      case 'VIOLENCE':
        return Colors.redAccent;
      case 'SPAM':
      case 'IMPERSONATION':
        return Colors.orange;
      case 'INAPPROPRIATE_CONTENT':
      case 'COPYRIGHT':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF00C6FF);
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'PENDING':
        bg = Colors.redAccent.withValues(alpha: 0.15);
        fg = Colors.redAccent;
        break;
      case 'RESOLVED':
        bg = const Color(0xFF10B981).withValues(alpha: 0.15);
        fg = const Color(0xFF10B981);
        break;
      case 'DISMISSED':
        bg = Colors.grey.withValues(alpha: 0.2);
        fg = Colors.grey;
        break;
      default:
        bg = const Color(0xFF00C6FF).withValues(alpha: 0.15);
        fg = const Color(0xFF00C6FF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _confirmBanUser(
    AdminReportItemDto report,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('admin.confirm.ban_title'))),
        content: Text(
          'Are you sure you want to BAN ${report.targetUser?.displayName ?? report.targetId}? '
          'This will terminate their active sessions and restrict access to the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('common.cancel'))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('admin.actions.ban'))),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(adminReportsProvider.notifier)
          .banTargetUser(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'User has been banned and report resolved.'
                  : 'Failed to ban user.',
            ),
            backgroundColor: success ? Colors.redAccent : Colors.grey[800],
          ),
        );
      }
    }
  }

  Future<void> _confirmDeactivateUser(
    AdminReportItemDto report,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('admin.actions.deactivate'))),
        content: Text(
          'Are you sure you want to deactivate ${report.targetUser?.displayName ?? report.targetId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('common.cancel'))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('admin.actions.deactivate'))),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(adminReportsProvider.notifier)
          .deactivateTargetUser(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'User has been deactivated and report resolved.'
                  : 'Failed to deactivate user.',
            ),
            backgroundColor: success ? Colors.orange : Colors.grey[800],
          ),
        );
      }
    }
  }
}



