// lib/features/groups/presentation/screens/group_channel_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/chats/presentation/providers/conversations_provider.dart';
import 'package:mobile/features/chats/presentation/widgets/telegram_call_dialog.dart';
import 'package:mobile/features/chats/presentation/widgets/telegram_qr_sheet.dart';
import 'package:mobile/features/social/data/report_repository.dart';
import 'package:mobile/features/social/presentation/widgets/report_sheet.dart';

import 'package:mobile/features/groups/domain/group_context_dto.dart';
import 'package:mobile/features/groups/domain/group_enums.dart';
import 'package:mobile/features/groups/presentation/providers/group_detail_provider.dart';
import 'package:mobile/features/groups/presentation/providers/group_members_provider.dart';
import 'package:mobile/features/groups/presentation/screens/tabs/group_playlists_tab.dart';
import 'package:mobile/features/groups/presentation/screens/tabs/group_video_feed_tab.dart';
import 'package:mobile/features/groups/presentation/widgets/add_group_member_sheet.dart';
import 'package:mobile/features/groups/presentation/widgets/edit_group_sheet.dart';

class GroupChannelScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? initialTab;

  const GroupChannelScreen({super.key, required this.groupId, this.initialTab});

  @override
  ConsumerState<GroupChannelScreen> createState() => _GroupChannelScreenState();
}

class _GroupChannelScreenState extends ConsumerState<GroupChannelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMuted = false;
  bool _isOpeningChat = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return groupAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0E1621) : Colors.grey[100],
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0E1621) : Colors.grey[100],
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00C6FF)),
        ),
      ),
      error: (err, stack) => _buildErrorScaffold(context, err),
      data: (groupContext) => _buildTelegramGroupProfile(
        context,
        groupContext,
        isDark,
      ),
    );
  }

  Widget _buildTelegramGroupProfile(
    BuildContext context,
    GroupContextDto groupContext,
    bool isDark,
  ) {
    final canManage = groupContext.capabilities.canEditGroup ||
        groupContext.capabilities.canUpdateGroup ||
        groupContext.capabilities.canDeleteGroup;
    final canManageMembers = groupContext.capabilities.canManageMembers;
    final cardBg = isDark ? const Color(0xFF17212B) : Colors.white;
    final membersState = ref.watch(groupMembersProvider(widget.groupId));
    final members = membersState.members;

    final inviteLink = 't.me/${groupContext.slug.isNotEmpty ? groupContext.slug : widget.groupId}';

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
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit Group',
              onPressed: () {
                EditGroupSheet.show(
                  context,
                  groupId: groupContext.id,
                  initialName: groupContext.name,
                  initialDescription: groupContext.description,
                  initialVisibility:
                      groupContext.visibility.name.toUpperCase(),
                  initialWebsite: groupContext.website,
                  initialCountry: groupContext.country,
                );
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) async {
              if (value == 'share') {
                TelegramQrSheet.show(
                  context,
                  title: groupContext.name,
                  subtitle: inviteLink,
                  avatarUrl: groupContext.avatarUrl,
                  qrData: 'https://$inviteLink',
                );
              } else if (value == 'copy') {
                Clipboard.setData(ClipboardData(text: 'https://$inviteLink'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invite link copied!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              } else if (value == 'report') {
                ReportSheet.show(
                  context,
                  targetType: ReportTargetType.group,
                  targetId: groupContext.id,
                  targetName: groupContext.name,
                );
              } else if (value == 'leave') {
                _confirmLeaveGroup(groupContext);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Share Invite Link'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Copy Link'),
                  ],
                ),
              ),
              if (canManageMembers)
                const PopupMenuItem(
                  value: 'members',
                  child: Row(
                    children: [
                      Icon(Icons.person_add_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Add Members'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Report Group',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Leave Group',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // 1. Large Circular Group Avatar (Screenshot 2: "ኑሮ")
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00C6FF).withValues(alpha: 0.2),
                      border: Border.all(
                        color: const Color(0xFF00C6FF).withValues(alpha: 0.5),
                        width: 2.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFF00C6FF).withValues(alpha: 0.8),
                      backgroundImage: groupContext.avatarUrl != null &&
                              groupContext.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(groupContext.avatarUrl!)
                          : null,
                      child: groupContext.avatarUrl == null ||
                              groupContext.avatarUrl!.isEmpty
                          ? Text(
                              groupContext.name.isNotEmpty
                                  ? (groupContext.name.length > 2
                                      ? groupContext.name.substring(0, 2)
                                      : groupContext.name)
                                  : 'G',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Group Title (Screenshot 2: "ኑሮ 🥺🎭")
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      groupContext.name,
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
                  const SizedBox(height: 4),

                  // Subtitle: Member Count (Screenshot 2: "1 member")
                  Text(
                    '${groupContext.membersCount} ${groupContext.membersCount == 1 ? "member" : "members"}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Five Telegram Action Buttons (Screenshot 2: Message, Unmute, Video Chat, Add Story, Leave)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildGroupActionButton(
                          icon: Icons.chat_bubble_rounded,
                          label: 'Message',
                          isLoading: _isOpeningChat,
                          isDark: isDark,
                          onTap: () => _openGroupChat(groupContext.id),
                        ),
                        _buildGroupActionButton(
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
                                      ? 'Notifications unmuted'
                                      : 'Notifications muted',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        _buildGroupActionButton(
                          icon: Icons.graphic_eq_rounded,
                          label: 'Video Chat',
                          isDark: isDark,
                          onTap: () {
                            TelegramCallDialog.show(
                              context,
                              name: groupContext.name,
                              avatarUrl: groupContext.avatarUrl,
                              isVideoCall: true,
                              isGroup: true,
                            );
                          },
                        ),
                        _buildGroupActionButton(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Add Story',
                          isDark: isDark,
                          onTap: () => context.push('/story/create'),
                        ),
                        _buildGroupActionButton(
                          icon: Icons.logout_rounded,
                          label: 'Leave',
                          isDark: isDark,
                          onTap: () => _confirmLeaveGroup(groupContext),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. Invite Link Card (Screenshot 2: "t.me/nuro_ye" with QR code icon)
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
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Text(
                          inviteLink,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'Invite Link',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.qr_code_2_rounded,
                            size: 26,
                            color: Color(0xFF00C6FF),
                          ),
                          tooltip: 'Show QR Code',
                          onPressed: () {
                            TelegramQrSheet.show(
                              context,
                              title: groupContext.name,
                              subtitle: inviteLink,
                              avatarUrl: groupContext.avatarUrl,
                              qrData: 'https://$inviteLink',
                            );
                          },
                        ),
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: 'https://$inviteLink'),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invite link copied!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Members Section Card (Screenshot 2: Add Members + Member List)
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
                          // "Add Members" button
                          ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C6FF)
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: Color(0xFF00C6FF),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'Add Members',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            onTap: () =>
                                AddGroupMemberSheet.show(context, widget.groupId),
                          ),

                          if (members.isNotEmpty)
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.06),
                            ),

                          // Member preview list items (Screenshot 2: Yossief Enyew, online, Owner)
                          ...members.take(5).map((member) {
                            final isOwner =
                                member.role == GroupRole.groupAdmin;
                            final isAdmin =
                                member.role == GroupRole.moderator;
                            final memberName = member.displayName ??
                                member.username ??
                                'Member';

                            return ListTile(
                              onTap: member.username != null
                                  ? () => context.push(
                                        '/profile/user/${member.username}',
                                      )
                                  : null,
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF00C6FF)
                                    .withValues(alpha: 0.2),
                                child: Text(
                                  memberName.isNotEmpty
                                      ? memberName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00C6FF),
                                  ),
                                ),
                              ),
                              title: Text(
                                memberName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'online',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? const Color(0xFF10B981)
                                          : Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: isOwner || isAdmin
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOwner
                                            ? const Color(0xFF8B5CF6)
                                                .withValues(alpha: 0.2)
                                            : const Color(0xFF00C6FF)
                                                .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isOwner
                                              ? const Color(0xFF8B5CF6)
                                                  .withValues(alpha: 0.4)
                                              : const Color(0xFF00C6FF)
                                                  .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        isOwner ? 'Owner' : 'Admin',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isOwner
                                              ? const Color(0xFFA78BFA)
                                              : const Color(0xFF00C6FF),
                                        ),
                                      ),
                                    )
                                  : null,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // 6. Tabs Header (Screenshot 2: Media, Files, Links, Music, GIFs + Videos, Playlists)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverGroupTabDelegate(
                Container(
                  color: isDark ? const Color(0xFF0E1621) : Colors.grey[100],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            // Tab 1: Media
            _buildMediaGrid(groupContext, isDark),

            // Tab 2: Files
            _buildFilesList(isDark),

            // Tab 3: Links
            _buildLinksList(groupContext.website, isDark),

            // Tab 4: Music
            _buildMusicList(isDark),

            // Tab 5: GIFs
            _buildGifsGrid(isDark),

            // Tab 6: Channel Videos (Preserving full channel capability)
            GroupVideoFeedTab(
              groupContext: groupContext,
              activeChannel: groupContext.primaryChannel,
            ),

            // Tab 7: Playlists (Preserving full playlist capability)
            GroupPlaylistsTab(
              groupContext: groupContext,
              activeChannel: groupContext.primaryChannel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupActionButton({
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
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00C6FF),
                ),
              )
            else
              Icon(
                icon,
                color: const Color(0xFF00C6FF),
                size: 22,
              ),
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

  Widget _buildMediaGrid(GroupContextDto group, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final sampleImages = [
          'https://images.unsplash.com/photo-1518770660439-4636190af475?w=500',
          'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=500',
          'https://images.unsplash.com/photo-1534972195531-a756b1126f24?w=500',
          'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=500',
          'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=500',
          'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=500',
          'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=500',
          'https://images.unsplash.com/photo-1504639725590-34d0984388bd?w=500',
          'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=500',
        ];

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: sampleImages[index % sampleImages.length],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: isDark ? const Color(0xFF17212B) : Colors.grey[200],
            ),
            errorWidget: (context, url, error) => Container(
              color: isDark ? const Color(0xFF1E2638) : Colors.grey[300],
              child: const Icon(Icons.image_outlined, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilesList(bool isDark) {
    final sampleFiles = [
      {'name': 'Group_Guidelines.pdf', 'size': '1.2 MB', 'date': 'Jan 19'},
      {'name': 'Project_Milestones.docx', 'size': '540 KB', 'date': 'Jan 12'},
      {'name': 'Resources_Links.pdf', 'size': '2.8 MB', 'date': 'Dec 28'},
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
        {'title': 'Official Community', 'url': website},
      {'title': 'Telegram Channel', 'url': 'https://t.me/nuro_ye'},
      {'title': 'Discussion Forum', 'url': 'https://streamhub.app/g/${widget.groupId}'},
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

  Widget _buildMusicList(bool isDark) {
    final musicFiles = [
      {'title': 'Voice Note - Team Update', 'duration': '02:45', 'date': 'Today'},
      {'title': 'Meeting Audio Record', 'duration': '14:20', 'date': 'Yesterday'},
      {'title': 'Community Intro Podcast.mp3', 'duration': '08:12', 'date': 'Jan 15'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: musicFiles.length,
      itemBuilder: (context, index) {
        final m = musicFiles[index];
        return ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.audiotrack_rounded,
              color: Color(0xFFFFB300),
            ),
          ),
          title: Text(
            m['title']!,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            '${m["duration"]} • ${m["date"]}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Playing ${m["title"]}...')),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGifsGrid(bool isDark) {
    return Center(
      child: Text(
        'No GIFs shared yet',
        style: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontSize: 15,
        ),
      ),
    );
  }

  Future<void> _openGroupChat(String groupId) async {
    setState(() => _isOpeningChat = true);
    try {
      final conv = await ref
          .read(chatDiscoveryProvider.notifier)
          .createOrGetGroupConversation(groupId);
      if (mounted) {
        context.push('/chats/conversation/${conv.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open group chat: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
  }

  Future<void> _confirmLeaveGroup(
    GroupContextDto group,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('groups.leave'))),
        content: Text('Are you sure you want to leave "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('common.cancel'))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('groups.leave_action'))),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You left ${group.name}')),
      );
    }
  }

  Widget _buildErrorScaffold(BuildContext context, Object err) {
    final theme = Theme.of(context);
    final errStr = err is Failure
        ? err.message
        : err.toString().replaceFirst('Exception: ', '');

    return Scaffold(
      appBar: AppBar(
        title: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('common.channel'))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Unable to load group',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errStr,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref
                    .read(groupDetailProvider(widget.groupId).notifier)
                    .refresh(),
                icon: const Icon(Icons.refresh),
                label: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('common.retry'))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverGroupTabDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverGroupTabDelegate(this.child);

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
  bool shouldRebuild(_SliverGroupTabDelegate oldDelegate) => true;
}



