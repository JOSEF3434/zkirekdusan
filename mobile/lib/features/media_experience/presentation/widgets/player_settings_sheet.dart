// lib/features/media_experience/presentation/widgets/player_settings_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/media_experience/domain/playback_preferences.dart';
import 'package:mobile/features/media_experience/presentation/providers/playback_preferences_provider.dart';
import 'package:mobile/features/media_experience/presentation/widgets/player_quality_sheet.dart';
import 'package:mobile/features/media_experience/presentation/widgets/player_speed_sheet.dart';
import 'package:mobile/features/player/presentation/providers/player_provider.dart';

class PlayerSettingsSheet extends ConsumerWidget {
  final String videoId;

  const PlayerSettingsSheet({super.key, required this.videoId});

  static Future<void> show(BuildContext context, String videoId) {
    return showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PlayerSettingsSheet(videoId: videoId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider(videoId));
    final prefs = ref.watch(playbackPreferencesProvider);
    final notifier = ref.read(playbackPreferencesProvider.notifier);
    final tr = ref.watch(trProvider);
    final theme = Theme.of(context);

    final currentQuality = state.currentRendition?.quality ?? tr('player.quality_auto');

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded),
                    const SizedBox(width: 12),
                    Text(
                      tr('playback.settings_title'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Quality option
              ListTile(
                leading: const Icon(Icons.high_quality_outlined),
                title: Text(tr('player.quality')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentQuality,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  PlayerQualitySheet.show(context, videoId);
                },
              ),
              // Playback Speed option
              ListTile(
                leading: const Icon(Icons.speed_outlined),
                title: Text(tr('player.speed')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${state.playbackSpeed}x',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  PlayerSpeedSheet.show(context, videoId);
                },
              ),
              const Divider(height: 1),
              // Double-tap seek toggle
              SwitchListTile(
                secondary: const Icon(Icons.touch_app_outlined),
                title: Text(tr('playback.double_tap_seek')),
                subtitle: Text(
                  tr('playback.double_tap_seek_desc'),
                  style: theme.textTheme.bodySmall,
                ),
                value: prefs.doubleTapSeekEnabled,
                onChanged: notifier.setDoubleTapSeekEnabled,
              ),
              if (prefs.doubleTapSeekEnabled) ...[
                ListTile(
                  leading: const Icon(Icons.fast_forward_outlined),
                  title: Text(tr('playback.seek_forward_interval')),
                  trailing: DropdownButton<int>(
                    value: prefs.seekForwardSeconds,
                    underline: const SizedBox.shrink(),
                    onChanged: (val) {
                      if (val != null) notifier.setSeekForwardSeconds(val);
                    },
                    items: PlaybackPreferences.allowedSeekIntervals
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                tr('playback.seconds_format', {'seconds': s}),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.fast_rewind_outlined),
                  title: Text(tr('playback.seek_backward_interval')),
                  trailing: DropdownButton<int>(
                    value: prefs.seekBackwardSeconds,
                    underline: const SizedBox.shrink(),
                    onChanged: (val) {
                      if (val != null) notifier.setSeekBackwardSeconds(val);
                    },
                    items: PlaybackPreferences.allowedSeekIntervals
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                tr('playback.seconds_format', {'seconds': s}),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
              const Divider(height: 1),
              // Auto-hide controls
              SwitchListTile(
                secondary: const Icon(Icons.visibility_off_outlined),
                title: Text(tr('playback.auto_hide_controls')),
                subtitle: Text(
                  tr('playback.auto_hide_controls_desc'),
                  style: theme.textTheme.bodySmall,
                ),
                value: prefs.autoHideControls,
                onChanged: notifier.setAutoHideControls,
              ),
              if (prefs.autoHideControls)
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: Text(tr('playback.auto_hide_delay')),
                  trailing: DropdownButton<int>(
                    value: prefs.autoHideDelaySeconds,
                    underline: const SizedBox.shrink(),
                    onChanged: (val) {
                      if (val != null) notifier.setAutoHideDelaySeconds(val);
                    },
                    items: PlaybackPreferences.allowedAutoHideDelays
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                tr('playback.seconds_format', {'seconds': s}),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(tr('playback.title')),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/settings/playback');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
