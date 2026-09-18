// lib/features/settings/presentation/screens/storage_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/core/utils/localization_service.dart';

class StorageSettingsScreen extends ConsumerStatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  ConsumerState<StorageSettingsScreen> createState() =>
      _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends ConsumerState<StorageSettingsScreen> {
  bool _isProcessing = false;

  Future<void> _handleClearCache() async {
    final tr = ref.read(trProvider);
    setState(() => _isProcessing = true);
    try {
      final cacheManager = ref.read(cacheManagerProvider);
      await cacheManager.clearCache();
      ref.invalidate(storageBreakdownProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr('storage.clear_success'))));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDeleteAllDownloads() async {
    final tr = ref.read(trProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('storage.delete_all_title')),
        content: Text(tr('storage.delete_all_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('storage.delete_all_btn')),
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
          SnackBar(content: Text(tr('storage.delete_all_success'))),
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
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('storage.title')),
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
        error: (err, _) => Center(child: Text('${tr('state.error')}: $err')),
        data: (breakdown) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Storage Overview Card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('storage.total'),
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
                tr('storage.breakdown'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              _buildCategoryTile(
                icon: Icons.download_done_rounded,
                title: tr('storage.downloaded_videos'),
                subtitle: tr('storage.downloaded_videos_desc'),
                size: breakdown.formattedVideo,
                color: Colors.blue,
              ),
              _buildCategoryTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: tr('storage.chat_media'),
                subtitle: tr('storage.chat_media_desc'),
                size: breakdown.formattedChat,
                color: Colors.green,
              ),
              _buildCategoryTile(
                icon: Icons.image_outlined,
                title: tr('storage.image_cache'),
                subtitle: tr('storage.image_cache_desc'),
                size: breakdown.formattedCache,
                color: Colors.orange,
              ),
              _buildCategoryTile(
                icon: Icons.cleaning_services_outlined,
                title: tr('storage.temp_files'),
                subtitle: tr('storage.temp_files_desc'),
                size: breakdown.formattedTemp,
                color: Colors.purple,
              ),
              const SizedBox(height: 32),

              // Actions
              Text(
                tr('storage.manage_space'),
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
                  child: Icon(
                    Icons.delete_sweep_outlined,
                    color: Colors.orange,
                  ),
                ),
                title: Text(tr('storage.clear_cache_title')),
                subtitle: Text(tr('storage.clear_cache_desc')),
                trailing: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : OutlinedButton(
                        onPressed: _handleClearCache,
                        child: Text(tr('storage.clear_btn')),
                      ),
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0x22EF5350),
                  child: Icon(Icons.delete_forever_outlined, color: Colors.red),
                ),
                title: Text(tr('storage.delete_all_label')),
                subtitle: Text(tr('storage.delete_all_desc')),
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
                        child: Text(tr('storage.delete_btn')),
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
      subtitle: Text(subtitle),
      trailing: Text(size, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
