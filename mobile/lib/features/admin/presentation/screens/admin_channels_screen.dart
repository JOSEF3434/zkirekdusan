// lib/features/admin/presentation/screens/admin_channels_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_search_bar.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_confirmation_dialog.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';

class AdminChannelsScreen extends ConsumerStatefulWidget {
  const AdminChannelsScreen({super.key});

  @override
  ConsumerState<AdminChannelsScreen> createState() => _AdminChannelsScreenState();
}

class _AdminChannelsScreenState extends ConsumerState<AdminChannelsScreen> {
  final List<AdminChannelItemDto> _channels = [];
  bool _isLoading = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchChannels();
  }

  Future<void> _fetchChannels([String? search]) async {
    if (search != null) _search = search;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.getChannels(search: _search.isEmpty ? null : _search);
      final rawItems = res['items'];
      final List<AdminChannelItemDto> items = rawItems is List<AdminChannelItemDto>
          ? rawItems
          : ((rawItems as List?) ?? []).whereType<AdminChannelItemDto>().toList();
      setState(() {
        _channels.clear();
        _channels.addAll(items);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteChannel(String id, String name) async {
    final reason = await AdminConfirmationDialog.show(
      context,
      title: 'Delete Channel',
      message: 'Are you sure you want to permanently delete channel "#$name"?',
      confirmColor: Colors.red,
      requireReason: true,
    );
    if (reason != null && mounted) {
      final ok = await ref.read(adminRepositoryProvider).deleteChannel(id, reason: reason);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Channel deleted')),
        );
        _fetchChannels();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.channels')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchChannels(),
          ),
        ],
      ),
      body: AdminResponsiveLayout(
        child: Column(
          children: [
            AdminSearchBar(
              hintText: 'Search channels...',
              onSearch: (val) {
                _fetchChannels(val);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _channels.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.tag_rounded, size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(tr('admin.no_records')),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _channels.length,
                          separatorBuilder: (_, i) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _channels[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.tag_rounded),
                              ),
                              title: Text(item.name.isNotEmpty ? item.name : item.slug),
                              subtitle: Text(
                                '${item.groupName ?? 'General'} • ${item.messageCount} messages',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteChannel(item.id, item.name),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
