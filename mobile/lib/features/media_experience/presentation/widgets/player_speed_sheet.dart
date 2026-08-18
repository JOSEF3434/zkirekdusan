// lib/features/media_experience/presentation/widgets/player_speed_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/player/presentation/providers/player_provider.dart';

import '../../domain/playback_preferences.dart';

class PlayerSpeedSheet extends ConsumerWidget {
  final String videoId;

  const PlayerSpeedSheet({super.key, required this.videoId});

  static Future<void> show(BuildContext context, String videoId) {
    return showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (context) => PlayerSpeedSheet(videoId: videoId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider(videoId));
    final notifier = ref.read(playerProvider(videoId).notifier);
    final tr = ref.watch(trProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              tr('player.speed'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          ...PlaybackPreferences.allowedSpeeds.map((speed) {
            final isSelected = state.playbackSpeed == speed;
            return ListTile(
              leading: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : const SizedBox(width: 24),
              title: Text('${speed}x'),
              onTap: () {
                notifier.setPlaybackSpeed(speed);
                Navigator.of(context).pop();
              },
            );
          }),
        ],
      ),
    );
  }
}
