import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/social/presentation/providers/likes_provider.dart';

class LikeButton extends ConsumerStatefulWidget {
  final String postId;
  final int initialLikesCount;
  final bool initialIsLiked;
  final double iconSize;
  final TextStyle? textStyle;
  final Color? defaultColor;
  final Color activeColor;

  final bool isVideo;

  const LikeButton({
    super.key,
    required this.postId,
    required this.initialLikesCount,
    required this.initialIsLiked,
    this.iconSize = 28.0,
    this.textStyle,
    this.defaultColor,
    this.activeColor = Colors.red,
    this.isVideo = false,
  });

  @override
  ConsumerState<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

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
    ]).animate(_controller);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(likesProvider.notifier)
          .seed(widget.postId, widget.initialIsLiked, widget.initialLikesCount);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    ref
        .read(likesProvider.notifier)
        .toggleLike(widget.postId, isVideo: widget.isVideo);
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final likeStateMap = ref.watch(likesProvider);
    final likeState = likeStateMap[widget.postId];

    final isLiked = likeState?.isLiked ?? widget.initialIsLiked;
    final count = likeState?.likesCount ?? widget.initialLikesCount;

    final themeColor = Theme.of(context).iconTheme.color ?? Colors.black;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked
                  ? widget.activeColor
                  : (widget.defaultColor ?? themeColor),
              size: widget.iconSize,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCount(count),
            style:
                widget.textStyle ??
                TextStyle(
                  color: widget.defaultColor ?? themeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count == 0) return 'Like';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
