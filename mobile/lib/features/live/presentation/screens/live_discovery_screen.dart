// lib/features/live/presentation/screens/live_discovery_screen.dart
// Shows all currently LIVE and SCHEDULED streams with skeletons and pagination.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/live/presentation/providers/live_discovery_provider.dart';
import 'package:mobile/features/live/presentation/widgets/live_card_widget.dart';

class LiveDiscoveryScreen extends ConsumerWidget {
  const LiveDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Live'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'LIVE NOW'),
              Tab(text: 'Scheduled'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_LiveStreamsList(), _ScheduledStreamsList()],
        ),
      ),
    );
  }
}

// ─── Live NOW ─────────────────────────────────────────────────────────────────

class _LiveStreamsList extends ConsumerWidget {
  const _LiveStreamsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveStreamsProvider);

    if (state.isLoading) {
      return _Skeletons();
    }

    if (state.error != null && state.streams.isEmpty) {
      return _ErrorState(
        message: state.error!,
        onRetry: () => ref.read(liveStreamsProvider.notifier).load(),
      );
    }

    if (state.streams.isEmpty) {
      return _EmptyState(
        icon: Icons.live_tv_outlined,
        message: 'No streams are live right now.',
        sub: 'Check back soon or browse scheduled streams.',
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
          padding: const EdgeInsets.all(16),
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

// ─── Scheduled ────────────────────────────────────────────────────────────────

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
        icon: Icons.schedule,
        message: 'No scheduled streams.',
        sub: 'When creators schedule streams, they appear here.',
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
          padding: const EdgeInsets.all(16),
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

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Skeletons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 200,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 120,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  final VoidCallback onRefresh;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.sub,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load streams',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
