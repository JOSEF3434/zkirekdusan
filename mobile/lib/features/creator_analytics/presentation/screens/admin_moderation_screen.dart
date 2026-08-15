// lib/features/creator_analytics/presentation/screens/admin_moderation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/creator_analytics/domain/creator_analytics_dto.dart';
import 'package:mobile/features/creator_analytics/presentation/providers/admin_moderation_provider.dart';
import 'package:mobile/features/creator_analytics/presentation/widgets/confirm_action_dialog.dart';

class AdminModerationScreen extends ConsumerStatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  ConsumerState<AdminModerationScreen> createState() =>
      _AdminModerationScreenState();
}

class _AdminModerationScreenState extends ConsumerState<AdminModerationScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminModerationProvider.notifier).loadMore();
    }
  }

  Future<void> _handleResolve(AdminReportDto report) async {
    final confirm = await ConfirmActionDialog.show(
      context,
      title: 'Resolve Report',
      content: 'Mark this report as resolved?',
      confirmText: 'Resolve',
    );
    if (confirm != true) return;

    try {
      await ref.read(adminModerationProvider.notifier).resolveReport(report.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Report resolved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminModerationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Moderation')),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(AdminModerationState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${state.error}',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            ElevatedButton(
              onPressed: () =>
                  ref.read(adminModerationProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.reports.isEmpty) {
      return const Center(child: Text('No reports to moderate.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(adminModerationProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        itemCount: state.reports.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == state.reports.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final report = state.reports[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              report.reason,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Target: ${report.reportedContentType} (${report.reportedContentId ?? "Unknown"})',
                ),
                if (report.description != null) ...[
                  const SizedBox(height: 4),
                  Text('Details: ${report.description}'),
                ],
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: report.status == 'PENDING'
                        ? Colors.orange.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    report.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: report.status == 'PENDING'
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            trailing: report.status == 'PENDING'
                ? FilledButton.tonal(
                    onPressed: () => _handleResolve(report),
                    child: const Text('Resolve'),
                  )
                : null,
          );
        },
      ),
    );
  }
}
