// lib/features/profile/presentation/public_profile_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/chats/presentation/providers/conversations_provider.dart';
import 'package:mobile/features/chats/presentation/widgets/telegram_call_dialog.dart';
import 'package:mobile/features/chats/presentation/widgets/telegram_qr_sheet.dart';
import 'package:mobile/features/social/data/report_repository.dart';
import 'package:mobile/features/social/presentation/widgets/report_sheet.dart';
import 'package:mobile/features/profile/data/models/profile_model.dart';
import 'package:mobile/features/profile/presentation/providers/profile_posts_provider.dart';
import 'package:mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:mobile/features/stories/data/models/story_feed_group_model.dart';
import 'package:mobile/features/stories/data/models/story_model.dart';
import 'package:mobile/features/stories/presentation/providers/story_feed_provider.dart';
import 'package:mobile/features/stories/presentation/screens/story_viewer_screen.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String username;

  const PublicProfileScreen({super.key, required this.username});

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMuted = false;
  bool _isOpeningChat = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(publicProfileProvider(widget.username));
    final feedAsync = ref.watch(storyFeedProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            color: isDark ? const Color(0xFF17212B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (val) {
              if (val == 'share') {
                final profile = profileState.value;
                if (profile != null) {
                  final canonicalUrl = 'https://app.zikrekidusan.com/u/${profile.username ?? widget.username}';
                  TelegramQrSheet.show(
                    context,
                    title: profile.displayName ?? profile.username ?? 'User',
                    subtitle: '@${profile.username ?? ""}',
                    avatarUrl: profile.avatarUrl,
                    qrData: canonicalUrl,
                  );
                }
              } else if (val == 'copy') {
                final canonicalUrl = 'https://app.zikrekidusan.com/u/${widget.username}';
                Clipboard.setData(ClipboardData(text: canonicalUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile link copied!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              } else if (val == 'report') {
                final profile = profileState.value;
                ReportSheet.show(
                  context,
                  targetType: ReportTargetType.user,
                  targetId: profile?.userId ?? widget.username,
                  targetUserId: profile?.userId,
                  targetName: profile?.displayName ?? '@${widget.username}',
                );
              } else if (val == 'block') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User blocked'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('QR Code & Share'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Copy Link'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Text('Report User', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Block User',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: profileState.when(
        data: (profile) =>
            _buildTelegramProfile(context, profile, feedAsync.valueOrNull, isDark),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00C6FF)),
        ),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_off_rounded,
                  size: 56,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  'User not found or error loading profile',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref
                      .read(publicProfileProvider(widget.username).notifier)
                      .refresh(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00C6FF),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelegramProfile(
    BuildContext context,
    ProfileModel profile,
    List<StoryFeedGroupModel>? feedGroups,
    bool isDark,
  ) {
    final userStoryGroup = feedGroups?.firstWhere(
      (g) => g.owner.id == profile.userId,
      orElse: () => StoryFeedGroupModel(
        owner: StoryAuthorModel(id: profile.userId),
        stories: [],
        hasUnseen: false,
        latestStoryAt: DateTime.now(),
        totalStories: 0,
      ),
    );
    final hasActiveStories =
        userStoryGroup != null && userStoryGroup.stories.isNotEmpty;

    final displayName = profile.displayName ?? profile.username ?? 'User';
    final cardBg = isDark ? const Color(0xFF17212B) : Colors.white;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),

                // 1. Center Avatar with Story Ring (Screenshot 1)
                GestureDetector(
                  onTap: () {
                    if (hasActiveStories) {
                      context.push(
                        '/story-viewer',
                        extra: StoryViewerArgs(
                          groups: [userStoryGroup],
                          initialGroupIndex: 0,
                        ),
                      );
                    } else if (profile.avatarUrl != null) {
                      _showAvatarFullscreen(context, profile.avatarUrl!, displayName);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: hasActiveStories
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF00C6FF),
                                Color(0xFF10B981),
                                Color(0xFF0072FF),
                              ],
                            )
                          : null,
                      border: hasActiveStories
                          ? null
                          : Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.6),
                              width: 2,
                            ),
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor:
                          const Color(0xFF00C6FF).withValues(alpha: 0.2),
                      backgroundImage: profile.avatarUrl != null &&
                              profile.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(
                              MediaUrlResolver.resolve(profile.avatarUrl!) ??
                                  profile.avatarUrl!,
                            )
                          : null,
                      child: profile.avatarUrl == null ||
                              profile.avatarUrl!.isEmpty
                          ? Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00C6FF),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Display Name (Screenshot 1: "Sara Bi")
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle: Status (Screenshot 1: "last seen at 10:02 AM")
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'online',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF10B981) : Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Four Action Buttons Row (Screenshot 1: Message, Mute, Call, Video)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Message',
                        isLoading: _isOpeningChat,
                        isDark: isDark,
                        onTap: () => _openDirectChat(profile.userId),
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
                              content: Text(
                                _isMuted
                                    ? 'Notifications muted'
                                    : 'Notifications unmuted',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.phone_rounded,
                        label: 'Call',
                        isDark: isDark,
                        onTap: () {
                          TelegramCallDialog.show(
                            context,
                            name: displayName,
                            avatarUrl: profile.avatarUrl,
                            isVideoCall: false,
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.videocam_rounded,
                        label: 'Video',
                        isDark: isDark,
                        onTap: () {
                          TelegramCallDialog.show(
                            context,
                            name: displayName,
                            avatarUrl: profile.avatarUrl,
                            isVideoCall: true,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Info Card (Screenshot 1: Phone, Bio, Username with QR Code)
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Phone / Mobile Row
                        _buildInfoTile(
                          title: '+251 940346902',
                          subtitle: 'Mobile',
                          isDark: isDark,
                          onTap: () {
                            Clipboard.setData(
                              const ClipboardData(text: '+251940346902'),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Phone number copied!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          },
                        ),
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06),
                        ),

                        // Bio Row (Screenshot 1: "Manage your entire business from ONE screen!")
                        _buildInfoTile(
                          title: profile.bio != null && profile.bio!.isNotEmpty
                              ? profile.bio!
                              : 'Manage your entire business from ONE screen!',
                          subtitle: 'Bio',
                          isDark: isDark,
                          onTap: () {
                            if (profile.bio != null) {
                              Clipboard.setData(ClipboardData(text: profile.bio!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bio copied!')),
                              );
                            }
                          },
                        ),
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06),
                        ),

                        // Username Row with QR Code Icon (Screenshot 1: "@CNET_CS_manager")
                        _buildInfoTile(
                          title: '@${profile.username ?? "user"}',
                          subtitle: 'Username',
                          isDark: isDark,
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.qr_code_2_rounded,
                              size: 26,
                              color: Color(0xFF00C6FF),
                            ),
                            tooltip: 'Show QR Code',
                            onPressed: () {
                              final canonicalUrl = 'https://app.zikrekidusan.com/u/${profile.username ?? widget.username}';
                              TelegramQrSheet.show(
                                context,
                                title: displayName,
                                subtitle: '@${profile.username ?? ""}',
                                avatarUrl: profile.avatarUrl,
                                qrData: canonicalUrl,
                              );
                            },
                          ),
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: '@${profile.username}'),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Username copied!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // 5. Telegram Tab Bar Header (Screenshot 1: Posts, Media, Files, Links, Groups)
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabHeaderDelegate(
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
                      Tab(text: 'Posts'),
                      Tab(text: 'Media'),
                      Tab(text: 'Files'),
                      Tab(text: 'Links'),
                      Tab(text: 'Groups'),
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
          // Tab 1: Posts (2-column media grid, matching Screenshot 1!)
          _buildPostsMediaGrid(profile.userId, isDark),

          // Tab 2: Media (Photos & Videos)
          _buildMediaGrid(profile.userId, isDark),

          // Tab 3: Files
          _buildFilesList(isDark),

          // Tab 4: Links
          _buildLinksList(profile.website, isDark),

          // Tab 5: Groups
          _buildGroupsList(isDark),
        ],
      ),
    );
  }

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
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF17212B)
              : Colors.white,
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
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00C6FF),
                ),
              )
            else
              Icon(
                icon,
                color: const Color(0xFF00C6FF),
                size: 24,
              ),
            const SizedBox(height: 6),
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

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  // ── Posts Media Grid (Screenshot 1 bottom half) ───────────────────────────

  Widget _buildPostsMediaGrid(String userId, bool isDark) {
    final state = ref.watch(profilePostsProvider(userId));

    if (state.isLoading && state.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C6FF)),
      );
    }

    if (state.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: 48,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No posts shared yet',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.95,
      ),
      itemCount: state.posts.length,
      itemBuilder: (context, index) {
        final post = state.posts[index];
        final mediaUrl = post.media.isNotEmpty
            ? MediaUrlResolver.resolve(post.media.first.url)
            : null;

        return GestureDetector(
          onTap: () {
            if (post.id.isNotEmpty) {
              context.push('/video/${post.id}');
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: isDark ? const Color(0xFF17212B) : Colors.grey[300],
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (mediaUrl != null && mediaUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: mediaUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark
                            ? const Color(0xFF17212B)
                            : Colors.grey[200],
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark
                            ? const Color(0xFF1E2638)
                            : Colors.grey[200],
                        child: const Icon(
                          Icons.image_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: isDark
                          ? const Color(0xFF17212B)
                          : Colors.grey[100],
                      child: Center(
                        child: Text(
                          post.content ?? '',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),

                  // Bottom Gradient with Like/View counts
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.75),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            size: 13,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likesCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.visibility_outlined,
                            size: 13,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.viewsCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaGrid(String userId, bool isDark) {
    return _buildPostsMediaGrid(userId, isDark);
  }

  Widget _buildFilesList(bool isDark) {
    final sampleFiles = [
      {'name': 'Company_Overview_2026.pdf', 'size': '2.4 MB', 'date': 'Today'},
      {'name': 'CNET_OneScreen_Catalog.docx', 'size': '1.1 MB', 'date': 'Yesterday'},
      {'name': 'Presentation_Slide_Deck.pptx', 'size': '8.6 MB', 'date': 'Aug 24'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sampleFiles.length,
      itemBuilder: (context, index) {
        final f = sampleFiles[index];
        return ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF00C6FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.insert_drive_file_rounded,
              color: Color(0xFF00C6FF),
            ),
          ),
          title: Text(
            f['name']!,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            '${f["size"]} • ${f["date"]}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading ${f["name"]}...')),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLinksList(String? website, bool isDark) {
    final links = [
      if (website != null && website.isNotEmpty)
        {'title': 'Official Website', 'url': website},
      {'title': 'CNET Cloud Platform', 'url': 'https://cnet.et/products/onescreen'},
      {'title': 'StreamHub Channel', 'url': 'https://streamhub.app/@${widget.username}'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: links.length,
      itemBuilder: (context, index) {
        final l = links[index];
        return ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.link_rounded,
              color: Color(0xFF10B981),
            ),
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
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF00C6FF),
            ),
          ),
          onTap: () {
            Clipboard.setData(ClipboardData(text: l['url']!));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link copied to clipboard!')),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupsList(bool isDark) {
    final groups = [
      {'name': 'CNET Support Community', 'members': '1,420 members'},
      {'name': 'OneScreen Beta Testers', 'members': '890 members'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final g = groups[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF00C6FF).withValues(alpha: 0.2),
            child: Text(
              g['name']![0],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF00C6FF),
              ),
            ),
          ),
          title: Text(
            g['name']!,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            g['members']!,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDirectChat(String targetUserId) async {
    setState(() => _isOpeningChat = true);
    try {
      final conv = await ref
          .read(chatDiscoveryProvider.notifier)
          .createOrGetDirectConversation(targetUserId);
      if (mounted) {
        context.push('/chats/conversation/${conv.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open chat: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
  }

  void _showAvatarFullscreen(
    BuildContext context,
    String avatarUrl,
    String title,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: MediaUrlResolver.resolve(avatarUrl) ?? avatarUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverTabHeaderDelegate(this.child);

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverTabHeaderDelegate oldDelegate) => true;
}
