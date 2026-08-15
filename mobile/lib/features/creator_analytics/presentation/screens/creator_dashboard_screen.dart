// lib/features/creator_analytics/presentation/screens/creator_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/creator/domain/creator_permission_service.dart';
import 'package:mobile/features/creator_analytics/presentation/providers/creator_dashboard_provider.dart';
import 'package:mobile/features/creator_analytics/presentation/widgets/analytics_stat_card.dart';

class CreatorDashboardScreen extends ConsumerWidget {
  const CreatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(creatorPermissionServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Dashboard'),
        actions: [
          if (permissions.isGlobalAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Moderation',
              onPressed: () => context.push('/admin/moderation'),
            ),
        ],
      ),
      body: _buildBody(context, ref, permissions),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    CreatorPermissionService permissions,
  ) {
    if (permissions.isGlobalAdmin) {
      return _buildAdminDashboard(context, ref);
    }
    return _buildCreatorDashboard(context, ref);
  }

  Widget _buildAdminDashboard(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminMetricsProvider);
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
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
                  ref.read(adminMetricsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final metrics = state.metrics;
    if (metrics == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: () => ref.read(adminMetricsProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Platform Overview', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              AnalyticsStatCard(
                title: 'Total Users',
                value: metrics.totalUsers.toString(),
                icon: Icons.people,
                iconColor: Colors.blue,
              ),
              AnalyticsStatCard(
                title: 'Total Videos',
                value: metrics.totalVideos.toString(),
                icon: Icons.video_library,
                iconColor: Colors.red,
              ),
              AnalyticsStatCard(
                title: 'Total Groups',
                value: metrics.totalGroups.toString(),
                icon: Icons.group_work,
                iconColor: Colors.green,
              ),
              AnalyticsStatCard(
                title: 'Active Streams',
                value: metrics.activeStreams.toString(),
                icon: Icons.live_tv,
                iconColor: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 32),
          ListTile(
            title: const Text('Manage Reports & Moderation'),
            subtitle: const Text('Review flagged content and users'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            leading: const Icon(Icons.gavel),
            tileColor: theme.colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () => context.push('/admin/moderation'),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Go to Creator Workspace'),
            subtitle: const Text('Manage groups and channels'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            leading: const Icon(Icons.dashboard),
            tileColor: theme.colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () => context.go('/creator'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorDashboard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // For regular creators, we guide them to select a channel from their workspace
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Welcome to Creator Analytics',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'To view analytics and manage content, please navigate to your Creator Workspace and select a specific channel.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go to Workspace'),
            onPressed: () => context.go('/creator'),
          ),
        ],
      ),
    );
  }
}
