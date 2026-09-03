// lib/features/settings/presentation/content_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Content Preferences'),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Content Filtering ─────────────────────────────────────────────
          SettingsGroup(
            label: 'CONTENT FILTERING',
            children: [
              SettingsDropdownTile(
                icon: Icons.filter_alt_outlined,
                iconColor: const Color(0xFF9B59B6),
                title: 'Sensitive Content Filter',
                value: s.sensitiveFilter,
                options: _filterOptions,
                onChanged: n.setSensitiveFilter,
              ),
              SettingsNavTile(
                icon: Icons.not_interested_outlined,
                iconColor: const Color(0xFFFF6584),
                title: 'Interests & Blocked Topics',
                subtitle: 'Customize what appears in your feed',
                onTap: () => _showInterestsSheet(context),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Playback ──────────────────────────────────────────────────────
          SettingsGroup(
            label: 'PLAYBACK',
            children: [
              SettingsDropdownTile(
                icon: Icons.play_circle_outline_rounded,
                iconColor: const Color(0xFF00C6FF),
                title: 'Autoplay Videos',
                value: s.autoplayMode,
                options: _autoplayOptions,
                onChanged: n.setAutoplayMode,
              ),
              SettingsDropdownTile(
                icon: Icons.hd_outlined,
                iconColor: const Color(0xFF43E97B),
                title: 'Streaming Quality',
                value: s.streamingQuality,
                options: _qualityOptions,
                onChanged: n.setStreamingQuality,
              ),
              SettingsSwitchTile(
                icon: Icons.subtitles_outlined,
                iconColor: const Color(0xFFFF9F43),
                title: 'Subtitles & Captions',
                subtitle: 'Enable automatically when available',
                value: s.subtitlesEnabled,
                onChanged: n.setSubtitlesEnabled,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Feed Customization ─────────────────────────────────────────────
          SettingsGroup(
            label: 'FEED CUSTOMIZATION',
            children: [
              SettingsNavTile(
                icon: Icons.recommend_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: 'Recommendation Engine',
                subtitle: 'Manage what the algorithm prioritizes',
                onTap: () {},
              ),
              SettingsNavTile(
                icon: Icons.history_toggle_off_outlined,
                iconColor: const Color(0xFF00B894),
                title: 'Watch History',
                subtitle: 'View or clear your watch history',
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

  void _showInterestsSheet(BuildContext context) {
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
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Text('Interests',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text('Select topics you enjoy to personalize your feed'),
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
                              label: Text(i),
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
                    child: const Text('Save Interests',
                        style: TextStyle(fontWeight: FontWeight.bold)),
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
