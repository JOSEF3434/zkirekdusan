// lib/features/profile/presentation/widgets/profile_live_streams_tab.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/live/data/live_streaming_repository.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';

/// Provider for loading all live streams created by a specific user.
final profileLiveStreamsProvider =
    FutureProvider.family<List<LiveStreamDto>, String>((ref, userId) async {
      final repo = ref.watch(liveStreamingRepositoryProvider);
      final response = await repo.getUserStreams(userId, page: 1, limit: 50);
      return response.items;
    });

enum _StreamFilter { all, live, scheduled, ended, drafts }

class ProfileLiveStreamsTab extends ConsumerStatefulWidget {
  final String userId;
  final bool isMyProfile;

  const ProfileLiveStreamsTab({
    super.key,
    required this.userId,
    this.isMyProfile = true,
  });

  @override
  ConsumerState<ProfileLiveStreamsTab> createState() =>
      _ProfileLiveStreamsTabState();
}

class _ProfileLiveStreamsTabState extends ConsumerState<ProfileLiveStreamsTab> {
  _StreamFilter _selectedFilter = _StreamFilter.all;

  @override
  Widget build(BuildContext context) {
    final streamsAsync = ref.watch(profileLiveStreamsProvider(widget.userId));
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    return streamsAsync.when(
      data: (streams) {
        // Filter logic
        final liveStreams = streams
            .where((s) => s.status == LiveStreamStatus.live)
            .toList();
        final scheduledStreams = streams
            .where((s) => s.status == LiveStreamStatus.scheduled)
            .toList();
        final endedStreams = streams
            .where(
              (s) =>
                  s.status == LiveStreamStatus.ended ||
                  s.status == LiveStreamStatus.vodReady ||
                  s.status == LiveStreamStatus.processing,
            )
            .toList();
        final draftStreams = streams
            .where((s) => s.status == LiveStreamStatus.draft)
            .toList();

        final displayedStreams = switch (_selectedFilter) {
          _StreamFilter.live => liveStreams,
          _StreamFilter.scheduled => scheduledStreams,
          _StreamFilter.ended => endedStreams,
          _StreamFilter.drafts => draftStreams,
          _StreamFilter.all => streams,
        };

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(profileLiveStreamsProvider(widget.userId));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header & Action Banner (for creator) ─────────────────────────
              if (widget.isMyProfile)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                            theme.colorScheme.secondary.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.cell_tower_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Live Stream Management',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Schedule, launch studio, or manage broadcasts',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => context.push('/live/studio'),
                            icon: const Icon(Icons.videocam_rounded, size: 16),
                            label: const Text(
                              'Go Live',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Filter Chips Bar ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All (${streams.length})',
                        filter: _StreamFilter.all,
                        icon: Icons.grid_view_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Live (${liveStreams.length})',
                        filter: _StreamFilter.live,
                        icon: Icons.circle,
                        iconColor: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Scheduled (${scheduledStreams.length})',
                        filter: _StreamFilter.scheduled,
                        icon: Icons.calendar_today_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Ended & VOD (${endedStreams.length})',
                        filter: _StreamFilter.ended,
                        icon: Icons.video_library_outlined,
                      ),
                      if (widget.isMyProfile) ...[
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Drafts (${draftStreams.length})',
                          filter: _StreamFilter.drafts,
                          icon: Icons.edit_note_rounded,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Stream List or Empty State ─────────────────────────────────
              if (displayedStreams.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.live_tv_rounded,
                              size: 54,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _emptyTitleForFilter(_selectedFilter),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _emptyDescForFilter(
                              _selectedFilter,
                              widget.isMyProfile,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (widget.isMyProfile) ...[
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () => context.push('/live/studio'),
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 18,
                              ),
                              label: Consumer(
                                builder: (_, ref, _) => Text(
                                  ref.watch(trProvider)('profile.start_live'),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final stream = displayedStreams[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _StreamCard(
                          stream: stream,
                          isOwner: widget.isMyProfile,
                          onRefresh: () => ref.invalidate(
                            profileLiveStreamsProvider(widget.userId),
                          ),
                        ),
                      );
                    }, childCount: displayedStreams.length),
                  ),
                ),
            ],
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
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                '${tr('profile.error_loading_streams')}: $err',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () =>
                    ref.invalidate(profileLiveStreamsProvider(widget.userId)),
                child: Text(tr('common.retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required _StreamFilter filter,
    required IconData icon,
    Color? iconColor,
  }) {
    final isSelected = _selectedFilter == filter;
    final theme = Theme.of(context);

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 14,
        color:
            iconColor ??
            (isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.4,
      ),
      selectedColor: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = filter);
      },
    );
  }

  String _emptyTitleForFilter(_StreamFilter filter) {
    return switch (filter) {
      _StreamFilter.live => 'No Streams Currently Live',
      _StreamFilter.scheduled => 'No Upcoming Scheduled Streams',
      _StreamFilter.ended => 'No Past Streams or VODs Yet',
      _StreamFilter.drafts => 'No Draft Streams Found',
      _StreamFilter.all => 'No Live Streams Found',
    };
  }

  String _emptyDescForFilter(_StreamFilter filter, bool isMyProfile) {
    if (!isMyProfile) {
      return 'This creator has not hosted any live broadcasts yet.';
    }
    return switch (filter) {
      _StreamFilter.live =>
        'You are not currently broadcasting. Go live anytime to connect with your audience!',
      _StreamFilter.scheduled =>
        'Schedule a broadcast in advance so your viewers can plan ahead.',
      _StreamFilter.ended =>
        'Recorded streams and VODs will appear here once your broadcasts finish.',
      _StreamFilter.drafts =>
        'Create and save draft stream settings to easily launch later.',
      _StreamFilter.all =>
        'Start broadcasting live to your audience or schedule upcoming events.',
    };
  }
}

// ── Stream Card with Full Status Badges & Management ─────────────────────────

class _StreamCard extends ConsumerWidget {
  final LiveStreamDto stream;
  final bool isOwner;
  final VoidCallback onRefresh;

  const _StreamCard({
    required this.stream,
    required this.isOwner,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: stream.status == LiveStreamStatus.live
              ? Colors.redAccent.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: stream.status == LiveStreamStatus.live ? 1.5 : 1.0,
        ),
      ),
      color: isDark
          ? const Color(0xFF161F2E)
          : theme.colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail / Video Preview Area ────────────────────────────────
          GestureDetector(
            onTap: () => _handleCardTap(context),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child:
                      stream.thumbnailUrl != null &&
                          stream.thumbnailUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl:
                              MediaUrlResolver.resolve(stream.thumbnailUrl!) ??
                              stream.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.black26,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, err) =>
                              _buildPlaceholderMedia(context, stream.status),
                        )
                      : _buildPlaceholderMedia(context, stream.status),
                ),

                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // Top Left: Full Status Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: _buildStatusBadge(context, stream.status),
                ),

                // Top Right: Visibility Badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: _buildVisibilityBadge(context, stream.visibility),
                ),

                // Bottom Left: Viewer count or Scheduled Date
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: _buildMediaBottomInfo(context, stream),
                ),

                // Bottom Right: Duration or Protocol
                if (stream.duration != null && stream.duration! > 0)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(stream.duration!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Metadata & Details ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        stream.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Management Menu (Three Dots)
                    _buildManagementMenu(context, ref),
                  ],
                ),

                if (stream.description != null &&
                    stream.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    stream.description!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Info tags: Group/Channel, Date, Likes
                Row(
                  children: [
                    if (stream.videoChannel != null) ...[
                      Icon(
                        Icons.tv_rounded,
                        size: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stream.videoChannel!.name,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatStreamTimestamp(stream),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const Spacer(),
                    if (stream.likesCount > 0) ...[
                      Icon(
                        Icons.favorite_rounded,
                        size: 13,
                        color: Colors.pinkAccent.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${stream.likesCount}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (stream.totalChatMessages > 0) ...[
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${stream.totalChatMessages}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // ── Quick Action Bar ───────────────────────────────────────
                _buildQuickActionBar(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderMedia(BuildContext context, LiveStreamStatus status) {
    final isLive = status == LiveStreamStatus.live;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLive
              ? [const Color(0xFF8B0000), const Color(0xFF1E0000)]
              : [const Color(0xFF1A233A), const Color(0xFF0D111A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLive
                  ? Icons.sensors_rounded
                  : (status == LiveStreamStatus.scheduled
                        ? Icons.event_available_rounded
                        : Icons.live_tv_rounded),
              size: 42,
              color: isLive ? Colors.redAccent : Colors.white70,
            ),
            const SizedBox(height: 6),
            Text(
              isLive
                  ? 'BROADCASTING'
                  : (status == LiveStreamStatus.scheduled
                        ? 'UPCOMING STREAM'
                        : 'LIVE ARCHIVE'),
              style: TextStyle(
                color: isLive ? Colors.redAccent : Colors.white54,
                fontSize: 10.5,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, LiveStreamStatus status) {
    Color bg;
    Color fg = Colors.white;
    String text;
    IconData? icon;

    switch (status) {
      case LiveStreamStatus.live:
        bg = const Color(0xFFDC2626); // Bright red
        text = 'LIVE';
        icon = Icons.circle;
        break;
      case LiveStreamStatus.scheduled:
        bg = const Color(0xFF2563EB); // Royal blue
        text = 'SCHEDULED';
        icon = Icons.calendar_month_rounded;
        break;
      case LiveStreamStatus.vodReady:
        bg = const Color(0xFF059669); // Emerald green
        text = 'VOD READY';
        icon = Icons.check_circle_rounded;
        break;
      case LiveStreamStatus.processing:
        bg = const Color(0xFFD97706); // Amber
        text = 'PROCESSING';
        icon = Icons.sync_rounded;
        break;
      case LiveStreamStatus.ended:
        bg = const Color(0xFF475569); // Slate grey
        text = 'ENDED';
        icon = Icons.stop_circle_rounded;
        break;
      case LiveStreamStatus.draft:
        bg = const Color(0xFF7C3AED); // Purple
        text = 'DRAFT';
        icon = Icons.edit_note_rounded;
        break;
      case LiveStreamStatus.cancelled:
        bg = const Color(0xFF6B7280);
        text = 'CANCELLED';
        break;
      case LiveStreamStatus.failed:
        bg = const Color(0xFFDC2626);
        text = 'FAILED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          if (status == LiveStreamStatus.live)
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.6),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: status == LiveStreamStatus.live ? 8 : 11,
              color: fg,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityBadge(
    BuildContext context,
    LiveStreamVisibility visibility,
  ) {
    final (icon, label) = switch (visibility) {
      LiveStreamVisibility.private => (Icons.lock_rounded, 'Private'),
      LiveStreamVisibility.groupOnly => (Icons.group_rounded, 'Group Only'),
      LiveStreamVisibility.unlisted => (Icons.link_rounded, 'Unlisted'),
      LiveStreamVisibility.public => (Icons.public_rounded, 'Public'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
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
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaBottomInfo(BuildContext context, LiveStreamDto stream) {
    if (stream.status == LiveStreamStatus.live) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.remove_red_eye_rounded,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              '${stream.currentViewerCount} watching',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (stream.status == LiveStreamStatus.scheduled &&
        stream.scheduledAt != null) {
      final dt = DateTime.tryParse(stream.scheduledAt!);
      final text = dt != null
          ? DateFormat('EEE, MMM d • h:mm a').format(dt)
          : stream.scheduledAt!;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.alarm_rounded, size: 12, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (stream.peakViewerCount > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Peak: ${stream.peakViewerCount} viewers',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildQuickActionBar(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Primary Action
        if (stream.status == LiveStreamStatus.live) ...[
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => context.push('/live/${stream.id}'),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text(
                'Watch Live',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          if (isOwner) ...[
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Enter Studio',
              onPressed: () => context.push('/live/studio'),
              icon: const Icon(Icons.video_settings_rounded, size: 18),
            ),
            const SizedBox(width: 6),
            IconButton.outlined(
              tooltip: 'End Stream',
              color: Colors.redAccent,
              onPressed: () => _confirmEndStream(context, ref),
              icon: const Icon(Icons.stop_circle_outlined, size: 18),
            ),
          ],
        ] else if (stream.status == LiveStreamStatus.scheduled) ...[
          Expanded(
            child: isOwner
                ? FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _startScheduledStream(context, ref),
                    icon: const Icon(Icons.videocam_rounded, size: 18),
                    label: const Text(
                      'Go Live Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  )
                : OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _shareStream(context),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Consumer(
                      builder: (_, ref, _) =>
                          Text(ref.watch(trProvider)('profile.remind_me')),
                    ),
                  ),
          ),
          if (isOwner) ...[
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Edit Stream',
              onPressed: () => _showEditStreamDialog(context, ref),
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              tooltip: 'Share',
              onPressed: () => _shareStream(context),
              icon: const Icon(Icons.share_outlined, size: 18),
            ),
          ],
        ] else if (stream.status == LiveStreamStatus.draft) ...[
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => context.push('/live/studio'),
              icon: const Icon(Icons.rocket_launch_rounded, size: 18),
              label: const Text(
                'Open in Studio',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Edit Draft',
            onPressed: () => _showEditStreamDialog(context, ref),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          const SizedBox(width: 6),
          IconButton.outlined(
            tooltip: 'Delete Draft',
            color: theme.colorScheme.error,
            onPressed: () => _confirmDeleteStream(context, ref),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
          ),
        ] else ...[
          // Ended / VOD Ready / Processing
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _handleCardTap(context),
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: Text(
                stream.status == LiveStreamStatus.vodReady
                    ? 'Watch Recording'
                    : 'View Archive',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (isOwner && stream.status == LiveStreamStatus.ended) ...[
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: () => _publishVod(context, ref),
              icon: const Icon(Icons.publish_rounded, size: 16),
              label: Consumer(
                builder: (_, ref, _) => Text(
                  ref.watch(trProvider)('profile.publish_vod'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Share',
            onPressed: () => _shareStream(context),
            icon: const Icon(Icons.share_outlined, size: 18),
          ),
        ],
      ],
    );
  }

  Widget _buildManagementMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (val) {
        switch (val) {
          case 'watch':
            _handleCardTap(context);
            break;
          case 'studio':
            context.push('/live/studio');
            break;
          case 'start':
            _startScheduledStream(context, ref);
            break;
          case 'edit':
            _showEditStreamDialog(context, ref);
            break;
          case 'key':
            _showStreamKeyModal(context, ref);
            break;
          case 'publish':
            _publishVod(context, ref);
            break;
          case 'end':
            _confirmEndStream(context, ref);
            break;
          case 'share':
            _shareStream(context);
            break;
          case 'delete':
            _confirmDeleteStream(context, ref);
            break;
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'watch',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.visibility_outlined),
            title: Text('View Stream Details'),
          ),
        ),
        if (isOwner &&
            (stream.status == LiveStreamStatus.draft ||
                stream.status == LiveStreamStatus.scheduled)) ...[
          const PopupMenuItem(
            value: 'start',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.videocam_rounded, color: Colors.redAccent),
              title: Text(
                'Go Live Now',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const PopupMenuItem(
            value: 'studio',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.video_settings_rounded),
              title: Text('Open Studio'),
            ),
          ),
        ],
        if (isOwner) ...[
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit Stream Info'),
            ),
          ),
          const PopupMenuItem(
            value: 'key',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.key_rounded),
              title: Text('Stream Key & RTMP'),
            ),
          ),
        ],
        const PopupMenuItem(
          value: 'share',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.share_outlined),
            title: Text('Share Stream Link'),
          ),
        ),
        if (isOwner && stream.status == LiveStreamStatus.ended)
          const PopupMenuItem(
            value: 'publish',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.publish_rounded, color: Colors.green),
              title: Text('Publish as VOD'),
            ),
          ),
        if (isOwner && stream.status == LiveStreamStatus.live)
          const PopupMenuItem(
            value: 'end',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.stop_circle_rounded, color: Colors.redAccent),
              title: Text(
                'End Live Stream',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        if (isOwner) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text(
                'Delete Stream',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _handleCardTap(BuildContext context) {
    if (stream.status == LiveStreamStatus.live ||
        stream.status == LiveStreamStatus.vodReady ||
        stream.status == LiveStreamStatus.ended) {
      context.push('/live/${stream.id}');
    } else if (isOwner) {
      context.push('/live/studio');
    }
  }

  Future<void> _startScheduledStream(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final repo = ref.read(liveStreamingRepositoryProvider);
      await repo.startStream(stream.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stream is now LIVE! Opening studio...'),
            backgroundColor: Colors.green,
          ),
        );
        context.push('/live/studio');
        onRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start stream: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _publishVod(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(liveStreamingRepositoryProvider);
      await repo.publishVod(stream.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stream VOD published successfully!'),
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
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _confirmEndStream(BuildContext context, WidgetRef ref) async {
    final tr = ref.read(trProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('profile.end_stream_title')),
        content: Text(tr('profile.end_stream_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('profile.end_stream_btn')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(liveStreamingRepositoryProvider);
        await repo.endStream(stream.id);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(tr('profile.stream_ended'))));
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(tr('profile.end_stream_error', {'error': e.toString()}))));
        }
      }
    }
  }

  Future<void> _confirmDeleteStream(BuildContext context, WidgetRef ref) async {
    final tr = ref.read(trProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('profile.delete_stream_title')),
        content: Text(
          tr('profile.delete_stream_msg', {'title': stream.title}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('common.delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(liveStreamingRepositoryProvider);
        await repo.deleteStream(
          stream.id,
          channelId: stream.videoChannelId.isNotEmpty
              ? stream.videoChannelId
              : null,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('profile.stream_deleted'))),
          );
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(tr('profile.delete_stream_error', {'error': e.toString()}))));
        }
      }
    }
  }

  void _shareStream(BuildContext context) {
    final link = 'https://app.zikrekidusan.com/live/${stream.id}';
    Share.share(
      'Watch "${stream.title}" on Zikre Kidusan Live:\n$link',
      subject: stream.title,
    );
  }

  void _showStreamKeyModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RTMP Stream Configuration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Use these settings in OBS Studio, Streamlabs, or PRISM to broadcast:',
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Server Ingest URL',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        stream.rtmpIngestUrl ??
                            'rtmp://live.zikrekidusan.com/live',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                stream.rtmpIngestUrl ??
                                'rtmp://live.zikrekidusan.com/live',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('RTMP URL copied to clipboard!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Stream Slug / ID',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        stream.slug.isNotEmpty ? stream.slug : stream.id,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: stream.slug.isNotEmpty
                                ? stream.slug
                                : stream.id,
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Stream key copied to clipboard!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditStreamDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController(text: stream.title);
    final descCtrl = TextEditingController(text: stream.description ?? '');
    LiveStreamVisibility selectedVisibility = stream.visibility;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Stream Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Stream Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Visibility',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<LiveStreamVisibility>(
                  initialValue: selectedVisibility,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: LiveStreamVisibility.public,
                      child: Text('Public (Anyone can discover)'),
                    ),
                    DropdownMenuItem(
                      value: LiveStreamVisibility.unlisted,
                      child: Text('Unlisted (Link only)'),
                    ),
                    DropdownMenuItem(
                      value: LiveStreamVisibility.groupOnly,
                      child: Text('Group Members Only'),
                    ),
                    DropdownMenuItem(
                      value: LiveStreamVisibility.private,
                      child: Text('Private (Only me)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedVisibility = val);
                    }
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final newTitle = titleCtrl.text.trim();
                      if (newTitle.isEmpty) return;

                      try {
                        final repo = ref.read(liveStreamingRepositoryProvider);
                        await repo.updateStream(stream.id, {
                          'title': newTitle,
                          'description': descCtrl.text.trim(),
                          'visibility': selectedVisibility.name.toUpperCase(),
                        });
                        if (modalCtx.mounted) Navigator.pop(modalCtx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stream updated successfully!'),
                            ),
                          );
                          onRefresh();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update stream: $e'),
                            ),
                          );
                        }
                      }
                    },
                    child: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('profile.save_changes'))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatStreamTimestamp(LiveStreamDto stream) {
    if (stream.status == LiveStreamStatus.scheduled &&
        stream.scheduledAt != null) {
      final dt = DateTime.tryParse(stream.scheduledAt!);
      if (dt != null) {
        return dt.isAfter(DateTime.now())
            ? 'Starts ${timeago.format(dt, allowFromNow: true)}'
            : DateFormat('MMM d, y').format(dt);
      }
    }
    final dt = DateTime.tryParse(stream.createdAt);
    if (dt != null) {
      return timeago.format(dt);
    }
    return '';
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
