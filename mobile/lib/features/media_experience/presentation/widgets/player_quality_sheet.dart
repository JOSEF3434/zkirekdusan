// lib/features/media_experience/presentation/widgets/player_quality_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/player/presentation/providers/player_provider.dart';

class PlayerQualitySheet extends ConsumerWidget {
  final String videoId;

  const PlayerQualitySheet({super.key, required this.videoId});

  static Future<void> show(BuildContext context, String videoId) {
    return showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PlayerQualitySheet(videoId: videoId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider(videoId));
    final notifier = ref.read(playerProvider(videoId).notifier);
    final tr = ref.watch(trProvider);

    final renditions = state.video?.renditions ?? [];

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  tr('player.quality'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              if (renditions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(tr('player.quality_auto')),
                )
              else
                ...renditions.map((rendition) {
                  final isSelected = state.currentRendition?.id == rendition.id;
                  return ListTile(
                    leading: isSelected
                        ? const Icon(Icons.check, color: Colors.blue)
                        : const SizedBox(width: 24),
                    title: Text(rendition.quality),
                    onTap: () {
                      notifier.setQuality(rendition);
                      Navigator.of(context).pop();
                    },
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
