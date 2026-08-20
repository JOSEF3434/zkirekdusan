// lib/features/stories/presentation/widgets/story_views_sheet.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:mobile/features/stories/data/datasources/stories_remote_datasource.dart';
import 'package:mobile/features/stories/data/models/story_view_model.dart';

class StoryViewsSheet extends ConsumerStatefulWidget {
  final String storyId;

  const StoryViewsSheet({super.key, required this.storyId});

  static Future<void> show(BuildContext context, String storyId) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StoryViewsSheet(storyId: storyId),
    );
  }

  @override
  ConsumerState<StoryViewsSheet> createState() => _StoryViewsSheetState();
}

class _StoryViewsSheetState extends ConsumerState<StoryViewsSheet> {
  late Future<List<StoryViewModel>> _viewersFuture;

  @override
  void initState() {
    super.initState();
    _viewersFuture = ref
        .read(storiesRemoteDatasourceProvider)
        .getViewers(widget.storyId);
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
                const Icon(Icons.visibility_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Story Views',
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

          // Viewers List
          Expanded(
            child: FutureBuilder<List<StoryViewModel>>(
              future: _viewersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load viewers',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  );
                }

                final viewers = snapshot.data ?? [];
                if (viewers.isEmpty) {
                  return const Center(child: Text('No views yet'));
                }

                return ListView.builder(
                  itemCount: viewers.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final item = viewers[index];
                    final avatarUrl = item.viewer.avatarUrl;
                    final name = item.viewer.effectiveName;
                    final timeStr = timeago.format(item.viewedAt);

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage:
                            avatarUrl != null && avatarUrl.isNotEmpty
                            ? CachedNetworkImageProvider(avatarUrl)
                            : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
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
