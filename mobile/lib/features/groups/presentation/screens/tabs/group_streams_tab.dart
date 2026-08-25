// lib/features/groups/presentation/screens/tabs/group_streams_tab.dart
// Full CRUD management for group live streams & recordings with one-tap VOD publishing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/groups/domain/group_context_dto.dart';
import 'package:mobile/features/live/data/live_streaming_repository.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/presentation/widgets/live_badge_widget.dart';
import 'package:mobile/features/live/presentation/widgets/viewer_count_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class GroupStreamsTab extends ConsumerStatefulWidget {
  final GroupContextDto groupContext;
  final VideoChannelSummaryDto? activeChannel;

  const GroupStreamsTab({
    super.key,
    required this.groupContext,
    required this.activeChannel,
  });

  @override
  ConsumerState<GroupStreamsTab> createState() => _GroupStreamsTabState();
}

class _GroupStreamsTabState extends ConsumerState<GroupStreamsTab> {
  bool _isLoading = true;
  String? _error;
  List<LiveStreamDto> _streams = [];
  String _filter = 'all'; // all, live, scheduled, ended

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  @override
  void didUpdateWidget(covariant GroupStreamsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeChannel?.id != widget.activeChannel?.id) {
      _loadStreams();
    }
  }

  Future<void> _loadStreams() async {
    final channelId = widget.activeChannel?.id;
    if (channelId == null || channelId.isEmpty) {
      setState(() {
        _isLoading = false;
        _streams = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(liveStreamingRepositoryProvider);
      final res = await repo.getChannelStreams(channelId, limit: 50);
      if (mounted) {
        setState(() {
          _streams = res.items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is AppException
              ? e.message
              : e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<LiveStreamDto> get _filteredStreams {
    switch (_filter) {
      case 'live':
        return _streams.where((s) => s.status == LiveStreamStatus.live).toList();
      case 'scheduled':
        return _streams
            .where((s) => s.status == LiveStreamStatus.scheduled)
            .toList();
      case 'ended':
        return _streams
            .where((s) =>
                s.status == LiveStreamStatus.ended ||
                s.status == LiveStreamStatus.vodReady ||
                s.status == LiveStreamStatus.processing)
            .toList();
      default:
        return _streams;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final channel = widget.activeChannel;
    final canStream = widget.groupContext.capabilities.canStartLive ||
        widget.groupContext.capabilities.canUploadVideo;

    if (channel == null) {
      return const Center(child: Text('No active channel selected'));
    }

    return Scaffold(
      floatingActionButton: canStream
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/live/studio?channelId=${channel.id}'),
              icon: const Icon(Icons.videocam_outlined),
              label: const Text('Go Live'),
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadStreams,
        child: Column(
          children: [
            // Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All Streams'),
                    const SizedBox(width: 8),
                    _buildFilterChip('live', 'Live Now'),
                    const SizedBox(width: 8),
                    _buildFilterChip('scheduled', 'Scheduled'),
                    const SizedBox(width: 8),
                    _buildFilterChip('ended', 'Recordings & VOD'),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorView(theme)
                      : _filteredStreams.isEmpty
                          ? _buildEmptyView(theme)
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredStreams.length,
                              itemBuilder: (ctx, i) {
                                return _StreamCard(
                                  stream: _filteredStreams[i],
                                  canManage: canStream,
                                  onRefresh: _loadStreams,
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = key),
    );
  }

  Widget _buildEmptyView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.live_tv_outlined,
                size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No live streams found',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _filter == 'live'
                  ? 'There are no active live broadcasts right now.'
                  : 'Start a live broadcast or schedule a stream for this channel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error ?? 'Failed to load streams', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loadStreams,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreamCard extends ConsumerWidget {
  final LiveStreamDto stream;
  final bool canManage;
  final VoidCallback onRefresh;

  const _StreamCard({
    required this.stream,
    required this.canManage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLive = stream.status == LiveStreamStatus.live;
    final isEnded = stream.status == LiveStreamStatus.ended ||
        stream.status == LiveStreamStatus.vodReady;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (isLive) {
            context.push('/live/room/${stream.id}');
          } else if (canManage && stream.status == LiveStreamStatus.draft) {
            context.push('/live/studio?channelId=${stream.videoChannelId}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail / Live indicator box
                  Container(
                    width: 100,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                      image: stream.thumbnailUrl != null
                          ? DecorationImage(
                              image: NetworkImage(stream.thumbnailUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Center(
                      child: isLive
                          ? const LiveBadgeWidget(small: true)
                          : Icon(
                              isEnded ? Icons.videocam : Icons.schedule,
                              color: Colors.white70,
                              size: 28,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stream.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (stream.description != null &&
                            stream.description!.isNotEmpty)
                          Text(
                            stream.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (isLive)
                              ViewerCountWidget(count: stream.currentViewerCount)
                            else if (stream.startedAt != null)
                              Text(
                                timeago.format(
                                  DateTime.tryParse(stream.startedAt!) ??
                                      DateTime.now(),
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              )
                            else if (stream.scheduledAt != null)
                              Text(
                                'Scheduled for: ${stream.scheduledAt}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isLive)
                    FilledButton.icon(
                      onPressed: () => context.push('/live/room/${stream.id}'),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Watch Live'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  if (isEnded && canManage) ...[
                    OutlinedButton.icon(
                      onPressed: () => _publishVod(context, ref),
                      icon: const Icon(Icons.video_library, size: 16),
                      label: const Text('Post as Video (VOD)'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (canManage && !isLive)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red,
                      tooltip: 'Delete Stream',
                      onPressed: () => _confirmDelete(context, ref),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _publishVod(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(liveStreamingRepositoryProvider);
      await repo.publishVod(stream.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stream published as Channel Video successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        onRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish VOD: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Stream?'),
        content: const Text('This will delete this live stream recording.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final repo = ref.read(liveStreamingRepositoryProvider);
        await repo.deleteStream(stream.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stream deleted')),
          );
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete stream: $e')),
          );
        }
      }
    }
  }
}
