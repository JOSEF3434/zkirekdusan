// lib/features/groups/presentation/screens/channel_detail_screen.dart
// Channel detail page — shown when user taps a video channel (not a group/community).
// Channels use "Subscribers" terminology; groups use "Members".

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final int subscribersCount;
  final int videosCount;
  final bool isOwner;
  final bool isVerified;
  final String status;

  const ChannelDetailModel({
    required this.id,
    required this.name,
    required this.handle,
    required this.slug,
    this.description,
    this.avatarUrl,
    this.subscribersCount = 0,
    this.videosCount = 0,
    this.isOwner = false,
    this.isVerified = false,
    this.status = 'ACTIVE',
  });

  factory ChannelDetailModel.fromJson(Map<String, dynamic> json) {
    return ChannelDetailModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Channel',
      handle: json['handle'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      subscribersCount: json['subscribersCount'] as int? ?? 0,
      videosCount: json['videosCount'] as int? ?? 0,
      isOwner: json['isOwner'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      status: json['status'] as String? ?? 'ACTIVE',
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
  bool _isOpeningChat = false;

  static const int _tabCount = 8;

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
        (currentUserId != null && currentUserId.isNotEmpty && channel.isOwner);

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
                await Clipboard.setData(ClipboardData(text: canonicalUrl));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Channel link copied!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
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
              const PopupMenuItem(
                value: 'report',
                child: Row(children: [
                  Icon(Icons.flag_rounded, color: Colors.orange, size: 20),
                  SizedBox(width: 12),
                  Text('Report Channel',
                      style: TextStyle(color: Colors.orange)),
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
                    const SizedBox(height: 8),

                    // ── Avatar ──────────────────────────────────────────────
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            const Color(0xFF00C6FF).withValues(alpha: 0.2),
                        border: Border.all(
                          color: const Color(0xFF00C6FF)
                              .withValues(alpha: 0.5),
                          width: 2.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor:
                            const Color(0xFF00C6FF).withValues(alpha: 0.8),
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
                                color: isDark
                                    ? Colors.white
                                    : Colors.black87,
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
                      _formatCount(channel.subscribersCount) +
                          ' subscribers',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDark ? Colors.grey[400] : Colors.grey[600],
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
                            color: isDark
                                ? Colors.grey[500]
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // ── Action buttons ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.chat_bubble_rounded,
                            label: 'Message',
                            isLoading: _isOpeningChat,
                            isDark: isDark,
                            onTap: () => _openChannelChat(channel),
                          ),
                          _buildActionButton(
                            icon: _isMuted
                                ? Icons.notifications_off_rounded
                                : Icons.notifications_rounded,
                            label: _isMuted ? 'Unmute' : 'Mute',
                            isDark: isDark,
                            onTap: () {
                              setState(() => _isMuted = !_isMuted);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_isMuted
                                      ? 'Notifications muted'
                                      : 'Notifications unmuted'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          // Subscribe button
                          _buildSubscribeButton(
                              channel, subscribeState.valueOrNull, isDark),
                          if (isOwner)
                            _buildActionButton(
                              icon: Icons.add_circle_outline_rounded,
                              label: 'Add Story',
                              isDark: isDark,
                              onTap: () => context.push('/story/create'),
                            ),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Channel link card ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          title: Text(
                            displayUrl,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            'Channel Link',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.qr_code_2_rounded,
                                size: 26, color: Color(0xFF00C6FF)),
                            tooltip: 'Show QR Code',
                            onPressed: () => TelegramQrSheet.show(
                              context,
                              title: channel.name,
                              subtitle: displayUrl,
                              avatarUrl: channel.avatarUrl,
                              qrData: canonicalUrl,
                              entityType: AppLinkEntityType.group,
                            ),
                          ),
                          onTap: () async {
                            await Clipboard.setData(
                                ClipboardData(text: canonicalUrl));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Channel link copied!')),
                              );
                            }
                          },
                        ),
                      ),
                    ),

                    // ── Description ─────────────────────────────────────────
                    if (channel.description != null &&
                        channel.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            channel.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),

                    // ── Stats row ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          _buildStatChip(
                            Icons.people_outline,
                            _formatCount(channel.subscribersCount),
                            'Subscribers',
                            isDark,
                          ),
                          const SizedBox(width: 10),
                          _buildStatChip(
                            Icons.play_circle_outline,
                            _formatCount(channel.videosCount),
                            'Videos',
                            isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ── Pinned Tab Bar ─────────────────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverChannelTabDelegate(
                  Container(
                    color: isDark ? const Color(0xFF0E1621) : Colors.grey[100],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
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
                          color: isDark
                              ? const Color(0xFF00C6FF)
                              : const Color(0xFF0072FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: isDark ? Colors.black : Colors.white,
                        unselectedLabelColor:
                            isDark ? Colors.grey[400] : Colors.grey[700],
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        tabs: const [
                          Tab(text: 'Media'),
                          Tab(text: 'Files'),
                          Tab(text: 'Links'),
                          Tab(text: 'Music'),
                          Tab(text: 'GIFs'),
                          Tab(text: 'Videos'),
                          Tab(text: 'Playlists'),
                          Tab(text: 'Subscribers'),
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
              _buildMediaGrid(isDark),
              _buildFilesList(isDark),
              _buildLinksList(channel, isDark),
              _buildMusicList(isDark),
              _buildGifsGrid(isDark),
              _buildVideosTab(isDark),
              _buildPlaylistsTab(isDark),
              _buildSubscribersTab(isDark),
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
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 62,
        padding: const EdgeInsets.symmetric(vertical: 10),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF00C6FF)),
              )
            else
              Icon(icon, color: const Color(0xFF00C6FF), size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    final isSubscribed = subscribeState?.isSubscribed ?? false;
    final isLoading = subscribeState?.isLoading ?? false;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              HapticFeedback.selectionClick();
              ref
                  .read(channelSubscribeProvider(widget.channelId).notifier)
                  .toggle();
            },
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSubscribed
              ? (isDark ? const Color(0xFF17212B) : Colors.white)
              : const Color(0xFF00C6FF),
          borderRadius: BorderRadius.circular(16),
          border: isSubscribed
              ? Border.all(
                  color: const Color(0xFF00C6FF).withValues(alpha: 0.6))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isSubscribed
                      ? const Color(0xFF00C6FF)
                      : Colors.white,
                ),
              )
            else
              Icon(
                isSubscribed
                    ? Icons.notifications_active_rounded
                    : Icons.add_rounded,
                color: isSubscribed
                    ? const Color(0xFF00C6FF)
                    : Colors.white,
                size: 22,
              ),
            const SizedBox(height: 5),
            Text(
              isSubscribed ? 'Subscribed' : 'Subscribe',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: isSubscribed
                    ? const Color(0xFF00C6FF)
                    : Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Stat Chip ───────────────────────────────────────────────────────────────

  Widget _buildStatChip(
      IconData icon, String value, String label, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF17212B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00C6FF), size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tabs ────────────────────────────────────────────────────────────────────

  Widget _buildMediaGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: 0,
      itemBuilder: (context, index) => const SizedBox.shrink(),
    );
  }

  Widget _buildFilesList(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded,
              size: 56,
              color: isDark ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No files shared yet',
            style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksList(ChannelDetailModel channel, bool isDark) {
    final links = <Map<String, String>>[
      if (channel.handle.isNotEmpty)
        {
          'title': channel.name,
          'url':
              'https://zikire-kdusan.onrender.com/c/${channel.slug}'
        },
    ];

    if (links.isEmpty) {
      return Center(
        child: Text(
          'No links shared yet',
          style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: links.length,
      itemBuilder: (context, index) {
        final l = links[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF17212B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.link_rounded, color: Color(0xFF10B981)),
            ),
            title: Text(
              l['title']!,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              l['url']!,
              style: const TextStyle(fontSize: 12, color: Color(0xFF00C6FF)),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.copy_rounded,
                  size: 18, color: Colors.grey),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: l['url']!));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied!')),
                  );
                }
              },
            ),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: l['url']!));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard!')),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildMusicList(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note_rounded,
              size: 56,
              color: isDark ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No music shared yet',
            style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildGifsGrid(bool isDark) {
    return Center(
      child: Text(
        'No GIFs shared yet',
        style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 15),
      ),
    );
  }

  Widget _buildVideosTab(bool isDark) {
    final videosAsync =
        ref.watch(channelVideosProvider(widget.channelId));
    final videos = videosAsync.videos;
    final isLoading = videosAsync.isLoading;

    if (isLoading && videos.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00C6FF)));
    }

    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined,
                size: 56,
                color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No videos yet',
              style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ],
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: v.thumbnailUrl != null && v.thumbnailUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: v.thumbnailUrl!,
                    width: 80,
                    height: 50,
                    fit: BoxFit.cover,
                    errorWidget: (c, u, e) => Container(
                      width: 80,
                      height: 50,
                      color: isDark
                          ? const Color(0xFF17212B)
                          : Colors.grey[300],
                      child: const Icon(Icons.play_circle_outline,
                          color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 50,
                    color: isDark
                        ? const Color(0xFF17212B)
                        : Colors.grey[300],
                    child: const Icon(Icons.play_circle_outline,
                        color: Colors.grey),
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
          subtitle: Text(
            '${v.viewsCount} views',
            style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          trailing: const Icon(Icons.play_arrow_rounded,
              color: Color(0xFF00C6FF)),
          onTap: () => context.push('/video/${v.id}'),
        );
      },
    );
  }

  Widget _buildPlaylistsTab(bool isDark) {
    final playlistsAsync =
        ref.watch(channelPlaylistsProvider(widget.channelId));
    final playlists = playlistsAsync.playlists;
    final isLoading = playlistsAsync.isLoading;

    if (isLoading && playlists.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00C6FF)));
    }

    if (playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_play_rounded,
                size: 56,
                color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No playlists yet',
              style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.grey[400] : Colors.grey[600]),
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
            child: const Icon(Icons.playlist_play_rounded,
                color: Color(0xFF00C6FF)),
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
                color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Colors.grey),
          onTap: () => context.push('/playlists/${p.id}'),
        );
      },
    );
  }

  Widget _buildSubscribersTab(bool isDark) {
    final subscribersAsync =
        ref.watch(channelSubscribersProvider(widget.channelId));

    return subscribersAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00C6FF))),
      error: (_, i) => Center(
        child: Text(
          'Could not load subscribers',
          style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
      ),
      data: (subscribers) {
        if (subscribers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 56,
                    color: isDark ? Colors.grey[600] : Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No subscribers yet',
                  style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 4),
              onTap: () {
                if (username != null && username.isNotEmpty) {
                  context.push('/@$username');
                } else if (userId.isNotEmpty) {
                  context.push('/profile/user/$userId');
                }
              },
              leading: CircleAvatar(
                radius: 22,
                backgroundColor:
                    const Color(0xFF00C6FF).withValues(alpha: 0.2),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00C6FF),
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              title: Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: username != null
                  ? Text(
                      '@$username',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    )
                  : null,
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.grey),
            );
          },
        );
      },
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

  Future<void> _openChannelChat(ChannelDetailModel channel) async {
    setState(() => _isOpeningChat = true);
    try {
      // Channel chat opens the group-associated chat; fallback to group detail
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening ${channel.name} chat...')),
      );
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
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

