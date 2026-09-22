// lib/features/live/presentation/screens/live_discovery_screen.dart
// Shows LIVE NOW, SCHEDULED, and MY SCHEDULES streams with categories and reminders.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/live/presentation/providers/live_discovery_provider.dart';
import 'package:mobile/features/live/presentation/widgets/live_card_widget.dart';
import 'package:mobile/features/live/presentation/widgets/live_category_bar.dart';
import 'package:mobile/features/live/presentation/widgets/scheduled_live_card_widget.dart';

class LiveDiscoveryScreen extends ConsumerWidget {
  const LiveDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tr('live.title'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Go Live / Schedule',
              onPressed: () => _showLiveActionsSheet(context),
            ),
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Navigation',
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: false,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: [
              Tab(
                icon: const Icon(Icons.sensors, size: 18),
                text: tr('live.tab_now'),
              ),
              Tab(
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                text: tr('live.tab_scheduled'),
              ),
              const Tab(
                icon: Icon(Icons.schedule_send_outlined, size: 18),
                text: 'My Schedules',
              ),
            ],
          ),
        ),
        endDrawer: _buildSideDrawer(context, theme),
        body: Column(
          children: [
            // Modern horizontal category bar with Add Category button
            const LiveCategoryBar(),
            const Divider(height: 1, thickness: 0.5),

            // Tab Views
            const Expanded(
              child: TabBarView(
                children: [
                  _LiveStreamsList(),
                  _ScheduledStreamsList(),
                  _MyScheduledStreamsList(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showLiveActionsSheet(context),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.sensors_rounded),
          label: const Text(
            'Go Live',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildSideDrawer(BuildContext context, ThemeData theme) {
    return Drawer(
      width: 280,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.live_tv_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Live Hub',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Discover & broadcast live',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.home_outlined, size: 22, color: theme.colorScheme.onSurfaceVariant),
              title: const Text('Home', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              horizontalTitleGap: 8,
              onTap: () { Navigator.of(context).pop(); context.go('/home'); },
            ),
            ListTile(
              leading: Icon(Icons.sensors_rounded, size: 22, color: Colors.redAccent),
              title: const Text('Go Live', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.redAccent)),
              horizontalTitleGap: 8,
              onTap: () { Navigator.of(context).pop(); context.push('/live/studio'); },
            ),
            ListTile(
              leading: Icon(Icons.event_available_rounded, size: 22, color: theme.colorScheme.onSurfaceVariant),
              title: const Text('Schedule Stream', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              horizontalTitleGap: 8,
              onTap: () { Navigator.of(context).pop(); context.push('/live/studio?schedule=true'); },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.analytics_outlined, size: 22, color: theme.colorScheme.onSurfaceVariant),
              title: const Text('Creator Studio', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              horizontalTitleGap: 8,
              onTap: () { Navigator.of(context).pop(); context.push('/creator'); },
            ),
            ListTile(
              leading: Icon(Icons.settings_outlined, size: 22, color: theme.colorScheme.onSurfaceVariant),
              title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              horizontalTitleGap: 8,
              onTap: () { Navigator.of(context).pop(); context.push('/settings'); },
            ),
          ],
        ),
      ),
    );
  }

  void _showLiveActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Live Stream Studio',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Choose how you want to broadcast',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                // Go Live Now card
                InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push('/live/studio');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sensors_rounded, color: Colors.redAccent, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Go Live Now',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Start broadcasting immediately from your camera',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.redAccent),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Schedule card
                InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push('/live/studio?schedule=true');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.event_available_rounded, color: Colors.blueAccent, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Schedule for Later',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Post schedule and notify users or followers in advance',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.blueAccent),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Live Streams List (Tab 1) ────────────────────────────────────────────────

class _LiveStreamsList extends ConsumerWidget {
  const _LiveStreamsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveStreamsProvider);

    if (state.isLoading) return _Skeletons();

    if (state.error != null && state.streams.isEmpty) {
      return _ErrorState(
        message: state.error!,
        onRetry: () => ref.read(liveStreamsProvider.notifier).load(),
      );
    }

    if (state.streams.isEmpty) {
      return _EmptyState(
        icon: Icons.live_tv_outlined,
        messageKey: 'live.no_streams',
        subKey: 'live.no_streams_hint',
        onRefresh: () => ref.read(liveStreamsProvider.notifier).refresh(),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200) {
          ref.read(liveStreamsProvider.notifier).loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => ref.read(liveStreamsProvider.notifier).refresh(),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: state.streams.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == state.streams.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return LiveCardWidget(stream: state.streams[i]);
          },
        ),
      ),
    );
  }
}

// ─── Scheduled Streams List (Tab 2) ───────────────────────────────────────────

class _ScheduledStreamsList extends ConsumerWidget {
  const _ScheduledStreamsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduledStreamsProvider);

    if (state.isLoading) return _Skeletons();

    if (state.error != null && state.streams.isEmpty) {
      return _ErrorState(
        message: state.error!,
        onRetry: () => ref.read(scheduledStreamsProvider.notifier).load(),
      );
    }

    if (state.streams.isEmpty) {
      return _EmptyState(
        icon: Icons.calendar_month_outlined,
        messageKey: 'live.no_scheduled',
        subKey: 'live.no_scheduled_hint',
        onRefresh: () => ref.read(scheduledStreamsProvider.notifier).refresh(),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200) {
          ref.read(scheduledStreamsProvider.notifier).loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => ref.read(scheduledStreamsProvider.notifier).refresh(),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: state.streams.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == state.streams.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return ScheduledLiveCardWidget(stream: state.streams[i]);
          },
        ),
      ),
    );
  }
}

// ─── My Scheduled Streams List (Tab 3) ────────────────────────────────────────

class _MyScheduledStreamsList extends ConsumerWidget {
  const _MyScheduledStreamsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myScheduledStreamsProvider);

    if (state.isLoading) return _Skeletons();

    if (state.error != null && state.streams.isEmpty) {
      return _ErrorState(
        message: state.error!,
        onRetry: () => ref.read(myScheduledStreamsProvider.notifier).load(),
      );
    }

    if (state.streams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_note_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No personal schedules yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Streams you schedule will appear here so you can manage and start them.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/live/studio?schedule=true'),
                icon: const Icon(Icons.add_alarm_rounded),
                label: const Text('Schedule a Stream'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(myScheduledStreamsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: state.streams.length,
        itemBuilder: (_, i) {
          return ScheduledLiveCardWidget(stream: state.streams[i]);
        },
      ),
    );
  }
}

// ─── Skeletons & States ───────────────────────────────────────────────────────

class _Skeletons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 4,
      itemBuilder: (context, index) => _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 220,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: 140,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  final IconData icon;
  final String messageKey;
  final String subKey;
  final VoidCallback onRefresh;

  const _EmptyState({
    required this.icon,
    required this.messageKey,
    required this.subKey,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              tr(messageKey),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              tr(subKey),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: Text(tr('explore.refresh')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends ConsumerWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              tr('live.load_failed'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(tr('common.try_again')),
            ),
          ],
        ),
      ),
    );
  }
}
