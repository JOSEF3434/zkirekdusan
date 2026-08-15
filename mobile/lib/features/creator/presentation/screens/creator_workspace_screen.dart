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
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

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
    final authUser = ref.watch(authProvider).user;
    final currentUserId = authUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Workspace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => context.push('/creator/dashboard'),
            tooltip: 'Creator Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/creator/create-group'),
            tooltip: 'Create New Group',
          ),
        ],
      ),
      body: _buildBody(state, currentUserId),
    );
  }

  Widget _buildBody(CreatorWorkspaceState state, String? currentUserId) {
    if (state.isLoading &&
        state.activeGroups.isEmpty &&
        state.pendingGroups.isEmpty) {
      return const CreatorLoadingSkeleton();
    }

    if (state.error != null &&
        state.activeGroups.isEmpty &&
        state.pendingGroups.isEmpty) {
      return CreatorErrorState(
        error: state.error!,
        onRetry: () => ref.read(creatorWorkspaceProvider.notifier).refresh(),
      );
    }

    if (state.activeGroups.isEmpty && state.pendingGroups.isEmpty) {
      return CreatorEmptyState(
        title: 'No Groups Available',
        message:
            'Create a group to start uploading videos and building your audience.',
        buttonText: 'Create Group',
        onAction: () => context.push('/creator/create-group'),
      );
    }

    // Categorize groups based on the plan
    final pendingGroups = state.pendingGroups;

    // Categorize active groups
    final myGroups = <CreatorGroupDto>[];
    final otherActiveGroups = <CreatorGroupDto>[];

    for (var group in state.activeGroups) {
      if (group.createdById == currentUserId) {
        myGroups.add(group);
      } else {
        otherActiveGroups.add(group);
      }
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(creatorWorkspaceProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if (pendingGroups.isNotEmpty) ...[
            _buildSectionHeader(
              'Pending Review',
              Icons.hourglass_empty,
              Colors.orange,
            ),
            _buildGroupList(pendingGroups, isPending: true),
          ],

          if (myGroups.isNotEmpty) ...[
            _buildSectionHeader('Your Groups', Icons.star, Colors.blue),
            _buildGroupList(myGroups),
          ],

          if (otherActiveGroups.isNotEmpty) ...[
            _buildSectionHeader(
              'Available to Upload',
              Icons.public,
              Colors.green,
            ),
            _buildGroupList(otherActiveGroups),
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
  }) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final group = groups[index];
        return CreatorGroupCard(
          group: group,
          onTap: () {
            if (isPending || group.status == GroupStatus.pendingApproval) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'This group is waiting for approval from a system administrator.',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }
            if (group.status == GroupStatus.suspended ||
                group.status == GroupStatus.archived) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This group is no longer active.'),
                ),
              );
              return;
            }

            context.push('/creator/groups/${group.id}/channels', extra: group);
          },
        );
      }, childCount: groups.length),
    );
  }
}
