// lib/features/settings/presentation/content_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/settings/presentation/providers/social_settings_provider.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_widgets.dart';

class ContentSettingsScreen extends ConsumerWidget {
  const ContentSettingsScreen({super.key});

  static const _filterOptions = ['Strict', 'Standard', 'Off'];
  static const _autoplayOptions = ['Always', 'Wi-Fi Only', 'Never'];
  static const _qualityOptions = [
    'Auto (Recommended)',
    '4K Ultra HD',
    '1080p Full HD',
    '720p HD',
    '480p SD',
    '360p Low',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(socialSettingsProvider);
    final n = ref.read(socialSettingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = ref.watch(trProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(tr('settings.content_preferences')),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Content Filtering ─────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.content.filtering'),
            children: [
              SettingsDropdownTile(
                icon: Icons.filter_alt_outlined,
                iconColor: const Color(0xFF9B59B6),
                title: tr('settings.content.sensitive_filter'),
                value: s.sensitiveFilter,
                options: _filterOptions,
                optionLabels: {
                  'Strict': tr('settings.content.filter.strict'),
                  'Standard': tr('settings.content.filter.standard'),
                  'Off': tr('settings.content.filter.off'),
                },
                onChanged: n.setSensitiveFilter,
              ),
              SettingsNavTile(
                icon: Icons.not_interested_outlined,
                iconColor: const Color(0xFFFF6584),
                title: tr('settings.content.interests'),
                subtitle: tr('settings.content.interests_desc'),
                onTap: () => _showInterestsSheet(context, tr),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Playback ──────────────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.content.playback'),
            children: [
              SettingsDropdownTile(
                icon: Icons.play_circle_outline_rounded,
                iconColor: const Color(0xFF00C6FF),
                title: tr('settings.content.autoplay_videos'),
                value: s.autoplayMode,
                options: _autoplayOptions,
                optionLabels: {
                  'Always': tr('settings.content.autoplay.always'),
                  'Wi-Fi Only': tr('settings.content.autoplay.wifi_only'),
                  'Never': tr('settings.content.autoplay.never'),
                },
                onChanged: n.setAutoplayMode,
              ),
              SettingsDropdownTile(
                icon: Icons.hd_outlined,
                iconColor: const Color(0xFF43E97B),
                title: tr('settings.content.streaming_quality'),
                value: s.streamingQuality,
                options: _qualityOptions,
                optionLabels: {
                  'Auto (Recommended)': tr('settings.content.quality.auto'),
                  '4K Ultra HD': tr('settings.content.quality.4k'),
                  '1080p Full HD': tr('settings.content.quality.1080p'),
                  '720p HD': tr('settings.content.quality.720p'),
                  '480p SD': tr('settings.content.quality.480p'),
                  '360p Low': tr('settings.content.quality.360p'),
                },
                onChanged: n.setStreamingQuality,
              ),
              SettingsSwitchTile(
                icon: Icons.subtitles_outlined,
                iconColor: const Color(0xFFFF9F43),
                title: tr('settings.content.subtitles_captions'),
                subtitle: tr('settings.content.subtitles_desc'),
                value: s.subtitlesEnabled,
                onChanged: n.setSubtitlesEnabled,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Feed Customization ─────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.content.feed_customization'),
            children: [
              SettingsNavTile(
                icon: Icons.recommend_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: tr('settings.content.recommendation_engine'),
                subtitle: tr('settings.content.recommendation_engine_desc'),
                onTap: () {},
              ),
              SettingsNavTile(
                icon: Icons.history_toggle_off_outlined,
                iconColor: const Color(0xFF00B894),
                title: tr('settings.content.watch_history'),
                subtitle: tr('settings.content.watch_history_desc'),
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showInterestsSheet(BuildContext context, String Function(String, [Map<String, dynamic>?]) tr) {
    final interests = [
      'Technology', 'Music', 'Sports', 'Gaming', 'Cooking',
      'Travel', 'Fashion', 'Science', 'Art', 'Finance',
      'Health', 'Education', 'Comedy', 'News', 'Movies',
    ];
    final selected = <String>{'Technology', 'Gaming', 'Music'};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (_, controller) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Text(tr('settings.content.interests_title'),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(tr('settings.content.interests_subtitle')),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interests
                        .map((i) => FilterChip(
                              label: Text(tr('settings.content.interest.${i.toLowerCase()}')),
                              selected: selected.contains(i),
                              onSelected: (v) => setState(() {
                                if (v) {
                                  selected.add(i);
                                } else {
                                  selected.remove(i);
                                }
                              }),
                              selectedColor: const Color(0xFF00C6FF).withValues(alpha: 0.2),
                              checkmarkColor: const Color(0xFF00C6FF),
                            ))
                        .toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C6FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(tr('settings.content.save_interests'),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
