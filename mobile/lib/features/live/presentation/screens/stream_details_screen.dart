// lib/features/live/presentation/screens/stream_details_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mobile/app/env/env.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/live/data/live_streaming_repository.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';

/// Provider for loading a specific live stream's details by ID.
final streamDetailProvider =
    FutureProvider.family<LiveStreamDto, String>((ref, streamId) async {
      final repo = ref.watch(liveStreamingRepositoryProvider);
      return repo.getStreamById(streamId);
    });

class StreamDetailsScreen extends ConsumerStatefulWidget {
  final String streamId;

  const StreamDetailsScreen({super.key, required this.streamId});

  @override
  ConsumerState<StreamDetailsScreen> createState() =>
      _StreamDetailsScreenState();
}

class _StreamDetailsScreenState extends ConsumerState<StreamDetailsScreen> {
  bool _isActionLoading = false;

  void _safeBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '0:00';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${secs.toString().padLeft(2, '0')}s';
    }
    return '${minutes}m ${secs.toString().padLeft(2, '0')}s';
  }

  String _formatTimestamp(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '—';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    return DateFormat('EEE, MMM d, yyyy • h:mm a').format(dt.toLocal());
  }

  Future<void> _publishVod(LiveStreamDto stream) async {
    setState(() => _isActionLoading = true);
    try {
      final repo = ref.read(liveStreamingRepositoryProvider);
      await repo.publishVod(stream.id);
      ref.invalidate(streamDetailProvider(widget.streamId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stream VOD published successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish VOD: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _shareStream(LiveStreamDto stream) async {
    final shareUrl = '${Env.frontendBaseUrl}/live/${stream.id}';
    final shareText =
        'Check out "${stream.title}" on Antigravity Live: $shareUrl';
    try {
      await Share.share(shareText, subject: stream.title);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: shareUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stream link copied to clipboard!')),
        );
      }
    }
  }

  Future<void> _confirmDeleteStream(LiveStreamDto stream) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Stream Archive'),
        content: Text(
          'Are you sure you want to delete "${stream.title}"? This will permanently remove the stream archive and recording.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isActionLoading = true);
    try {
      final repo = ref.read(liveStreamingRepositoryProvider);
      await repo.deleteStream(stream.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stream archive deleted successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _safeBack(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete stream: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final streamAsync = ref.watch(streamDetailProvider(widget.streamId));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final authUser = ref.watch(authProvider).user;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _safeBack(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () => _safeBack(context),
          ),
          title: const Text(
            'Stream Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: () => ref.invalidate(streamDetailProvider(widget.streamId)),
            ),
            streamAsync.when(
              data: (stream) => IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share',
                onPressed: () => _shareStream(stream),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
        body: streamAsync.when(
          data: (stream) {
            final isOwner =
                authUser != null &&
                (stream.createdById == authUser.id ||
                    (stream.createdBy?.username != null &&
                        stream.createdBy!.username == authUser.username));

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(streamDetailProvider(widget.streamId));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Hero Media Stage ─────────────────────────────────────
                    _buildMediaHero(context, stream),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Title & Visibility ─────────────────────────────
                          Text(
                            stream.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ── Status and Tag Chips ───────────────────────────
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildStatusChip(context, stream.status),
                              _buildVisibilityChip(context, stream.visibility),
                              if (stream.protocol.name.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    stream.protocol.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Primary Action Row ─────────────────────────────
                          _buildPrimaryActionRow(context, stream, isOwner),
                          const SizedBox(height: 20),

                          // ── Broadcast Performance & Metrics ────────────────
                          Text(
                            'Stream Analytics & Metrics',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildMetricsGrid(context, stream),
                          const SizedBox(height: 20),

                          // ── Channel & Host Information ─────────────────────
                          Text(
                            'Host & Channel',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildHostAndChannelCard(context, stream),
                          const SizedBox(height: 20),

                          // ── Broadcast Timeline ─────────────────────────────
                          Text(
                            'Broadcast Timeline',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildTimelineCard(context, stream),
                          const SizedBox(height: 20),

                          // ── Stream Description & Topics ───────────────────
                          if (stream.description != null &&
                              stream.description!.trim().isNotEmpty) ...[
                            Text(
                              'About this Broadcast',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: cs.outlineVariant.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                stream.description!.trim(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.45,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // ── Categories & Tags ──────────────────────────────
                          if (stream.categories.isNotEmpty ||
                              stream.tags.isNotEmpty) ...[
                            Text(
                              'Categories & Tags',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                for (final cat in stream.categories)
                                  Chip(
                                    avatar: const Icon(Icons.tag_rounded, size: 14),
                                    label: Text(cat),
                                    backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onPrimaryContainer,
                                    ),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                for (final tag in stream.tags)
                                  Chip(
                                    label: Text('#$tag'),
                                    backgroundColor: cs.surfaceContainerHighest,
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                    ),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],

                          // ── Management Actions (Owner only) ────────────────
                          if (isOwner) ...[
                            const Divider(height: 32),
                            Text(
                              'Manage Stream Recording',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (stream.status == LiveStreamStatus.ended)
                                  Expanded(
                                    child: FilledButton.tonalIcon(
                                      onPressed: _isActionLoading
                                          ? null
                                          : () => _publishVod(stream),
                                      icon: const Icon(Icons.publish_rounded, size: 18),
                                      label: const Text('Publish as VOD'),
                                    ),
                                  ),
                                if (stream.status == LiveStreamStatus.ended)
                                  const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      side: const BorderSide(color: Colors.redAccent),
                                    ),
                                    onPressed: _isActionLoading
                                        ? null
                                        : () => _confirmDeleteStream(stream),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Delete Archive'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 54,
                    color: cs.error,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Failed to load stream details: $err',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () =>
                        ref.invalidate(streamDetailProvider(widget.streamId)),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Sub-Widgets ─────────────────────────────────────────────────────────────

  Widget _buildMediaHero(BuildContext context, LiveStreamDto stream) {
    final hasThumb =
        stream.thumbnailUrl != null && stream.thumbnailUrl!.isNotEmpty;
    final hasVod =
        stream.status == LiveStreamStatus.vodReady ||
        (stream.hlsUrl != null && stream.hlsUrl!.isNotEmpty);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image or Gradient
          if (hasThumb)
            CachedNetworkImage(
              imageUrl:
                  MediaUrlResolver.resolve(stream.thumbnailUrl!) ??
                  stream.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, err) => _buildHeroPlaceholder(stream),
            )
          else
            _buildHeroPlaceholder(stream),

          // Gradient overlay
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // Top Left Status Badge
          Positioned(
            top: 14,
            left: 14,
            child: _buildStatusChip(context, stream.status),
          ),

          // Top Right Visibility Badge
          Positioned(
            top: 14,
            right: 14,
            child: _buildVisibilityChip(context, stream.visibility),
          ),

          // Center Play Button (if VOD available)
          if (hasVod)
            Center(
              child: GestureDetector(
                onTap: () => context.push('/live/${stream.id}'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 38,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Bottom Left Duration
          if (stream.duration != null && stream.duration! > 0)
            Positioned(
              bottom: 12,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(stream.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroPlaceholder(LiveStreamDto stream) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              stream.status == LiveStreamStatus.live
                  ? Icons.sensors_rounded
                  : Icons.live_tv_rounded,
              size: 48,
              color: stream.status == LiveStreamStatus.live
                  ? Colors.redAccent
                  : Colors.white70,
            ),
            const SizedBox(height: 8),
            Text(
              stream.status == LiveStreamStatus.live
                  ? 'LIVE BROADCAST'
                  : 'STREAM ARCHIVE',
              style: TextStyle(
                color: stream.status == LiveStreamStatus.live
                    ? Colors.redAccent
                    : Colors.white54,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, LiveStreamStatus status) {
    Color bg;
    String label;
    IconData icon;

    switch (status) {
      case LiveStreamStatus.live:
        bg = const Color(0xFFDC2626);
        label = 'LIVE';
        icon = Icons.circle;
        break;
      case LiveStreamStatus.vodReady:
        bg = const Color(0xFF059669);
        label = 'VOD READY';
        icon = Icons.check_circle_rounded;
        break;
      case LiveStreamStatus.processing:
        bg = const Color(0xFFD97706);
        label = 'PROCESSING';
        icon = Icons.sync_rounded;
        break;
      case LiveStreamStatus.scheduled:
        bg = const Color(0xFF2563EB);
        label = 'SCHEDULED';
        icon = Icons.calendar_month_rounded;
        break;
      case LiveStreamStatus.ended:
        bg = const Color(0xFF475569);
        label = 'ENDED';
        icon = Icons.stop_circle_rounded;
        break;
      case LiveStreamStatus.draft:
        bg = const Color(0xFF7C3AED);
        label = 'DRAFT';
        icon = Icons.edit_note_rounded;
        break;
      case LiveStreamStatus.cancelled:
        bg = const Color(0xFF6B7280);
        label = 'CANCELLED';
        icon = Icons.cancel_outlined;
        break;
      case LiveStreamStatus.failed:
        bg = const Color(0xFFDC2626);
        label = 'FAILED';
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityChip(
    BuildContext context,
    LiveStreamVisibility visibility,
  ) {
    final (icon, label) = switch (visibility) {
      LiveStreamVisibility.public => (Icons.public_rounded, 'Public'),
      LiveStreamVisibility.private => (Icons.lock_rounded, 'Private'),
      LiveStreamVisibility.groupOnly => (Icons.group_rounded, 'Group Only'),
      LiveStreamVisibility.unlisted => (Icons.link_rounded, 'Unlisted'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionRow(
    BuildContext context,
    LiveStreamDto stream,
    bool isOwner,
  ) {
    final hasVod =
        stream.status == LiveStreamStatus.vodReady ||
        (stream.hlsUrl != null && stream.hlsUrl!.isNotEmpty);

    return Row(
      children: [
        if (hasVod) ...[
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => context.push('/live/${stream.id}'),
              icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
              label: const Text(
                'Watch Recording',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (stream.status == LiveStreamStatus.ended && isOwner) ...[
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isActionLoading ? null : () => _publishVod(stream),
              icon: const Icon(Icons.publish_rounded, size: 20),
              label: const Text(
                'Publish VOD',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _shareStream(stream),
          icon: const Icon(Icons.share_outlined, size: 18),
          label: const Text('Share'),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, LiveStreamDto stream) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final metrics = [
      (
        'Peak Viewers',
        '${stream.peakViewerCount}',
        Icons.trending_up_rounded,
        const Color(0xFF3B82F6),
      ),
      (
        'Total Viewers',
        '${stream.totalViewerCount}',
        Icons.groups_rounded,
        const Color(0xFF8B5CF6),
      ),
      (
        'Duration',
        _formatDuration(stream.duration),
        Icons.timer_outlined,
        const Color(0xFF10B981),
      ),
      (
        'Total Likes',
        '${stream.likesCount}',
        Icons.favorite_rounded,
        const Color(0xFFEC4899),
      ),
      (
        'Chat Messages',
        '${stream.totalChatMessages}',
        Icons.chat_bubble_outline_rounded,
        const Color(0xFFF59E0B),
      ),
      (
        'Reactions',
        '${stream.totalReactions}',
        Icons.emoji_emotions_outlined,
        const Color(0xFF06B6D4),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final (label, val, icon, color) = metrics[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 6),
              Text(
                val,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHostAndChannelCard(BuildContext context, LiveStreamDto stream) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          // Host row
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cs.primaryContainer,
                backgroundImage: stream.createdBy?.avatarUrl != null
                    ? CachedNetworkImageProvider(
                        MediaUrlResolver.resolve(stream.createdBy!.avatarUrl!) ??
                            stream.createdBy!.avatarUrl!,
                      )
                    : null,
                child: stream.createdBy?.avatarUrl == null
                    ? Text(
                        stream.createdBy?.username?.isNotEmpty == true
                            ? stream.createdBy!.username![0].toUpperCase()
                            : 'H',
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream.createdBy?.username ?? 'Broadcaster',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Stream Host',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Channel row (if available)
          if (stream.videoChannel != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.secondaryContainer,
                  backgroundImage: stream.videoChannel!.avatarUrl != null
                      ? CachedNetworkImageProvider(
                          MediaUrlResolver.resolve(stream.videoChannel!.avatarUrl!) ??
                              stream.videoChannel!.avatarUrl!,
                        )
                      : null,
                  child: stream.videoChannel!.avatarUrl == null
                      ? Icon(Icons.tv_rounded, size: 18, color: cs.onSecondaryContainer)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stream.videoChannel!.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (stream.group != null)
                        Text(
                          'Group: ${stream.group!.name}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: cs.outline,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, LiveStreamDto stream) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final items = [
      ('Started At', _formatTimestamp(stream.startedAt), Icons.play_arrow_outlined),
      ('Ended At', _formatTimestamp(stream.endedAt), Icons.stop_circle_outlined),
      ('Scheduled At', _formatTimestamp(stream.scheduledAt), Icons.calendar_today_outlined),
      ('Created At', _formatTimestamp(stream.createdAt), Icons.access_time_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 16),
            Row(
              children: [
                Icon(items[i].$3, size: 16, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  items[i].$1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  items[i].$2,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
