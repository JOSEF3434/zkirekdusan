// lib/features/media_experience/presentation/widgets/video_progress_overlay.dart
import 'package:flutter/material.dart';
import 'package:mobile/features/media_experience/domain/playback_progress.dart';

class VideoProgressOverlay extends StatelessWidget {
  final PlaybackProgress progress;

  const VideoProgressOverlay({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: progress.fraction,
      backgroundColor: Colors.white24,
      valueColor: AlwaysStoppedAnimation<Color>(
        Theme.of(context).colorScheme.primary,
      ),
      minHeight: 4,
    );
  }
}
