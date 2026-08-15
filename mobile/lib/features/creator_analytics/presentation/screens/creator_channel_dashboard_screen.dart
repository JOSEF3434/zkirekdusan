// lib/features/creator_analytics/presentation/screens/creator_channel_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/creator_analytics/presentation/providers/creator_dashboard_provider.dart';
import 'package:mobile/features/creator_analytics/presentation/widgets/analytics_coming_soon.dart';
import 'package:mobile/features/creator_analytics/presentation/widgets/analytics_stat_card.dart';

class CreatorChannelDashboardScreen extends ConsumerWidget {
  final String groupId;
  final String channelId;
  final String channelName;

  const CreatorChannelDashboardScreen({
    super.key,
    required this.groupId,
    required this.channelId,
    required this.channelName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ChannelAnalyticsArgs(groupId: groupId, channelId: channelId);
    final state = ref.watch(channelAnalyticsProvider(args));

    return Scaffold(
      appBar: AppBar(
        title: Text('$channelName Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_library),
            tooltip: 'Manage Videos',
            onPressed: () =>
                context.push('/creator/dashboard/channel/$channelId/videos'),
          ),
        ],
      ),
      body: _buildBody(context, ref, state, args),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ChannelAnalyticsState state,
    ChannelAnalyticsArgs args,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      final theme = Theme.of(context);
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
                  ref.read(channelAnalyticsProvider(args).notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final analytics = state.analytics;
    if (analytics == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(channelAnalyticsProvider(args).notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              AnalyticsStatCard(
                title: 'Total Views',
                value: analytics.totalViews,
                icon: Icons.visibility,
                iconColor: Colors.blue,
              ),
              AnalyticsStatCard(
                title: 'Subscribers',
                value: analytics.totalSubscribers.toString(),
                icon: Icons.people,
                iconColor: Colors.purple,
              ),
              AnalyticsStatCard(
                title: 'Total Likes',
                value: analytics.totalLikes.toString(),
                icon: Icons.thumb_up,
                iconColor: Colors.green,
              ),
              AnalyticsStatCard(
                title: 'Total Videos',
                value: analytics.totalVideos.toString(),
                icon: Icons.video_file,
                iconColor: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Historical Performance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const AnalyticsComingSoon(featureName: 'Time-series Charts'),
          const SizedBox(height: 24),
          const AnalyticsComingSoon(featureName: 'Audience Demographics'),
          const SizedBox(height: 32),
          FilledButton.icon(
            icon: const Icon(Icons.manage_history),
            label: const Text('Manage Content & Moderation'),
            onPressed: () =>
                context.push('/creator/dashboard/channel/$channelId/videos'),
          ),
        ],
      ),
    );
  }
}
