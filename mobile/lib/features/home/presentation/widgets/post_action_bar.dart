import 'package:flutter/material.dart';

class PostActionBar extends StatelessWidget {
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final bool isLiked;
  final bool isSaved;

  const PostActionBar({
    super.key,
    required this.likesCount,
    required this.commentsCount,
    required this.viewsCount,
    required this.isLiked,
    required this.isSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          _ActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : null,
            label: _formatCount(likesCount),
            onPressed: () {},
          ),
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(commentsCount),
            onPressed: () {},
          ),
          _ActionButton(icon: Icons.repeat, label: '', onPressed: () {}),
          const Spacer(),
          _ActionButton(
            icon: Icons.remove_red_eye_outlined,
            label: _formatCount(viewsCount),
            onPressed: null, // Read-only
          ),
          _ActionButton(
            icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count == 0) return '';
    if (count > 999999) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count > 999) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final Color? color;

  const _ActionButton({
    required this.icon,
    this.label,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color:
                  color ??
                  Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
            ),
            if (label != null && label!.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
