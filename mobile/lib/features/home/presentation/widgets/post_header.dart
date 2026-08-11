import 'package:flutter/material.dart';
import 'package:mobile/features/home/domain/post_model.dart';

class PostHeader extends StatelessWidget {
  final PostAuthorDto author;
  final DateTime createdAt;
  final String? groupId;

  const PostHeader({
    super.key,
    required this.author,
    required this.createdAt,
    this.groupId,
  });

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: author.avatarUrl != null
                ? NetworkImage(author.avatarUrl!)
                : null,
            child: author.avatarUrl == null
                ? Text(author.displayName?.isNotEmpty == true
                    ? author.displayName![0].toUpperCase()
                    : '?')
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        author.displayName ?? author.username ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatDate(createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (author.username != null)
                  Text(
                    '@${author.username}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement options menu
            },
          ),
        ],
      ),
    );
  }
}
