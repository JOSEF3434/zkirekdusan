import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/home/data/video_repository.dart';

final watchHistoryProvider = FutureProvider((ref) {
  final repo = ref.watch(videoRepositoryProvider);
  return repo.getWatchHistory(page: 1, limit: 50);
});

class WatchHistoryScreen extends ConsumerWidget {
  const WatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final historyAsync = ref.watch(watchHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('library.history'))),
      body: historyAsync.when(
        data: (response) {
          if (response.data.isEmpty) {
            return Center(child: Text(tr('state.empty')));
          }
          return ListView.builder(
            itemCount: response.data.length,
            itemBuilder: (context, index) {
              final video = response.data[index];
              return ListTile(
                leading: Container(
                  width: 80,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(4),
                    image: video.thumbnailUrl != null
                        ? DecorationImage(
                            image: NetworkImage(video.thumbnailUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                title: Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  video.author.displayName ??
                      video.author.username ??
                      'Unknown Channel',
                ),
                onTap: () => context.push('/video/${video.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            '${tr('state.error')}\n$err',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
