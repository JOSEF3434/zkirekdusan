import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/features/social/presentation/providers/comments_provider.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  final String postId;
  final bool isVideo;

  const CommentsSheet({super.key, required this.postId, this.isVideo = false});

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();

  static void show(BuildContext context, String postId, {bool isVideo = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(postId: postId, isVideo: isVideo),
    );
  }
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();

  (String, bool) get _arg => (widget.postId, widget.isVideo);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(commentsProvider(_arg).notifier).loadMore();
    }
  }

  void _submitComment() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(commentsProvider(_arg).notifier).createComment(text);
    _textController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentsAsync = ref.watch(commentsProvider(_arg));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle and Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comments',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Comments List
              Expanded(
                child: commentsAsync.when(
                  data: (state) {
                    if (state.comments.isEmpty) {
                      return const Center(
                        child: Text('No comments yet. Be the first!'),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount:
                          state.comments.length + (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.comments.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final comment = state.comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            backgroundImage: comment.author.avatarUrl != null
                                ? CachedNetworkImageProvider(
                                    comment.author.avatarUrl!,
                                  )
                                : null,
                            child: comment.author.avatarUrl == null
                                ? Text(
                                    comment.author.displayName?[0]
                                            .toUpperCase() ??
                                        comment.author.username?[0]
                                            .toUpperCase() ??
                                        '?',
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Text(
                                comment.author.displayName ??
                                    comment.author.username ??
                                    'User',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeago.format(comment.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(comment.content),
                          ),
                          trailing: _CommentLikeButton(
                            likesCount: comment.likesCount,
                            isLiked: state.likedCommentIds.contains(comment.id),
                            onTap: () {
                              ref
                                  .read(commentsProvider(_arg).notifier)
                                  .toggleCommentLike(comment.id);
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      Center(child: Text('Failed to load comments: $error')),
                ),
              ),

              // Input Field
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: theme.colorScheme.primary,
                      onPressed: _submitComment,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _CommentLikeButton extends StatefulWidget {
  final int likesCount;
  final bool isLiked;
  final VoidCallback onTap;

  const _CommentLikeButton({
    required this.likesCount,
    required this.isLiked,
    required this.onTap,
  });

  @override
  State<_CommentLikeButton> createState() => _CommentLikeButtonState();
}

class _CommentLikeButtonState extends State<_CommentLikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                widget.isLiked ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: widget.isLiked
                    ? Colors.redAccent
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.likesCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${widget.likesCount}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: widget.isLiked
                        ? Colors.redAccent
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
