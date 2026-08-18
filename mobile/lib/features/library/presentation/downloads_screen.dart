// lib/features/library/presentation/downloads_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/media_experience/presentation/widgets/download_status_tile.dart';
import 'package:flutter/foundation.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final downloadState = ref.watch(downloadServiceProvider);

    // Combine downloading + completed items
    final allIds = <String>{
      ...downloadState.downloads.keys,
      ...downloadState.downloading,
      ...downloadState.errors.keys,
    }.toList();

    return Scaffold(
      appBar: AppBar(title: Text(tr('library.downloads'))),
      body: kIsWeb
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  tr('downloads.web_unavailable'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            )
          : allIds.isEmpty
          ? Center(child: Text(tr('downloads.empty')))
          : ListView.builder(
              itemCount: allIds.length,
              itemBuilder: (context, index) {
                final videoId = allIds[index];
                final metadata = downloadState.downloads[videoId];

                return DownloadStatusTile(videoId: videoId, metadata: metadata);
              },
            ),
    );
  }
}
