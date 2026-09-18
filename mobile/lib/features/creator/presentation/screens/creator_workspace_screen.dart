// lib/features/creator/presentation/screens/creator_workspace_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/creator/domain/creator_enums.dart';
import 'package:mobile/features/creator/presentation/providers/creator_workspace_provider.dart';
import 'package:mobile/features/creator/presentation/widgets/creator_empty_state.dart';
import 'package:mobile/features/creator/presentation/widgets/creator_error_state.dart';
import 'package:mobile/features/creator/presentation/widgets/creator_group_card.dart';
import 'package:mobile/features/creator/presentation/widgets/creator_loading_skeleton.dart';
import 'package:mobile/features/creator/domain/creator_group_dto.dart';
import 'package:mobile/features/groups/presentation/widgets/group_management_sheet.dart';
import 'package:mobile/core/utils/localization_service.dart';

class CreatorWorkspaceScreen extends ConsumerStatefulWidget {
  const CreatorWorkspaceScreen({super.key});

  @override
  ConsumerState<CreatorWorkspaceScreen> createState() =>
      _CreatorWorkspaceScreenState();
}

class _CreatorWorkspaceScreenState
    extends ConsumerState<CreatorWorkspaceScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Refresh the workspace when this screen mounts to ensure we have the
    // latest groups from the server (e.g. after returning from Create Channel)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(creatorWorkspaceProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(creatorWorkspaceProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creatorWorkspaceProvider);
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('creator.workspace_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => context.push('/creator/upload'),
            tooltip: tr('creator.upload_tooltip'),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => context.push('/creator/dashboard'),
            tooltip: tr('creator.dashboard_tooltip'),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/creator/create-group'),
            tooltip: tr('creator.create_channel_tooltip'),
          ),
        ],
      ),
      body: _buildBody(state, tr),
    );
  }

  Widget _buildBody(
    CreatorWorkspaceState state,
    String Function(String, [Map<String, dynamic>?]) tr,
  ) {
    if (state.isLoading && state.groups.isEmpty) {
      return const CreatorLoadingSkeleton();
    }

    if (state.error != null && state.groups.isEmpty) {
      return CreatorErrorState(
        error: state.error!,
        onRetry: () => ref.read(creatorWorkspaceProvider.notifier).refresh(),
      );
    }

    if (state.groups.isEmpty) {
      return CreatorEmptyState(
        title: tr('creator.no_channels_title'),
        message: tr('creator.no_channels_desc'),
        buttonText: tr('creator.create_channel_btn'),
        onAction: () => context.push('/creator/create-group'),
      );
    }

    // Categorize groups based on status
    final activeGroups = <CreatorGroupDto>[];
    final pendingGroups = <CreatorGroupDto>[];
    final rejectedGroups = <CreatorGroupDto>[];
    final suspendedGroups = <CreatorGroupDto>[];

    for (var group in state.groups) {
      switch (group.status) {
        case GroupStatus.active:
          activeGroups.add(group);
          break;
        case GroupStatus.pendingApproval:
          pendingGroups.add(group);
          break;
        case GroupStatus.rejected:
          rejectedGroups.add(group);
          break;
        case GroupStatus.suspended:
        case GroupStatus.archived:
          suspendedGroups.add(group);
          break;
      }
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(creatorWorkspaceProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if (activeGroups.isNotEmpty) ...[
            _buildSectionHeader(
              tr('creator.active_channels'),
              Icons.star,
              Colors.blue,
            ),
            _buildGroupList(activeGroups),
          ],

          if (pendingGroups.isNotEmpty) ...[
            _buildSectionHeader(
              tr('creator.pending_channels'),
              Icons.hourglass_empty,
              Colors.orange,
            ),
            _buildGroupList(pendingGroups, isPending: true),
          ],

          if (rejectedGroups.isNotEmpty) ...[
            _buildSectionHeader(
              tr('creator.rejected_channels'),
              Icons.cancel,
              Colors.red.shade900,
            ),
            _buildGroupList(rejectedGroups, isRejected: true),
          ],

          if (suspendedGroups.isNotEmpty) ...[
            _buildSectionHeader(
              tr('creator.suspended_channels'),
              Icons.block,
              Colors.red,
            ),
            _buildGroupList(suspendedGroups, isSuspended: true),
          ],

          if (state.isPaginating)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupList(
    List<CreatorGroupDto> groups, {
    bool isPending = false,
    bool isRejected = false,
    bool isSuspended = false,
  }) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final group = groups[index];
        return CreatorGroupCard(
          group: group,
          onTap: () {
            context.push('/groups/${group.id}');
          },
          onLongPress: () {
            GroupManagementSheet.show(context, group: group);
          },
        );
      }, childCount: groups.length),
    );
  }
}
