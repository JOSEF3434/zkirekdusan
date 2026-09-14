// lib/features/settings/presentation/downloads_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/settings/presentation/providers/social_settings_provider.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_widgets.dart';

class DownloadsSettingsScreen extends ConsumerWidget {
  const DownloadsSettingsScreen({super.key});

  static const _qualityOptions = [
    '4K Ultra HD',
    '1080p Full HD',
    '720p HD',
    '480p SD',
    '360p Low (Saves Space)',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(socialSettingsProvider);
    final n = ref.read(socialSettingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(tr('settings.downloads')),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Storage Summary Card ───────────────────────────────────────────
          _StorageSummaryCard(isDark: isDark, theme: theme, tr: tr),
          const SizedBox(height: 16),

          // ── Download Quality ───────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.downloads.download_quality'),
            children: [
              SettingsDropdownTile(
                icon: Icons.high_quality_outlined,
                iconColor: const Color(0xFF00C6FF),
                title: tr('settings.downloads.video_quality'),
                value: s.downloadQuality,
                options: _qualityOptions,
                optionLabels: {
                  '4K Ultra HD': tr('settings.downloads.quality.4k'),
                  '1080p Full HD': tr('settings.downloads.quality.1080p'),
                  '720p HD': tr('settings.downloads.quality.720p'),
                  '480p SD': tr('settings.downloads.quality.480p'),
                  '360p Low (Saves Space)': tr('settings.downloads.quality.360p'),
                },
                onChanged: n.setDownloadQuality,
              ),
              SettingsSwitchTile(
                icon: Icons.wifi_outlined,
                iconColor: const Color(0xFF43E97B),
                title: tr('settings.downloads.wifi_only'),
                subtitle: tr('settings.downloads.wifi_only_desc'),
                value: s.downloadWifiOnly,
                onChanged: n.setDownloadWifiOnly,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Auto-Download ─────────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.downloads.auto_download'),
            children: [
              SettingsSwitchTile(
                icon: Icons.image_outlined,
                iconColor: const Color(0xFF9B59B6),
                title: tr('settings.downloads.photos'),
                subtitle: tr('settings.downloads.photos_desc'),
                value: s.autoDownloadPhotos,
                onChanged: n.setAutoDownloadPhotos,
              ),
              SettingsSwitchTile(
                icon: Icons.video_file_outlined,
                iconColor: const Color(0xFFFF9F43),
                title: tr('settings.downloads.videos'),
                subtitle: tr('settings.downloads.videos_desc'),
                value: s.autoDownloadVideos,
                onChanged: n.setAutoDownloadVideos,
              ),
              SettingsSwitchTile(
                icon: Icons.insert_drive_file_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: tr('settings.downloads.docs'),
                subtitle: tr('settings.downloads.docs_desc'),
                value: s.autoDownloadDocs,
                onChanged: n.setAutoDownloadDocs,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Download Location ─────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.downloads.storage_location'),
            children: [
              SettingsNavTile(
                icon: Icons.folder_outlined,
                iconColor: const Color(0xFFFF6584),
                title: tr('settings.downloads.save_location'),
                subtitle: s.storageLocation,
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Downloaded Videos List Link ────────────────────────────────────
          SettingsGroup(
            label: tr('settings.downloads.manage_downloads'),
            children: [
              SettingsNavTile(
                icon: Icons.download_done_rounded,
                iconColor: const Color(0xFF00C6FF),
                title: tr('settings.downloads.downloaded_videos'),
                subtitle: tr('settings.downloads.downloaded_videos_desc'),
                onTap: () {},
              ),
              SettingsNavTile(
                icon: Icons.delete_sweep_outlined,
                iconColor: Colors.red,
                title: tr('settings.downloads.clear_all'),
                subtitle: tr('settings.downloads.clear_all_desc'),
                onTap: () => _confirmClearDownloads(context, tr),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _confirmClearDownloads(BuildContext context, String Function(String, [Map<String, dynamic>?]) tr) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('settings.downloads.clear_confirm_title')),
        content: Text(tr('settings.downloads.clear_confirm_desc')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(tr('common.cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('settings.downloads.clear_cleared'))),
              );
            },
            child: Text(tr('common.delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StorageSummaryCard extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;
  final String Function(String, [Map<String, dynamic>?]) tr;

  const _StorageSummaryCard({
    required this.isDark,
    required this.theme,
    required this.tr,
  });

  @override
  Widget build(BuildContext context) {
    const totalGB = 64.0;
    const usedGB = 18.4;
    const usedFraction = usedGB / totalGB;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF00C6FF)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                tr('settings.downloads.device_storage'),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: usedFraction,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('settings.downloads.used', {'gb': usedGB.toStringAsFixed(1)}),
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text(tr('settings.downloads.free', {'gb': (totalGB - usedGB).toStringAsFixed(1)}),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StorageChip(label: tr('settings.downloads.chip_app'), value: '4.2 GB', color: Colors.white),
              const SizedBox(width: 8),
              _StorageChip(label: tr('settings.downloads.chip_media'), value: '12.8 GB', color: Colors.white70),
              const SizedBox(width: 8),
              _StorageChip(label: tr('settings.downloads.chip_other'), value: '1.4 GB', color: Colors.white54),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorageChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StorageChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
