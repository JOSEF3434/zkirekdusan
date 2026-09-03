// lib/features/settings/presentation/screens/storage_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/download_service.dart';

class StorageSettingsScreen extends ConsumerStatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  ConsumerState<StorageSettingsScreen> createState() =>
      _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends ConsumerState<StorageSettingsScreen> {
  bool _isProcessing = false;

  Future<void> _handleClearCache() async {
    setState(() => _isProcessing = true);
    try {
      final cacheManager = ref.read(cacheManagerProvider);
      await cacheManager.clearCache();
      ref.invalidate(storageBreakdownProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDeleteAllDownloads() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Downloads?'),
        content: const Text(
          'This will permanently delete all downloaded videos from your device. You will need an internet connection to watch them again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final cacheManager = ref.read(cacheManagerProvider);
      await cacheManager.clearDownloads();
      ref.invalidate(storageBreakdownProvider);
      ref.invalidate(downloadServiceProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All downloaded videos deleted.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final breakdownAsync = ref.watch(storageBreakdownProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage & Offline Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isProcessing
                ? null
                : () => ref.invalidate(storageBreakdownProvider),
          ),
        ],
      ),
      body: breakdownAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading storage: $err')),
        data: (breakdown) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Storage Overview Card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total App Storage',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        breakdown.formattedTotal,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: breakdown.totalBytes > 0 ? 1.0 : 0.0,
                          minHeight: 8,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Categories List
              Text(
                'Storage Breakdown',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              _buildCategoryTile(
                icon: Icons.download_done_rounded,
                title: 'Downloaded Videos',
                subtitle: 'Saved for offline playback',
                size: breakdown.formattedVideo,
                color: Colors.blue,
              ),
              _buildCategoryTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Chat Media',
                subtitle: 'Images, voice notes, and attachments',
                size: breakdown.formattedChat,
                color: Colors.green,
              ),
              _buildCategoryTile(
                icon: Icons.image_outlined,
                title: 'Image & Thumbnails Cache',
                subtitle: 'Cached for smooth browsing',
                size: breakdown.formattedCache,
                color: Colors.orange,
              ),
              _buildCategoryTile(
                icon: Icons.cleaning_services_outlined,
                title: 'Temporary Files',
                subtitle: 'Incomplete downloads and staging',
                size: breakdown.formattedTemp,
                color: Colors.purple,
              ),
              const SizedBox(height: 32),

              // Actions
              Text(
                'Manage Space',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0x22FFA726),
                  child: Icon(Icons.delete_sweep_outlined, color: Colors.orange),
                ),
                title: const Text('Clear Temporary Cache'),
                subtitle: const Text(
                  'Frees space by deleting cached images and temporary files. Downloaded videos are preserved.',
                ),
                trailing: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : OutlinedButton(
                        onPressed: _handleClearCache,
                        child: const Text('Clear'),
                      ),
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0x22EF5350),
                  child: Icon(Icons.delete_forever_outlined, color: Colors.red),
                ),
                title: const Text('Delete All Downloads'),
                subtitle: const Text(
                  'Permanently removes all offline video files from your device.',
                ),
                trailing: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: _handleDeleteAllDownloads,
                        child: const Text('Delete'),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String size,
    required Color color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Text(
        size,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
