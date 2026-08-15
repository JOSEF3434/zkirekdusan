// lib/features/creator_analytics/presentation/screens/creator_video_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/creator_analytics/domain/creator_video_dto.dart';
import 'package:mobile/features/creator_analytics/presentation/providers/creator_video_list_provider.dart';
import 'package:mobile/features/creator_analytics/presentation/widgets/confirm_action_dialog.dart';
import 'package:mobile/features/creator_analytics/presentation/widgets/creator_content_skeleton.dart';
import 'package:mobile/features/creator_analytics/presentation/widgets/creator_video_tile.dart';

class CreatorVideoManagementScreen extends ConsumerStatefulWidget {
  final String channelId;
  const CreatorVideoManagementScreen({super.key, required this.channelId});

  @override
  ConsumerState<CreatorVideoManagementScreen> createState() =>
      _CreatorVideoManagementScreenState();
}

class _CreatorVideoManagementScreenState
    extends ConsumerState<CreatorVideoManagementScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  CreatorVideoStatus? _statusFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  VideoListArgs get _args => VideoListArgs(
    channelId: widget.channelId,
    statusFilter: _statusFilter?.value,
    searchQuery: _searchQuery,
  );

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(creatorVideoListProvider(_args).notifier).loadMore();
    }
  }

  void _onSearchSubmit(String val) {
    setState(() => _searchQuery = val.trim());
  }

  Future<void> _handleDelete(CreatorVideoDto video) async {
    final confirm = await ConfirmActionDialog.show(
      context,
      title: 'Delete Video',
      content:
          'Are you sure you want to delete "${video.title}"? This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirm != true) return;

    try {
      await ref
          .read(creatorVideoListProvider(_args).notifier)
          .deleteVideo(video.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Video deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<void> _handlePublish(CreatorVideoDto video) async {
    final confirm = await ConfirmActionDialog.show(
      context,
      title: 'Publish Video',
      content:
          'Are you sure you want to publish "${video.title}"? It will become public immediately.',
      confirmText: 'Publish',
    );
    if (confirm != true) return;

    try {
      await ref
          .read(creatorVideoListProvider(_args).notifier)
          .publishVideo(video.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Video published')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Publish failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creatorVideoListProvider(_args));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Content'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SearchBar(
                  controller: _searchController,
                  hintText: 'Search videos...',
                  leading: const Icon(Icons.search),
                  onSubmitted: _onSearchSubmit,
                  trailing: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchSubmit('');
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('All'),
                          selected: _statusFilter == null,
                          onSelected: (val) =>
                              setState(() => _statusFilter = null),
                        ),
                      ),
                      ...CreatorVideoStatus.values.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(s.value),
                            selected: _statusFilter == s,
                            onSelected: (val) =>
                                setState(() => _statusFilter = val ? s : null),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(CreatorVideoListState state, ThemeData theme) {
    if (state.isLoading) return const CreatorContentSkeleton();

    if (state.error != null && state.videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${state.error}',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            ElevatedButton(
              onPressed: () =>
                  ref.read(creatorVideoListProvider(_args).notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.videos.isEmpty) {
      return const Center(child: Text('No videos found.'));
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(creatorVideoListProvider(_args).notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.videos.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.videos.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final video = state.videos[index];
          return CreatorVideoTile(
            video: video,
            onEdit: () => context.push(
              '/creator/dashboard/video/${widget.channelId}/${video.id}/edit',
              extra: video,
            ),
            onDelete: () => _handleDelete(video),
            onPublish: () => _handlePublish(video),
          );
        },
      ),
    );
  }
}
