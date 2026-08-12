import 'package:flutter/material.dart';
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/home/presentation/widgets/post_header.dart';
import 'package:mobile/features/home/presentation/widgets/post_media_grid.dart';
import 'package:mobile/features/home/presentation/widgets/post_action_bar.dart';

class PostCard extends StatelessWidget {
  final PostResponseDto post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0, // Flat design is common for social feeds
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostHeader(
            author: post.author,
            createdAt: post.createdAt,
            groupId: post.groupId,
          ),
          if (post.content != null && post.content!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                post.content!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          if (post.hashtags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 4.0,
                children: post.hashtags
                    .map(
                      (tag) => Text(
                        tag,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (post.media.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: PostMediaGrid(media: post.media),
            ),
          const Divider(height: 1),
          PostActionBar(
            likesCount: post.likesCount,
            commentsCount: post.commentsCount,
            viewsCount: post.viewsCount,
            isLiked: post.isLiked ?? false,
            isSaved: post.isSaved ?? false,
          ),
        ],
      ),
    );
  }
}
