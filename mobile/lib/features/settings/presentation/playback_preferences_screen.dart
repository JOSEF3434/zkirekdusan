// lib/features/settings/presentation/playback_preferences_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/media_experience/domain/playback_preferences.dart';
import 'package:mobile/features/media_experience/presentation/providers/playback_preferences_provider.dart';
import 'package:mobile/features/media_experience/data/playback_progress_repository.dart';
import 'package:mobile/features/media_experience/presentation/providers/continue_watching_provider.dart';

class PlaybackPreferencesScreen extends ConsumerWidget {
  const PlaybackPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(playbackPreferencesProvider);
    final notifier = ref.read(playbackPreferencesProvider.notifier);
    final tr = ref.watch(trProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(tr('playback.title'))),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(tr('playback.autoplay')),
            subtitle: Text(tr('playback.autoplay_desc')),
            value: prefs.autoplay,
            onChanged: notifier.setAutoplay,
          ),
          const Divider(),
          ListTile(
            title: Text(tr('playback.speed_default')),
            trailing: DropdownButton<double>(
              value: prefs.defaultSpeed,
              onChanged: (val) {
                if (val != null) notifier.setDefaultSpeed(val);
              },
              items: PlaybackPreferences.allowedSpeeds
                  .map((s) => DropdownMenuItem(value: s, child: Text('${s}x')))
                  .toList(),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(tr('playback.wifi_only')),
            subtitle: Text(tr('playback.wifi_only_desc')),
            value: prefs.downloadOnWifiOnly,
            onChanged: kIsWeb ? null : notifier.setDownloadOnWifiOnly,
          ),
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                tr('downloads.web_unavailable'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const Divider(),
          ListTile(
            title: Text(
              tr('playback.clear_progress'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: Text(tr('playback.clear_progress_desc')),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(tr('playback.clear_progress')),
                  content: Text(tr('playback.clear_confirm')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(tr('common.cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        tr('common.delete'),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(playbackProgressRepositoryProvider).clearAll();
                ref.read(continueWatchingProvider.notifier).refresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('playback.cleared'))),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
