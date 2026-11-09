// lib/features/groups/presentation/screens/channel_detail_screen.dart
// Channel detail page — YouTube-style content broadcasting platform.
// Channels use independent "Subscribers" rather than group members.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';
import 'package:mobile/core/utils/app_link_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/chats/presentation/widgets/telegram_qr_sheet.dart';
import 'package:mobile/features/groups/presentation/providers/channel_subscribe_provider.dart';
import 'package:mobile/features/groups/presentation/providers/channel_videos_provider.dart';
import 'package:mobile/features/groups/presentation/providers/channel_playlists_provider.dart';
import 'package:mobile/features/social/data/report_repository.dart';
import 'package:mobile/features/social/presentation/widgets/report_sheet.dart';

// ── Channel Detail Model ──────────────────────────────────────────────────────

class ChannelDetailModel {
  final String id;
  final String name;
  final String handle;
  final String slug;
  final String? description;
  final String? avatarUrl;
  final String? bannerUrl;
  final int subscribersCount;
  final int videosCount;
  final int totalViewsCount;
  final bool isOwner;
  final bool isSubscribed;
  final bool isVerified;
  final String status;
  final String? rejectionReason;
  final String? ownerId;
  final String visibility;
  final String? website;
  final DateTime createdAt;

  const ChannelDetailModel({
    required this.id,
    required this.name,
    required this.handle,
    required this.slug,
    this.description,
    this.avatarUrl,
    this.bannerUrl,
    this.subscribersCount = 0,
    this.videosCount = 0,
    this.totalViewsCount = 0,
    this.isOwner = false,
    this.isSubscribed = false,
    this.isVerified = false,
    this.status = 'ACTIVE',
    this.rejectionReason,
    this.ownerId,
    this.visibility = 'PUBLIC',
    this.website,
    required this.createdAt,
  });

  factory ChannelDetailModel.fromJson(Map<String, dynamic> json) {
    return ChannelDetailModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Channel',
      handle: json['handle'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      subscribersCount: (json['subscribersCount'] as num?)?.toInt() ?? 0,
      videosCount: (json['videosCount'] as num?)?.toInt() ?? 0,
      totalViewsCount: (json['totalViewsCount'] as num?)?.toInt() ?? 0,
      isOwner: json['isOwner'] as bool? ?? false,
      isSubscribed: json['isSubscribed'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      status: json['status'] as String? ?? 'ACTIVE',
      rejectionReason: json['rejectionReason'] as String?,
      ownerId: json['ownerId'] as String?,
      visibility: json['visibility'] as String? ?? 'PUBLIC',
      website: json['website'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final channelDetailProvider =
    FutureProvider.family<ChannelDetailModel, String>((ref, channelId) async {
  final dio = ref.read(apiClientProvider);
  final response = await dio.get('/video-channels/$channelId');
  final raw = response.data;
  Map<String, dynamic> data = {};
  if (raw is Map<String, dynamic> && raw.containsKey('data')) {
    data = (raw['data'] as Map<String, dynamic>?) ?? {};
  } else if (raw is Map<String, dynamic>) {
    data = raw;
  }
  return ChannelDetailModel.fromJson(data);
});

final channelSubscribersProvider = FutureProvider.family<
    List<Map<String, dynamic>>, String>((ref, channelId) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get(
      '/video-channels/$channelId/subscribers',
      queryParameters: {'limit': 50, 'page': 1},
    );
    final raw = response.data;
    List<dynamic> list = [];
    if (raw is Map<String, dynamic>) {
      final d = raw['data'];
      if (d is List) {
        list = d;
      } else if (d is Map<String, dynamic>) {
        final inner = d['data'];
        if (inner is List) list = inner;
      }
    } else if (raw is List) {
      list = raw;
    }
    return list.whereType<Map<String, dynamic>>().toList();
  } catch (_) {
    return [];
  }
});

final channelLiveStreamsProvider = FutureProvider.family<
    List<Map<String, dynamic>>, String>((ref, channelId) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/live-streaming/channel/$channelId');
    final raw = response.data;
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    if (raw is Map && raw['data'] is List) {
      return (raw['data'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return [];
  } catch (_) {
    return [];
  }
});

final channelCommunityPostsProvider = FutureProvider.family<
    List<Map<String, dynamic>>, String>((ref, channelId) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/video-channels/$channelId/posts');
    final raw = response.data;
    if (raw is Map && raw['items'] is List) {
      return (raw['items'] as List).whereType<Map<String, dynamic>>().toList();
    }
    if (raw is Map && raw['data'] is List) {
      return (raw['data'] as List).whereType<Map<String, dynamic>>().toList();
    }
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  } catch (_) {
    return [];
  }
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ChannelDetailScreen extends ConsumerStatefulWidget {
  final String channelId;

  const ChannelDetailScreen({super.key, required this.channelId});

  @override
  ConsumerState<ChannelDetailScreen> createState() =>
      _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends ConsumerState<ChannelDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMuted = false;

  static const int _tabCount = 6;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channelAsync = ref.watch(channelDetailProvider(widget.channelId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return channelAsync.when(
      loading: () => Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0E1621) : Colors.grey[100],
        appBar: AppBar(
          backgroundColor:
              isDark ? const Color(0xFF0E1621) : Colors.grey[100],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00C6FF)),
        ),
      ),
      error: (err, _) => _buildErrorScaffold(context, err, isDark),
      data: (channel) => _buildChannelProfile(context, channel, isDark),
    );
  }

  Widget _buildChannelProfile(
    BuildContext context,
    ChannelDetailModel channel,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF17212B) : Colors.white;
    final auth = ref.watch(authProvider);
    final currentUserId = auth.user?.id;
    final isOwner = channel.isOwner ||
        (currentUserId != null && currentUserId == channel.ownerId);

    final subscribeState =
        ref.watch(channelSubscribeProvider(widget.channelId));

    final canonicalUrl = 'https://zikire-kdusan.onrender.com/c/${channel.slug}';
    final displayUrl = 'zikire-kdusan.onrender.com/c/${channel.slug}';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1621) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0E1621) : Colors.grey[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          channel.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: cardBg,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            onSelected: (value) async {
              if (value == 'share') {
                TelegramQrSheet.show(
                  context,
                  title: channel.name,
                  subtitle: displayUrl,
                  avatarUrl: channel.avatarUrl,
                  qrData: canonicalUrl,
                  entityType: AppLinkEntityType.group,
                );
              } else if (value == 'copy') {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: canonicalUrl));
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Channel link copied!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              } else if (value == 'analytics' && isOwner) {
                context.push('/creator/dashboard/channel/${channel.id}/analytics', extra: {
                  'channelName': channel.name,
                });
              } else if (value == 'report') {
                ReportSheet.show(
                  context,
                  targetType: ReportTargetType.group,
                  targetId: channel.id,
                  targetName: channel.name,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(children: [
                  Icon(Icons.qr_code_2_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('Share Channel'),
                ]),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(children: [
                  Icon(Icons.copy_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('Copy Link'),
                ]),
              ),
              if (isOwner)
                const PopupMenuItem(
                  value: 'analytics',
                  child: Row(children: [
                    Icon(Icons.analytics_rounded, size: 20, color: Color(0xFF00C6FF)),
                    SizedBox(width: 12),
                    Text('Channel Analytics'),
                  ]),
                ),
              const PopupMenuItem(
                value: 'report',
                child: Row(children: [
                  Icon(Icons.flag_outlined, size: 20, color: Colors.redAccent),
                  SizedBox(width: 12),
                  Text('Report Channel'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: ResponsiveLayout.maxReadingWidth(
        maxWidth: 1000,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Banner Image if available
                    if (channel.bannerUrl != null && channel.bannerUrl!.isNotEmpty)
                      Container(
                        height: 140,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(channel.bannerUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    // Approval Status Banners
                    if (channel.status == 'PENDING')
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pending Administrator Approval',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'This channel is awaiting administrator review. It is not publicly discoverable until approved.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.amber[200] : Colors.amber[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (channel.status == 'REJECTED')
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Channel Application Rejected',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    channel.rejectionReason != null && channel.rejectionReason!.isNotEmpty
                                        ? 'Reason: ${channel.rejectionReason}'
                                        : 'This channel application was rejected by an administrator.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.red[200] : Colors.red[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (channel.status == 'SUSPENDED')
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pause_circle_outline_rounded, color: Colors.orange, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Channel Suspended',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'This channel has been suspended by an administrator. Broadcasting and uploads are paused.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.orange[200] : Colors.orange[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // ── Avatar ──────────────────────────────────────────────
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF0055).withValues(alpha: 0.15),
                        border: Border.all(
                          color: const Color(0xFFFF0055).withValues(alpha: 0.6),
                          width: 2.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFFFF0055).withValues(alpha: 0.8),
                        backgroundImage: channel.avatarUrl != null &&
                                channel.avatarUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(channel.avatarUrl!)
                            : null,
                        child: channel.avatarUrl == null ||
                                channel.avatarUrl!.isEmpty
                            ? Text(
                                channel.name.isNotEmpty
                                    ? channel.name
                                        .substring(
                                          0,
                                          channel.name.length > 2 ? 2 : 1,
                                        )
                                        .toUpperCase()
                                    : 'CH',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Channel name + verified ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              channel.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (channel.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified,
                                color: Color(0xFF00C6FF), size: 20),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // ── Subscriber count + handle ───────────────────────────
                    Text(
                      '${_formatCount(channel.subscribersCount)} subscribers • ${_formatCount(channel.videosCount)} videos',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (channel.handle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          channel.handle.startsWith('@')
                              ? channel.handle
                              : '@${channel.handle}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),

                    // ── Action buttons (YouTube Broadcasting Style) ─────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Primary Subscribe Toggle
                          _buildSubscribeButton(
                            channel,
                            subscribeState.valueOrNull,
                            isDark,
                          ),
                          const SizedBox(width: 12),

                          // Share
                          _buildActionButton(
                            icon: Icons.share_rounded,
                            label: 'Share',
                            isDark: isDark,
                            onTap: () {
                              TelegramQrSheet.show(
                                context,
                                title: channel.name,
                                subtitle: displayUrl,
                                avatarUrl: channel.avatarUrl,
                                qrData: canonicalUrl,
                                entityType: AppLinkEntityType.group,
                              );
                            },
                          ),
                          const SizedBox(width: 12),

                          // Mute / Unmute
                          _buildActionButton(
                            icon: _isMuted
                                ? Icons.notifications_off_rounded
                                : Icons.notifications_rounded,
                            label: _isMuted ? 'Muted' : 'Notify',
                            isDark: isDark,
                            onTap: () {
                              setState(() => _isMuted = !_isMuted);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_isMuted
                                      ? 'Channel notifications muted'
                                      : 'Channel notifications enabled'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),

                          // Owner quick tools
                          if (isOwner) ...[
                            const SizedBox(width: 12),
                            _buildActionButton(
                              icon: Icons.video_call_rounded,
                              label: 'Go Live',
                              isDark: isDark,
                              color: Colors.redAccent,
                              onTap: () => context.push('/live/studio?channelId=${channel.id}'),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Owner Management Control Bar
                    if (isOwner)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF00C6FF).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton.icon(
                              onPressed: () => context.push(
                                '/creator/dashboard/channel/${channel.id}/videos',
                              ),
                              icon: const Icon(Icons.upload_file_rounded, size: 18),
                              label: const Text('Manage Videos'),
                            ),
                            TextButton.icon(
                              onPressed: () => _createCommunityPost(context, channel.id),
                              icon: const Icon(Icons.post_add_rounded, size: 18),
                              label: const Text('New Post'),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // ── Pinned YouTube-Style Tab Bar ───────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverChannelTabDelegate(
                  Container(
                    color: isDark ? const Color(0xFF0E1621) : Colors.grey[100],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF17212B)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        physics: const BouncingScrollPhysics(),
                        indicator: BoxDecoration(
                          color: const Color(0xFF00C6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.black,
                        unselectedLabelColor:
                            isDark ? Colors.grey[400] : Colors.grey[700],
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        tabs: const [
                          Tab(text: 'Videos'),
                          Tab(text: 'Live'),
                          Tab(text: 'Playlists'),
                          Tab(text: 'Community'),
                          Tab(text: 'Subscribers'),
                          Tab(text: 'About'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildVideosTab(isDark, isOwner),
              _buildLiveTab(isDark, isOwner),
              _buildPlaylistsTab(isDark),
              _buildCommunityTab(channel, isDark, isOwner),
              _buildSubscribersTab(isDark),
              _buildAboutTab(channel, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ── Action button widget ────────────────────────────────────────────────────

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
    Color? color,
    bool isLoading = false,
  }) {
    final effectiveColor = color ?? const Color(0xFF00C6FF);
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF17212B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: effectiveColor,
                ),
              )
            else
              Icon(icon, color: effectiveColor, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeButton(
    ChannelDetailModel channel,
    ChannelSubscribeState? subscribeState,
    bool isDark,
  ) {
    final isSubscribed = subscribeState?.isSubscribed ?? channel.isSubscribed;
    final isLoading = subscribeState?.isLoading ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isLoading
          ? null
          : () async {
              HapticFeedback.selectionClick();
              await ref
                  .read(channelSubscribeProvider(widget.channelId).notifier)
                  .toggle(isSubscribed);
              ref.invalidate(channelDetailProvider(widget.channelId));
              ref.invalidate(channelSubscribersProvider(widget.channelId));
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: isSubscribed
              ? (isDark ? const Color(0xFF17212B) : Colors.white)
              : const Color(0xFFFF0055),
          borderRadius: BorderRadius.circular(16),
          border: isSubscribed
              ? Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isSubscribed ? Colors.grey : Colors.white,
                ),
              )
            else
              Icon(
                isSubscribed
                    ? Icons.notifications_active_rounded
                    : Icons.subscriptions_rounded,
                color: isSubscribed
                    ? (isDark ? Colors.white70 : Colors.black87)
                    : Colors.white,
                size: 20,
              ),
            const SizedBox(width: 8),
            Text(
              isSubscribed ? 'Subscribed' : 'Subscribe',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSubscribed
                    ? (isDark ? Colors.white : Colors.black87)
                    : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tabs ────────────────────────────────────────────────────────────────────

  Widget _buildVideosTab(bool isDark, bool isOwner) {
    final videosAsync = ref.watch(channelVideosProvider(widget.channelId));
    final videos = videosAsync.videos;
    final isLoading = videosAsync.isLoading;

    if (isLoading && videos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C6FF)),
      );
    }

    if (videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined,
                  size: 56, color: isDark ? Colors.grey[600] : Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No videos published yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                'This channel hasn\'t uploaded any videos yet.',
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              if (isOwner) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push(
                    '/creator/dashboard/channel/${widget.channelId}/videos',
                  ),
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Upload First Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C6FF),
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: videos.length,
      separatorBuilder: (_, i) => Divider(
        height: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
      ),
      itemBuilder: (context, index) {
        final v = videos[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: v.thumbnailUrl != null && v.thumbnailUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: v.thumbnailUrl!,
                    width: 90,
                    height: 56,
                    fit: BoxFit.cover,
                    errorWidget: (c, u, e) => Container(
                      width: 90,
                      height: 56,
                      color: isDark ? const Color(0xFF17212B) : Colors.grey[300],
                      child: const Icon(Icons.play_circle_outline, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 90,
                    height: 56,
                    color: isDark ? const Color(0xFF17212B) : Colors.grey[300],
                    child: const Icon(Icons.play_circle_outline, color: Colors.grey),
                  ),
          ),
          title: Text(
            v.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${v.viewsCount} views',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          trailing: const Icon(Icons.play_arrow_rounded, color: Color(0xFF00C6FF)),
          onTap: () => context.push('/video/${v.id}'),
        );
      },
    );
  }

  Widget _buildLiveTab(bool isDark, bool isOwner) {
    final liveAsync = ref.watch(channelLiveStreamsProvider(widget.channelId));

    return liveAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C6FF)),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Could not load live streams',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
      ),
      data: (streams) {
        if (streams.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.live_tv_rounded,
                      size: 56, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No live broadcasts right now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'When this channel goes live or schedules a stream, it will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  if (isOwner) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/live/studio?channelId=${widget.channelId}'),
                      icon: const Icon(Icons.video_call_rounded, size: 18),
                      label: const Text('Start Live Broadcast'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: streams.length,
          itemBuilder: (context, index) {
            final s = streams[index];
            final title = s['title'] as String? ?? 'Live Stream';
            final status = s['status'] as String? ?? 'ENDED';
            final isLive = status == 'LIVE';
            final viewers = s['viewersCount'] as int? ?? 0;
            final streamId = s['id'] as String? ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: isDark ? const Color(0xFF17212B) : Colors.white,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isLive ? Colors.redAccent.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.live_tv_rounded,
                    color: isLive ? Colors.redAccent : Colors.grey,
                  ),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Row(
                  children: [
                    if (isLive) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$viewers watching'),
                    ] else
                      Text('Status: $status'),
                  ],
                ),
                trailing: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF00C6FF), size: 30),
                onTap: () {
                  if (streamId.isNotEmpty) {
                    context.push('/live/view/$streamId');
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaylistsTab(bool isDark) {
    final playlistsAsync = ref.watch(channelPlaylistsProvider(widget.channelId));
    final playlists = playlistsAsync.playlists;
    final isLoading = playlistsAsync.isLoading;

    if (isLoading && playlists.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C6FF)),
      );
    }

    if (playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_play_rounded,
                size: 56, color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No playlists created yet',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: playlists.length,
      separatorBuilder: (_, i) => Divider(
        height: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
      ),
      itemBuilder: (context, index) {
        final p = playlists[index];
        return ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF00C6FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.playlist_play_rounded, color: Color(0xFF00C6FF)),
          ),
          title: Text(
            p.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            '${p.videosCount} videos',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Colors.grey),
          onTap: () => context.push('/playlists/${p.id}'),
        );
      },
    );
  }

  Widget _buildCommunityTab(ChannelDetailModel channel, bool isDark, bool isOwner) {
    final postsAsync = ref.watch(channelCommunityPostsProvider(widget.channelId));

    return postsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C6FF)),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Could not load community posts',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined,
                      size: 56, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No community posts yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Channel announcements, updates, and discussions will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  if (isOwner) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _createCommunityPost(context, channel.id),
                      icon: const Icon(Icons.post_add_rounded, size: 18),
                      label: const Text('Publish Announcement'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C6FF),
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final p = posts[index];
            final postId = p['id'] as String? ?? '';
            final content = p['content'] as String? ?? '';
            final likesCount = p['likesCount'] as int? ?? 0;
            final commentsCount = p['commentsCount'] as int? ?? 0;
            final mediaUrls = (p['mediaUrls'] as List?)?.whereType<String>().toList() ?? [];
            final createdAtStr = p['createdAt'] as String?;
            final postDate = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF17212B) : Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post Author Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFFF0055).withValues(alpha: 0.2),
                          backgroundImage: channel.avatarUrl != null && channel.avatarUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(channel.avatarUrl!)
                              : null,
                          child: channel.avatarUrl == null || channel.avatarUrl!.isEmpty
                              ? const Icon(Icons.campaign_rounded, size: 18, color: Color(0xFFFF0055))
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    channel.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  if (channel.isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified, color: Color(0xFF00C6FF), size: 14),
                                  ],
                                ],
                              ),
                              if (postDate != null)
                                Text(
                                  DateFormat('MMM d, y • h:mm a').format(postDate),
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Content
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[200] : Colors.black87,
                        height: 1.4,
                      ),
                    ),

                    // Media previews if attached
                    if (mediaUrls.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: mediaUrls.first,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const SizedBox.shrink(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Actions (Like & Comment)
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _likePost(channel.id, postId),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.favorite_border_rounded, size: 18, color: Colors.redAccent),
                                const SizedBox(width: 4),
                                Text('$likesCount', style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () => _showCommentsSheet(context, channel.id, postId),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.comment_outlined, size: 18, color: Color(0xFF00C6FF)),
                                const SizedBox(width: 4),
                                Text('$commentsCount', style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubscribersTab(bool isDark) {
    final subscribersAsync = ref.watch(channelSubscribersProvider(widget.channelId));

    return subscribersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C6FF)),
      ),
      error: (_, i) => Center(
        child: Text(
          'Could not load subscribers',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
      ),
      data: (subscribers) {
        if (subscribers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 56, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No subscribers yet',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: subscribers.length,
          separatorBuilder: (_, i) => Divider(
            height: 1,
            indent: 56,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
          itemBuilder: (context, index) {
            final sub = subscribers[index];
            final username = sub['username'] as String?;
            final displayName = sub['displayName'] as String?;
            final avatarUrl = sub['avatarUrl'] as String?;
            final userId = sub['id'] as String? ?? '';
            final name = displayName ?? username ?? 'Subscriber';

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              onTap: () {
                if (username != null && username.isNotEmpty) {
                  context.push('/@$username');
                } else if (userId.isNotEmpty) {
                  context.push('/profile/user/$userId');
                }
              },
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF00C6FF).withValues(alpha: 0.2),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00C6FF),
                        ),
                      )
                    : null,
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: username != null && username.isNotEmpty
                  ? Text('@$username', style: TextStyle(fontSize: 12, color: Colors.grey[500]))
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildAboutTab(ChannelDetailModel channel, bool isDark) {
    final cardBg = isDark ? const Color(0xFF17212B) : Colors.white;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Description Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                channel.description != null && channel.description!.isNotEmpty
                    ? channel.description!
                    : 'No description provided.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Channel Statistics Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Channel Statistics',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              _buildAboutItem(
                Icons.people_outline,
                'Subscribers',
                _formatCount(channel.subscribersCount),
                isDark,
              ),
              _buildAboutItem(
                Icons.video_library_outlined,
                'Videos',
                _formatCount(channel.videosCount),
                isDark,
              ),
              _buildAboutItem(
                Icons.visibility_outlined,
                'Total Views',
                _formatCount(channel.totalViewsCount),
                isDark,
              ),
              _buildAboutItem(
                Icons.calendar_today_outlined,
                'Joined',
                DateFormat('MMMM d, y').format(channel.createdAt),
                isDark,
              ),
              _buildAboutItem(
                Icons.alternate_email_rounded,
                'Handle',
                channel.handle,
                isDark,
              ),
              if (channel.website != null && channel.website!.isNotEmpty)
                _buildAboutItem(
                  Icons.language_rounded,
                  'Website',
                  channel.website!,
                  isDark,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutItem(IconData icon, String title, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF00C6FF)),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Community Post Dialogs ──────────────────────────────────────────────────

  Future<void> _createCommunityPost(BuildContext context, String channelId) async {
    final contentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('New Community Post'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: contentController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share an announcement or update with your subscribers...',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Content cannot be empty'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C6FF),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                final dio = ref.read(apiClientProvider);
                await dio.post('/video-channels/$channelId/posts', data: {
                  'content': contentController.text.trim(),
                });
                ref.invalidate(channelCommunityPostsProvider(channelId));
                messenger.showSnackBar(
                  const SnackBar(content: Text('Community post published!')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to publish post: $e')),
                );
              }
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  Future<void> _likePost(String channelId, String postId) async {
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post('/video-channels/$channelId/posts/$postId/like');
      ref.invalidate(channelCommunityPostsProvider(channelId));
    } catch (_) {}
  }

  Future<void> _showCommentsSheet(BuildContext context, String channelId, String postId) async {
    final commentController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF17212B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder(
                    future: ref.read(apiClientProvider).get('/video-channels/$channelId/posts/$postId/comments'),
                    builder: (ctx, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF00C6FF)));
                      }
                      if (!snapshot.hasData || snapshot.hasError) {
                        return const Center(child: Text('No comments yet'));
                      }
                      final raw = snapshot.data?.data;
                      List<dynamic> items = [];
                      if (raw is Map && raw['items'] is List) items = raw['items'];
                      if (raw is List) items = raw;
                      if (items.isEmpty) {
                        return const Center(child: Text('Be the first to comment'));
                      }
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final c = items[i];
                          final author = c['author'];
                          final authorName = author?['username'] ?? 'User';
                          final text = c['content'] ?? '';
                          return ListTile(
                            title: Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(text),
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0E1621) : Colors.grey[100],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: Color(0xFF00C6FF)),
                        onPressed: () async {
                          final txt = commentController.text.trim();
                          if (txt.isEmpty) return;
                          commentController.clear();
                          try {
                            final dio = ref.read(apiClientProvider);
                            await dio.post('/video-channels/$channelId/posts/$postId/comments', data: {
                              'content': txt,
                            });
                            ref.invalidate(channelCommunityPostsProvider(channelId));
                            setSheetState(() {});
                          } catch (_) {}
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  Widget _buildErrorScaffold(BuildContext context, Object err, bool isDark) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Unable to load channel',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString().replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    ref.invalidate(channelDetailProvider(widget.channelId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sliver delegate ───────────────────────────────────────────────────────────

class _SliverChannelTabDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverChannelTabDelegate(this.child);

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverChannelTabDelegate oldDelegate) => true;
}
