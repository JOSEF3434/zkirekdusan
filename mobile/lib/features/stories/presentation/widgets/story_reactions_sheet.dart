// lib/features/stories/presentation/widgets/story_reactions_sheet.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:mobile/features/stories/data/datasources/stories_remote_datasource.dart';
import 'package:mobile/features/stories/data/models/story_reaction_model.dart';

class StoryReactionsSheet extends ConsumerStatefulWidget {
  final String storyId;

  const StoryReactionsSheet({super.key, required this.storyId});

  static Future<void> show(BuildContext context, String storyId) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StoryReactionsSheet(storyId: storyId),
    );
  }

  @override
  ConsumerState<StoryReactionsSheet> createState() =>
      _StoryReactionsSheetState();
}

class _StoryReactionsSheetState extends ConsumerState<StoryReactionsSheet> {
  late Future<List<StoryReactionModel>> _reactionsFuture;

  @override
  void initState() {
    super.initState();
    _reactionsFuture = ref
        .read(storiesRemoteDatasourceProvider)
        .getReactions(widget.storyId);
  }

  String _getEmoji(String reaction) {
    switch (reaction.toUpperCase()) {
      case 'LOVE':
        return '😍';
      case 'HAHA':
        return '😂';
      case 'WOW':
        return '😮';
      case 'SAD':
        return '😢';
      case 'ANGRY':
        return '🔥';
      case 'LIKE':
      default:
        return '❤️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.6,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Story Reactions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Reactions List
          Expanded(
            child: FutureBuilder<List<StoryReactionModel>>(
              future: _reactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load reactions',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  );
                }

                final reactions = snapshot.data ?? [];
                if (reactions.isEmpty) {
                  return const Center(child: Text('No reactions yet'));
                }

                return ListView.builder(
                  itemCount: reactions.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final item = reactions[index];
                    final avatarUrl = item.user.avatarUrl;
                    final name = item.user.effectiveName;
                    final timeStr = timeago.format(item.createdAt);
                    final emoji = _getEmoji(item.reaction);

                    return ListTile(
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            backgroundImage:
                                avatarUrl != null && avatarUrl.isNotEmpty
                                ? CachedNetworkImageProvider(avatarUrl)
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(timeStr, style: theme.textTheme.bodySmall),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
