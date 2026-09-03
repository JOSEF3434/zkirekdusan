// lib/features/settings/presentation/preferences_settings_screens.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_widgets.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsState = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Appearance & Theme'),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Theme Selection ─────────────────────────────────────────────────
          SettingsGroup(
            label: 'THEME',
            children: [
              _ThemeTile(
                title: 'System Default',
                subtitle: 'Follow device theme setting',
                icon: Icons.brightness_auto_rounded,
                iconColor: const Color(0xFF9B59B6),
                selected: prefsState.themeMode == ThemeMode.system,
                onTap: () => prefsNotifier.setThemeMode(ThemeMode.system),
              ),
              _ThemeTile(
                title: 'Light Mode',
                subtitle: 'Clean white interface',
                icon: Icons.light_mode_rounded,
                iconColor: const Color(0xFFFF9F43),
                selected: prefsState.themeMode == ThemeMode.light,
                onTap: () => prefsNotifier.setThemeMode(ThemeMode.light),
              ),
              _ThemeTile(
                title: 'Dark Mode',
                subtitle: 'Easy on the eyes at night',
                icon: Icons.dark_mode_rounded,
                iconColor: const Color(0xFF6C63FF),
                selected: prefsState.themeMode == ThemeMode.dark,
                onTap: () => prefsNotifier.setThemeMode(ThemeMode.dark),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Chat Bubble Colors Preview ─────────────────────────────────────
          SettingsGroup(
            label: 'CHAT BUBBLES',
            children: [
              SettingsNavTile(
                icon: Icons.color_lens_outlined,
                iconColor: const Color(0xFFFF6584),
                title: 'Accent Color',
                subtitle: 'Customize chat bubble and UI accent color',
                onTap: () => _showColorPicker(context),
              ),
              SettingsNavTile(
                icon: Icons.wallpaper_outlined,
                iconColor: const Color(0xFF43E97B),
                title: 'Chat Wallpaper',
                subtitle: 'Set a custom background for chats',
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Text & Display ─────────────────────────────────────────────────
          SettingsGroup(
            label: 'TEXT & DISPLAY',
            children: [
              SettingsNavTile(
                icon: Icons.format_size_rounded,
                iconColor: const Color(0xFF00C6FF),
                title: 'Font Size',
                subtitle: 'Adjust the text size across the app',
                onTap: () => _showFontSizeSheet(context),
              ),
              SettingsNavTile(
                icon: Icons.animation_outlined,
                iconColor: const Color(0xFF00B894),
                title: 'Animations',
                subtitle: 'Reduce motion for accessibility',
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

  void _showColorPicker(BuildContext context) {
    final colors = [
      const Color(0xFF00C6FF),
      const Color(0xFF6C63FF),
      const Color(0xFF43E97B),
      const Color(0xFFFF6584),
      const Color(0xFFFF9F43),
      const Color(0xFF9B59B6),
      const Color(0xFFEE5A24),
      const Color(0xFF00B894),
    ];
    int selected = 0;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Accent Color',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: colors.asMap().entries.map((e) => GestureDetector(
                  onTap: () => setState(() => selected = e.key),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: e.value,
                      shape: BoxShape.circle,
                      border: selected == e.key
                          ? Border.all(
                              color: Colors.white, width: 3)
                          : null,
                      boxShadow: selected == e.key
                          ? [BoxShadow(color: e.value.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)]
                          : [],
                    ),
                    child: selected == e.key
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 22)
                        : null,
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors[selected],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Apply Color',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFontSizeSheet(BuildContext context) {
    double size = 14.0;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Font Size',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C6FF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Preview text at ${size.round()}px — The quick brown fox jumps.',
                  style: TextStyle(fontSize: size),
                  textAlign: TextAlign.center,
                ),
              ),
              Slider(
                value: size,
                min: 11,
                max: 20,
                divisions: 9,
                label: '${size.round()}px',
                activeColor: const Color(0xFF00C6FF),
                onChanged: (v) => setState(() => size = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Small', style: TextStyle(fontSize: 11)),
                  Text('Default', style: TextStyle(fontSize: 14)),
                  Text('Large', style: TextStyle(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
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
                  child: const Text('Apply',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;
  final bool isLast;

  const _ThemeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          onTap: onTap,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: selected ? const Color(0xFF00C6FF) : null)),
          subtitle: Text(subtitle,
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
          trailing: selected
              ? const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF00C6FF), size: 22)
              : Icon(Icons.circle_outlined,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  size: 22),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 66,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
      ],
    );
  }
}

// ── Language Settings Screen ─────────────────────────────────────────────────
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  static const _languages = [
    ('English', 'en', '🇬🇧'),
    ('አማርኛ (Amharic)', 'am', '🇪🇹'),
    ('ግእዝ (Ge\'ez)', 'gez', '📜'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsState = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Language'),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsGroup(
            label: 'APP LANGUAGE',
            children: [
              ..._languages.asMap().entries.map((entry) {
                final i = entry.key;
                final lang = entry.value;
                final isSelected = prefsState.languageCode == lang.$2;
                final theme = Theme.of(context);
                return Column(
                  children: [
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      onTap: () => prefsNotifier.setLanguageCode(lang.$2),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C6FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(lang.$3,
                              style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      title: Text(lang.$1,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: isSelected
                                  ? const Color(0xFF00C6FF)
                                  : null)),
                      subtitle: Text(lang.$2.toUpperCase(),
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5))),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF00C6FF), size: 24)
                          : Icon(Icons.circle_outlined,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.25),
                              size: 24),
                    ),
                    if (i < _languages.length - 1)
                      Divider(
                          height: 1,
                          indent: 66,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.08)),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
