// lib/features/creator_analytics/presentation/screens/creator_comment_moderation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/creator_analytics/domain/creator_comment_dto.dart';
import 'package:mobile/features/creator_analytics/presentation/providers/creator_comment_moderation_provider.dart';
import 'package:mobile/features/creator_analytics/presentation/widgets/confirm_action_dialog.dart';

class CreatorCommentModerationScreen extends ConsumerStatefulWidget {
  final String channelId;
  final String videoId;

  const CreatorCommentModerationScreen({
    super.key,
    required this.channelId,
    required this.videoId,
  });

  @override
  ConsumerState<CreatorCommentModerationScreen> createState() =>
      _CreatorCommentModerationScreenState();
}

class _CreatorCommentModerationScreenState
    extends ConsumerState<CreatorCommentModerationScreen> {
  final _scrollController = ScrollController();

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
      ref
          .read(creatorCommentModerationProvider(widget.videoId).notifier)
          .loadMore();
    }
  }

  Future<void> _handleDelete(CreatorCommentDto comment) async {
    final confirm = await ConfirmActionDialog.show(
      context,
      title: 'Delete Comment',
      content:
          'Are you sure you want to delete this comment by ${comment.author.displayHandle}?',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirm != true) return;

    try {
      await ref
          .read(creatorCommentModerationProvider(widget.videoId).notifier)
          .deleteComment(comment.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _handleTogglePin(CreatorCommentDto comment) async {
    try {
      await ref
          .read(creatorCommentModerationProvider(widget.videoId).notifier)
          .togglePin(comment.id);
      if (mounted) {
        final action = comment.isPinned ? 'unpinned' : 'pinned';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Comment $action')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creatorCommentModerationProvider(widget.videoId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('video.moderate_comments')))),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(CreatorCommentModerationState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${state.error}',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            ElevatedButton(
              onPressed: () => ref
                  .read(
                    creatorCommentModerationProvider(widget.videoId).notifier,
                  )
                  .refresh(),
              child: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('common.retry'))),
            ),
          ],
        ),
      );
    }

    if (state.comments.isEmpty) {
      return const Center(child: Text('No comments found.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(creatorCommentModerationProvider(widget.videoId).notifier)
          .refresh(),
      child: ListView.separated(
        controller: _scrollController,
        itemCount: state.comments.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == state.comments.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final comment = state.comments[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundImage: comment.author.avatarUrl != null
                  ? NetworkImage(comment.author.avatarUrl!)
                  : null,
              child: comment.author.avatarUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Row(
              children: [
                Text(
                  comment.author.displayHandle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (comment.isPinned) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.push_pin,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(comment.content),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'delete') _handleDelete(comment);
                if (val == 'pin') _handleTogglePin(comment);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'pin',
                  child: Text(comment.isPinned ? 'Unpin' : 'Pin to top'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


