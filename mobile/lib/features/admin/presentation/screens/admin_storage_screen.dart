// lib/features/admin/presentation/screens/admin_storage_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_stat_card.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';

class AdminStorageScreen extends ConsumerStatefulWidget {
  const AdminStorageScreen({super.key});

  @override
  ConsumerState<AdminStorageScreen> createState() => _AdminStorageScreenState();
}

class _AdminStorageScreenState extends ConsumerState<AdminStorageScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(adminRepositoryProvider).getStorageStats();
      setState(() {
        _stats = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _formatBytes(num bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.storage')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: AdminResponsiveLayout(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Stats
                    Row(
                      children: [
                        Expanded(
                          child: AdminStatCard(
                            title: 'Total Files',
                            value: '${_stats?['totalFiles'] ?? 0}',
                            icon: Icons.insert_drive_file_rounded,
                            color: Colors.cyan,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AdminStatCard(
                            title: 'Total Space Used',
                            value: _formatBytes(_stats?['totalSizeBytes'] ?? 0),
                            icon: Icons.storage_rounded,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Storage by Media Type
                    AdminSectionCard(
                      title: 'Storage Breakdown by Type',
                      subtitle: 'Media assets categorized by format',
                      child: Column(
                        children: ((_stats?['byType'] as List?) ?? []).map((t) {
                          return ListTile(
                            leading: const Icon(Icons.perm_media_outlined),
                            title: Text('${t['type']}'),
                            trailing: Text(
                              '${t['count']} files • ${_formatBytes(t['sizeBytes'] ?? 0)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Storage by Provider
                    AdminSectionCard(
                      title: 'Storage Providers',
                      subtitle: 'Underlying cloud storage buckets',
                      child: Column(
                        children: ((_stats?['byProvider'] as List?) ?? []).map((p) {
                          return ListTile(
                            leading: const Icon(Icons.cloud_outlined),
                            title: Text('${p['provider']}'),
                            trailing: Text(
                              '${p['count']} files • ${_formatBytes(p['sizeBytes'] ?? 0)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
