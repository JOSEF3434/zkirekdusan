// lib/features/groups/presentation/screens/group_channel_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/creator/domain/creator_enums.dart';
import 'package:mobile/features/creator/presentation/providers/creator_workspace_provider.dart';
import 'package:mobile/features/groups/data/group_repository.dart';
import 'package:mobile/features/groups/domain/group_context_dto.dart';
import 'package:mobile/features/groups/presentation/providers/group_detail_provider.dart';
import 'package:mobile/features/groups/presentation/screens/tabs/group_members_tab.dart';
import 'package:mobile/features/groups/presentation/screens/tabs/group_playlists_tab.dart';
import 'package:mobile/features/groups/presentation/screens/tabs/group_settings_tab.dart';
import 'package:mobile/features/groups/presentation/screens/tabs/group_streams_tab.dart';
import 'package:mobile/features/groups/presentation/screens/tabs/group_video_feed_tab.dart';
import 'package:mobile/features/groups/presentation/widgets/edit_group_sheet.dart';
import 'package:mobile/features/groups/presentation/widgets/group_channel_header.dart';

class GroupChannelScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? initialTab;

  const GroupChannelScreen({super.key, required this.groupId, this.initialTab});

  @override
  ConsumerState<GroupChannelScreen> createState() => _GroupChannelScreenState();
}

class _GroupChannelScreenState extends ConsumerState<GroupChannelScreen> {
  VideoChannelSummaryDto? _selectedChannel;

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));

    return groupAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => _buildErrorScaffold(context, err),
      data: (groupContext) => _buildChannelView(context, groupContext),
    );
  }

  Widget _buildErrorScaffold(BuildContext context, Object err) {
    final theme = Theme.of(context);
    final errStr = err is Failure
        ? err.message
        : err.toString().replaceFirst('Exception: ', '');

    IconData icon = Icons.lock_outline;
    String title = 'Access Denied';
    String description = errStr;
    bool showLogin = false;

    if (errStr.contains('401') ||
        errStr.toLowerCase().contains('unauthorized')) {
      icon = Icons.account_circle_outlined;
      title = 'Sign In Required';
      description = 'You need to sign in to access this channel.';
      showLogin = true;
    } else if (errStr.contains('404') ||
        errStr.toLowerCase().contains('not found')) {
      icon = Icons.search_off;
      title = 'Channel Not Found';
      description = 'This channel does not exist or may have been removed.';
    } else if (errStr.toLowerCase().contains('network') ||
        errStr.toLowerCase().contains('socket')) {
      icon = Icons.wifi_off;
      title = 'Connection Problem';
      description =
          'Unable to connect to the server. Please check your internet connection.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Channel'),
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
              Icon(icon, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(groupDetailProvider(widget.groupId).notifier)
                        .refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(width: 12),
                  if (showLogin)
                    FilledButton(
                      onPressed: () => context.push('/auth/login'),
                      child: const Text('Sign In'),
                    )
                  else
                    FilledButton.tonal(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelView(BuildContext context, GroupContextDto groupContext) {
    final theme = Theme.of(context);
    final activeChannel = _selectedChannel ?? groupContext.primaryChannel;
    final canViewMembers = groupContext.capabilities.canViewMembers;
    final isPending = groupContext.status == GroupStatus.pendingApproval;
    final canManage =
        groupContext.capabilities.canEditGroup ||
        groupContext.capabilities.canUpdateGroup ||
        groupContext.capabilities.canDeleteGroup;

    // Build dynamic tabs based on capabilities
    final tabs = <Tab>[
      const Tab(text: 'Videos'),
      const Tab(text: 'Live'),
      const Tab(text: 'Playlists'),
      if (canViewMembers) const Tab(text: 'Members'),
      const Tab(text: 'About & Settings'),
    ];

    final tabViews = <Widget>[
      GroupVideoFeedTab(
        groupContext: groupContext,
        activeChannel: activeChannel,
      ),
      GroupStreamsTab(
        groupContext: groupContext,
        activeChannel: activeChannel,
      ),
      GroupPlaylistsTab(
        groupContext: groupContext,
        activeChannel: activeChannel,
      ),
      if (canViewMembers) GroupMembersTab(groupContext: groupContext),
      GroupSettingsTab(groupContext: groupContext),
    ];

    int initialIndex = 0;
    if (widget.initialTab == 'live' || widget.initialTab == 'streams') initialIndex = 1;
    if (widget.initialTab == 'playlists') initialIndex = 2;
    if (widget.initialTab == 'members' && canViewMembers) initialIndex = 3;
    if (widget.initialTab == 'settings') initialIndex = tabs.length - 1;

    return DefaultTabController(
      length: tabs.length,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(groupContext.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Sharing @${activeChannel?.handle ?? groupContext.slug}',
                    ),
                  ),
                );
              },
            ),
            if (canManage)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'edit') {
                    EditGroupSheet.show(
                      context,
                      groupId: groupContext.id,
                      initialName: groupContext.name,
                      initialDescription: groupContext.description,
                      initialVisibility: groupContext.visibility.name
                          .toUpperCase(),
                      initialWebsite: groupContext.website,
                      initialCountry: groupContext.country,
                    );
                  } else if (value == 'repair') {
                    try {
                      await ref
                          .read(groupRepositoryProvider)
                          .repairGroup(groupContext.id);
                      ref.invalidate(groupDetailProvider(groupContext.id));
                      ref.read(creatorWorkspaceProvider.notifier).refresh();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Group synced successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sync failed: $e'),
                            backgroundColor: theme.colorScheme.error,
                          ),
                        );
                      }
                    }
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        title: const Text('Delete Group?'),
                        content: Text(
                          'Are you sure you want to delete "${groupContext.name}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dCtx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                            ),
                            onPressed: () => Navigator.of(dCtx).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      try {
                        await ref
                            .read(groupRepositoryProvider)
                            .deleteGroup(groupContext.id);
                        ref.read(creatorWorkspaceProvider.notifier).refresh();
                        if (context.mounted) {
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Group deleted successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Delete failed: $e'),
                              backgroundColor: theme.colorScheme.error,
                            ),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Edit Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'repair',
                    child: Row(
                      children: [
                        Icon(Icons.sync, size: 20),
                        SizedBox(width: 8),
                        Text('Sync & Repair'),
                      ],
                    ),
                  ),
                  if (groupContext.capabilities.canDeleteGroup)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete Group',
                            style: TextStyle(color: Colors.red),
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
              if (isPending)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      border: Border.all(color: Colors.amber.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          color: Colors.amber.shade900,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending Approval',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              Text(
                                'This group is awaiting admin review. You can preview and edit your settings.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: GroupChannelHeader(
                  contextDto: groupContext,
                  selectedChannel: activeChannel,
                  onChannelSelected: (ch) =>
                      setState(() => _selectedChannel = ch),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    tabs: tabs,
                    isScrollable: tabs.length > 3,
                    tabAlignment: tabs.length > 3
                        ? TabAlignment.start
                        : TabAlignment.fill,
                  ),
                  theme.colorScheme.surface,
                ),
              ),
            ];
          },
          body: TabBarView(children: tabViews),
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _color;

  _SliverTabBarDelegate(this._tabBar, this._color);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: _color, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
