// lib/features/settings/presentation/widgets/platform_overview_view.dart

import 'package:flutter/material.dart';
import 'package:mobile/features/settings/domain/public_system_report_model.dart';

/// Reusable, responsive platform-wide System Report overview widget.
/// Renders Users (by role), Groups, Channels (with video & live stream counts),
/// Video Details, Top Videos (by likes, comments, views, downloads),
/// Live Streams with viewers, and Platform Totals.
class PlatformOverviewView extends StatefulWidget {
  final PlatformOverviewModel overview;
  final VoidCallback? onRefresh;
  final bool isAdminView;

  const PlatformOverviewView({
    super.key,
    required this.overview,
    this.onRefresh,
    this.isAdminView = false,
  });

  @override
  State<PlatformOverviewView> createState() => _PlatformOverviewViewState();
}

class _PlatformOverviewViewState extends State<PlatformOverviewView> {
  int _topVideoFilterIndex = 0; // 0: Likes, 1: Comments, 2: Views, 3: Downloads

  @override
  Widget build(BuildContext context) {
    final o = widget.overview;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header bar with timestamp and refresh
        if (widget.isAdminView)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.analytics_rounded, color: Colors.blue, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'All-Over System Report & Live Analytics',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (o.generatedAt != null)
                        Text(
                          'Live snapshot: ${_formatDateTime(o.generatedAt!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.onRefresh != null)
                  OutlinedButton.icon(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                  ),
              ],
            ),
          ),

        // 1. Executive KPI Summary Grid
        _buildKpiSummaryGrid(context, o),
        const SizedBox(height: 16),

        // 2. Users Breakdown (by Role & Status)
        if (o.users != null) ...[
          _buildSectionCard(
            context,
            isDark: isDark,
            title: 'Users by Role & Status',
            icon: Icons.people_alt_rounded,
            color: Colors.blue,
            trailing: _badge('${o.users!.total} Total', Colors.blue),
            child: _buildUsersSection(context, o.users!),
          ),
          const SizedBox(height: 16),
        ],

        // 3. Groups & Messaging Channels
        if (o.groups != null) ...[
          _buildSectionCard(
            context,
            isDark: isDark,
            title: 'Groups & Communities',
            icon: Icons.groups_rounded,
            color: Colors.deepPurple,
            trailing: _badge('${o.groups!.total} Groups', Colors.deepPurple),
            child: _buildGroupsSection(o.groups!),
          ),
          const SizedBox(height: 16),
        ],

        // 4. Video Channels (Each channel with uploaded video & live stream count)
        if (o.channels != null) ...[
          _buildSectionCard(
            context,
            isDark: isDark,
            title: 'Channels (Videos & Live Streams)',
            icon: Icons.subscriptions_rounded,
            color: Colors.purple,
            trailing: _badge('${o.channels!.total} Channels', Colors.purple),
            child: _buildChannelsSection(context, o.channels!),
          ),
          const SizedBox(height: 16),
        ],

        // 5. Total Videos & Video Details
        if (o.videos != null) ...[
          _buildSectionCard(
            context,
            isDark: isDark,
            title: 'Videos Information & Engagement',
            icon: Icons.video_library_rounded,
            color: Colors.teal,
            trailing: _badge('${o.videos!.total} Videos', Colors.teal),
            child: _buildVideosSection(o.videos!),
          ),
          const SizedBox(height: 16),
        ],

        // 6. Top Videos (by Likes, Comments, Views, Downloads)
        if (o.topVideos != null) ...[
          _buildSectionCard(
            context,
            isDark: isDark,
            title: 'Top Videos in System',
            icon: Icons.emoji_events_rounded,
            color: Colors.amber.shade700,
            child: _buildTopVideosSection(context, o.topVideos!),
          ),
          const SizedBox(height: 16),
        ],

        // 7. Live Streams & Viewers
        if (o.liveStreams != null) ...[
          _buildSectionCard(
            context,
            isDark: isDark,
            title: 'Live Streams & Viewers',
            icon: Icons.live_tv_rounded,
            color: Colors.red,
            trailing: o.liveStreams!.liveNow > 0
                ? _badge('${o.liveStreams!.liveNow} LIVE NOW', Colors.red)
                : _badge('${o.liveStreams!.total} Streams', Colors.grey),
            child: _buildLiveStreamsSection(context, o.liveStreams!),
          ),
          const SizedBox(height: 16),
        ],

        // 8. Additional Platform Totals (Posts, Stories, Books, Files/Storage)
        if (o.platformTotals != null) ...[
          _buildSectionCard(
            context,
            isDark: isDark,
            title: 'All-Over Content & Storage Totals',
            icon: Icons.dashboard_customize_rounded,
            color: Colors.indigo,
            child: _buildPlatformTotalsSection(o.platformTotals!),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildKpiSummaryGrid(BuildContext context, PlatformOverviewModel o) {
    final cards = <_KpiItem>[
      if (o.users != null)
        _KpiItem(
          label: 'Total Users',
          value: _formatNumber(o.users!.total),
          subtitle: '${o.users!.byStatus['ACTIVE'] ?? 0} active',
          icon: Icons.people_rounded,
          color: Colors.blue,
        ),
      if (o.groups != null)
        _KpiItem(
          label: 'Total Groups',
          value: _formatNumber(o.groups!.total),
          subtitle: '${o.groups!.totalMembers} members',
          icon: Icons.groups_rounded,
          color: Colors.deepPurple,
        ),
      if (o.channels != null)
        _KpiItem(
          label: 'Video Channels',
          value: _formatNumber(o.channels!.total),
          subtitle: '${o.channels!.active} active • ${o.channels!.verified} verified',
          icon: Icons.tv_rounded,
          color: Colors.purple,
        ),
      if (o.videos != null)
        _KpiItem(
          label: 'Total Videos',
          value: _formatNumber(o.videos!.total),
          subtitle: '${_formatNumber(o.videos!.totalViews)} views',
          icon: Icons.play_circle_fill_rounded,
          color: Colors.teal,
        ),
      if (o.liveStreams != null)
        _KpiItem(
          label: 'Live Streams',
          value: _formatNumber(o.liveStreams!.total),
          subtitle: '${o.liveStreams!.liveNow} live • ${o.liveStreams!.currentViewers} watching',
          icon: Icons.live_tv_rounded,
          color: Colors.red,
        ),
      if (o.platformTotals != null)
        _KpiItem(
          label: 'Media Storage',
          value: _formatBytes(o.platformTotals!.totalStorageBytes),
          subtitle: '${_formatNumber(o.platformTotals!.totalFiles)} stored files',
          icon: Icons.cloud_done_rounded,
          color: Colors.indigo,
        ),
    ];

    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 760
            ? 3
            : (constraints.maxWidth > 460 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 96,
          ),
          itemBuilder: (context, i) {
            final item = cards[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: item.color.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.value,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: item.color,
                          ),
                        ),
                        Text(
                          item.subtitle,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUsersSection(BuildContext context, PlatformUsersOverview users) {
    final total = users.total > 0 ? users.total : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Users by Role',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 10),
        ...users.byRole.map((r) {
          final pct = r.count / total;
          final color = _roleColor(r.role);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.role.replaceAll('_', ' '),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${_formatNumber(r.count)} (${(pct * 100).toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }),
        if (users.byStatus.isNotEmpty) ...[
          const Divider(height: 20),
          const Text(
            'Account Status Breakdown',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: users.byStatus.entries.map((e) {
              final c = e.key == 'ACTIVE'
                  ? Colors.green
                  : (e.key == 'BANNED' ? Colors.red : Colors.orange);
              return _statPill('${e.key}: ${e.value}', c);
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildGroupsSection(PlatformGroupsOverview groups) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _metricBox('Total Groups', '${groups.total}', Colors.deepPurple),
        _metricBox('Active', '${groups.active}', Colors.green),
        _metricBox('Pending Approval', '${groups.pending}', Colors.orange),
        _metricBox('Suspended', '${groups.suspended}', Colors.red),
        _metricBox('Group Members', _formatNumber(groups.totalMembers), Colors.blue),
        _metricBox('Group Channels', _formatNumber(groups.messagingChannels), Colors.indigo),
      ],
    );
  }

  Widget _buildChannelsSection(
    BuildContext context,
    PlatformChannelsOverview channels,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _metricBox('Total Channels', '${channels.total}', Colors.purple),
            _metricBox('Active', '${channels.active}', Colors.green),
            _metricBox('Pending', '${channels.pending}', Colors.orange),
            _metricBox('Verified', '${channels.verified}', Colors.blue),
            _metricBox(
              'Total Subscribers',
              _formatNumber(channels.totalSubscribers),
              Colors.teal,
            ),
          ],
        ),
        if (channels.items.isNotEmpty) ...[
          const Divider(height: 24),
          const Text(
            'Channels Breakdown (Uploaded Videos & Live Streams)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: channels.items.length,
            separatorBuilder: (context, index) => const Divider(height: 12),
            itemBuilder: (ctx, i) {
              final ch = channels.items[i];
              return Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.purple.withValues(alpha: 0.15),
                    child: Text(
                      ch.name.isNotEmpty ? ch.name[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                ch.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (ch.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: Colors.blue, size: 14),
                            ],
                            if (ch.activeLiveStreamsCount > 0) ...[
                              const SizedBox(width: 6),
                              _badge('${ch.activeLiveStreamsCount} LIVE', Colors.red),
                            ],
                          ],
                        ),
                        Text(
                          '${ch.handle} • ${ch.status} • ${_formatNumber(ch.subscribersCount)} subscribers',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${ch.uploadedVideosCount} videos • ${ch.liveStreamsCount} lives',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${_formatNumber(ch.totalViewsCount)} views',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildVideosSection(PlatformVideosOverview videos) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _metricBox('Total Videos', _formatNumber(videos.total), Colors.teal),
        _metricBox('Ready', _formatNumber(videos.ready), Colors.green),
        _metricBox('Processing', _formatNumber(videos.processing), Colors.orange),
        _metricBox('Failed', _formatNumber(videos.failed), Colors.red),
        _metricBox('Public', _formatNumber(videos.publicCount), Colors.blue),
        _metricBox('Total Views', _formatNumber(videos.totalViews), Colors.indigo),
        _metricBox('Total Likes', _formatNumber(videos.totalLikes), Colors.pink),
        _metricBox('Comments', _formatNumber(videos.totalComments), Colors.amber.shade800),
        _metricBox('Downloads', _formatNumber(videos.totalDownloads), Colors.cyan.shade700),
        _metricBox(
          'Completed DLs',
          _formatNumber(videos.completedDownloadRecords),
          Colors.blueGrey,
        ),
        _metricBox('Shares', _formatNumber(videos.totalShares), Colors.deepPurple),
        _metricBox('Bookmarks', _formatNumber(videos.totalBookmarks), Colors.brown),
        _metricBox(
          'Total Duration',
          _formatDuration(videos.totalDurationSeconds),
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildTopVideosSection(
    BuildContext context,
    PlatformTopVideosOverview top,
  ) {
    final List<PlatformTopVideoItem> list;
    switch (_topVideoFilterIndex) {
      case 1:
        list = top.byComments;
        break;
      case 2:
        list = top.byViews;
        break;
      case 3:
        list = top.byDownloads;
        break;
      case 0:
      default:
        list = top.byLikes;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('Most Liked', Icons.thumb_up_rounded, 0),
              const SizedBox(width: 8),
              _filterChip('Most Commented', Icons.comment_rounded, 1),
              const SizedBox(width: 8),
              _filterChip('Most Viewed', Icons.visibility_rounded, 2),
              const SizedBox(width: 8),
              _filterChip('Most Downloaded', Icons.download_rounded, 3),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text('No videos recorded yet.', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (context, index) => const Divider(height: 12),
            itemBuilder: (ctx, i) {
              final v = list[i];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? Colors.amber
                          : (i == 1
                              ? Colors.grey.shade400
                              : (i == 2
                                  ? Colors.brown.shade300
                                  : Colors.blue.withValues(alpha: 0.12))),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: i < 3 ? Colors.white : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${v.channelName ?? "Unknown Channel"} (${v.channelHandle ?? ""}) • ${v.visibility}${v.duration != null ? " • ${_formatDuration(v.duration!.round())}" : ""}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _miniStat(Icons.thumb_up_outlined, _formatNumber(v.likesCount),
                                _topVideoFilterIndex == 0 ? Colors.pink : Colors.grey),
                            _miniStat(Icons.comment_outlined, _formatNumber(v.commentsCount),
                                _topVideoFilterIndex == 1 ? Colors.amber.shade800 : Colors.grey),
                            _miniStat(Icons.visibility_outlined, _formatNumber(v.viewsCount),
                                _topVideoFilterIndex == 2 ? Colors.blue : Colors.grey),
                            _miniStat(Icons.download_outlined, _formatNumber(v.downloadsCount),
                                _topVideoFilterIndex == 3 ? Colors.teal : Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _filterChip(String label, IconData icon, int idx) {
    final selected = _topVideoFilterIndex == idx;
    return ChoiceChip(
      avatar: Icon(icon, size: 15, color: selected ? Colors.white : Colors.grey),
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _topVideoFilterIndex = idx),
    );
  }

  Widget _buildLiveStreamsSection(
    BuildContext context,
    PlatformLiveStreamsOverview live,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _metricBox('Total Streams', '${live.total}', Colors.red),
            _metricBox('Live Now', '${live.liveNow}', Colors.redAccent),
            _metricBox('Ended', '${live.ended}', Colors.blueGrey),
            _metricBox('Scheduled', '${live.scheduled}', Colors.orange),
            _metricBox('Current Viewers', _formatNumber(live.currentViewers), Colors.green),
            _metricBox('Peak Viewers Max', _formatNumber(live.peakViewersMax), Colors.purple),
            _metricBox('Total Joins', _formatNumber(live.totalViewerJoins), Colors.blue),
            _metricBox('Unique Viewers', _formatNumber(live.uniqueViewerRecords), Colors.teal),
            _metricBox('Chat Messages', _formatNumber(live.totalChatMessages), Colors.indigo),
            _metricBox('Reactions', _formatNumber(live.totalReactions), Colors.amber.shade800),
            _metricBox('Stream Likes', _formatNumber(live.totalLikes), Colors.pink),
          ],
        ),
        if (live.recentAndActive.isNotEmpty) ...[
          const Divider(height: 24),
          const Text(
            'Active & Recent Live Streams',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: live.recentAndActive.length,
            separatorBuilder: (context, index) => const Divider(height: 12),
            itemBuilder: (ctx, i) {
              final s = live.recentAndActive[i];
              final isLive = s.status == 'LIVE';
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isLive ? Colors.red : Colors.grey).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.sensors_rounded,
                      color: isLive ? Colors.red : Colors.grey,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                s.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _badge(
                              s.status,
                              isLive ? Colors.red : (s.status == 'ENDED' ? Colors.blueGrey : Colors.orange),
                            ),
                          ],
                        ),
                        Text(
                          '${s.channelName ?? "Channel"} • ${s.totalChatMessages} chats • ${s.likesCount} likes',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isLive
                            ? '${s.currentViewerCount} watching'
                            : '${s.totalViewerCount} total views',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isLive ? Colors.red : null,
                        ),
                      ),
                      Text(
                        'Peak: ${s.peakViewerCount}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPlatformTotalsSection(PlatformTotalsOverview totals) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _metricBox('Posts', _formatNumber(totals.totalPosts), Colors.blue),
        _metricBox('Stories', _formatNumber(totals.totalStories), Colors.purple),
        _metricBox('Digital Books', _formatNumber(totals.totalBooks), Colors.amber.shade800),
        _metricBox('Stored Files', _formatNumber(totals.totalFiles), Colors.teal),
        _metricBox('Total Storage', _formatBytes(totals.totalStorageBytes), Colors.indigo),
        _metricBox('Moderation Reports', _formatNumber(totals.totalAbuseReports), Colors.orange),
        _metricBox('Pending Reports', _formatNumber(totals.pendingAbuseReports), Colors.red),
      ],
    );
  }

  // ── UI Helpers ──

  Widget _buildSectionCard(
    BuildContext context, {
    required bool isDark,
    required String title,
    required IconData icon,
    required Color color,
    Widget? trailing,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const Divider(height: 22),
            child,
          ],
        ),
      ),
    );
  }

  Widget _metricBox(String label, String value, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return Colors.red;
      case 'ADMIN':
        return Colors.deepPurple;
      case 'MODERATOR':
        return Colors.orange;
      case 'SUPPORT':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0m';
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${mins}m';
    final secs = totalSeconds % 60;
    return mins > 0 ? '${mins}m ${secs}s' : '${secs}s';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int idx = 0;
    while (size >= 1024 && idx < units.length - 1) {
      size /= 1024;
      idx++;
    }
    return '${size.toStringAsFixed(size >= 10 ? 1 : 2)} ${units[idx]}';
  }

  String _formatDateTime(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}

class _KpiItem {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiItem({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
