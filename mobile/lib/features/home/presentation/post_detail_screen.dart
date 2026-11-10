// lib/features/home/presentation/post_detail_screen.dart
// Displays a single Post with full rich text content, media, and comments.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/home/presentation/widgets/post_card.dart';
import 'package:mobile/features/social/presentation/comments_sheet.dart';

final _postDetailProvider = FutureProvider.autoDispose
    .family<PostResponseDto, String>((ref, postId) async {
      final dio = ref.read(apiClientProvider);
      final resp = await dio.get('/posts/$postId');
      final data = parseEnvelope(resp.data);
      return PostResponseDto.fromJson(data);
    });

class PostDetailScreen extends ConsumerWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(_postDetailProvider(postId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 56,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 12),
                Text(
                  'Unable to open this post',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'It may have been deleted or is private.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(_postDetailProvider(postId)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (post) => ListView(
          children: [
            PostCard(
              post: post,
              onPostDeleted: () {
                if (context.canPop()) context.pop();
              },
              onPostUpdated: () => ref.invalidate(_postDetailProvider(postId)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                onPressed: () => CommentsSheet.show(context, post.id),
                icon: const Icon(Icons.comment_outlined),
                label: Text('View & Add Comments (${post.commentsCount})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
