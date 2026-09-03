// lib/features/settings/presentation/downloads_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Downloads & Storage'),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Storage Summary Card ───────────────────────────────────────────
          _StorageSummaryCard(isDark: isDark, theme: theme),
          const SizedBox(height: 16),

          // ── Download Quality ───────────────────────────────────────────────
          SettingsGroup(
            label: 'DOWNLOAD QUALITY',
            children: [
              SettingsDropdownTile(
                icon: Icons.high_quality_outlined,
                iconColor: const Color(0xFF00C6FF),
                title: 'Video Quality',
                value: s.downloadQuality,
                options: _qualityOptions,
                onChanged: n.setDownloadQuality,
              ),
              SettingsSwitchTile(
                icon: Icons.wifi_outlined,
                iconColor: const Color(0xFF43E97B),
                title: 'Download on Wi-Fi Only',
                subtitle: 'Save mobile data by only downloading over Wi-Fi',
                value: s.downloadWifiOnly,
                onChanged: n.setDownloadWifiOnly,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Auto-Download ─────────────────────────────────────────────────
          SettingsGroup(
            label: 'AUTO-DOWNLOAD',
            children: [
              SettingsSwitchTile(
                icon: Icons.image_outlined,
                iconColor: const Color(0xFF9B59B6),
                title: 'Photos & Images',
                subtitle: 'Auto-download images from messages',
                value: s.autoDownloadPhotos,
                onChanged: n.setAutoDownloadPhotos,
              ),
              SettingsSwitchTile(
                icon: Icons.video_file_outlined,
                iconColor: const Color(0xFFFF9F43),
                title: 'Videos',
                subtitle: 'Auto-download video clips from messages',
                value: s.autoDownloadVideos,
                onChanged: n.setAutoDownloadVideos,
              ),
              SettingsSwitchTile(
                icon: Icons.insert_drive_file_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: 'Documents & Files',
                subtitle: 'Auto-download files, PDFs and attachments',
                value: s.autoDownloadDocs,
                onChanged: n.setAutoDownloadDocs,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Download Location ─────────────────────────────────────────────
          SettingsGroup(
            label: 'STORAGE LOCATION',
            children: [
              SettingsNavTile(
                icon: Icons.folder_outlined,
                iconColor: const Color(0xFFFF6584),
                title: 'Save Location',
                subtitle: s.storageLocation,
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Downloaded Videos List Link ────────────────────────────────────
          SettingsGroup(
            label: 'MANAGE DOWNLOADS',
            children: [
              SettingsNavTile(
                icon: Icons.download_done_rounded,
                iconColor: const Color(0xFF00C6FF),
                title: 'Downloaded Videos',
                subtitle: 'View and manage offline content',
                onTap: () {},
              ),
              SettingsNavTile(
                icon: Icons.delete_sweep_outlined,
                iconColor: Colors.red,
                title: 'Clear All Downloads',
                subtitle: 'Remove all offline videos and files',
                onTap: () => _confirmClearDownloads(context),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _confirmClearDownloads(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Downloads'),
        content: const Text('All downloaded videos and files will be removed. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All downloads cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StorageSummaryCard extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _StorageSummaryCard({required this.isDark, required this.theme});

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
          const Row(
            children: [
              Icon(Icons.storage_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                'Device Storage',
                style: TextStyle(
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
              Text('${usedGB.toStringAsFixed(1)} GB used',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text('${(totalGB - usedGB).toStringAsFixed(1)} GB free',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StorageChip(label: 'App', value: '4.2 GB', color: Colors.white),
              const SizedBox(width: 8),
              _StorageChip(label: 'Media', value: '12.8 GB', color: Colors.white70),
              const SizedBox(width: 8),
              _StorageChip(label: 'Other', value: '1.4 GB', color: Colors.white54),
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
