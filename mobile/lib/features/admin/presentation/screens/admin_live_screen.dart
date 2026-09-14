// lib/features/admin/presentation/screens/admin_live_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_status_badge.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_confirmation_dialog.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';

class AdminLiveScreen extends ConsumerStatefulWidget {
  const AdminLiveScreen({super.key});

  @override
  ConsumerState<AdminLiveScreen> createState() => _AdminLiveScreenState();
}

class _AdminLiveScreenState extends ConsumerState<AdminLiveScreen> {
  final List<dynamic> _streams = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  Future<void> _loadStreams() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.getLiveStreams();
      setState(() {
        _streams.clear();
        _streams.addAll((res['items'] as List?) ?? []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _terminateStream(String id, String title) async {
    final reason = await AdminConfirmationDialog.show(
      context,
      title: 'Terminate Stream',
      message: 'Immediately terminate live broadcast "$title"?',
      confirmLabel: 'Terminate',
      confirmColor: Colors.red,
      requireReason: true,
    );
    if (reason != null) {
      final ok = await ref.read(adminRepositoryProvider).terminateLiveStream(id, reason: reason);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live broadcast terminated')),
        );
        _loadStreams();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.live')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStreams,
          ),
        ],
      ),
      body: AdminResponsiveLayout(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _streams.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.live_tv_rounded, size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(tr('admin.no_records')),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _streams.length,
                    separatorBuilder: (_, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = _streams[index];
                      final creator = safeMap(s['createdBy']);
                      final count = safeMap(s['_count']);
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(Icons.videocam, color: Colors.white),
                        ),
                        title: Text(
                          s['title'] ?? 'Live Stream',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Host: @${creator?['username'] ?? 'creator'} • ${count?['viewers'] ?? 0} viewers',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AdminStatusBadge(status: s['status'] ?? 'LIVE'),
                            const SizedBox(width: 8),
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              onPressed: () => _terminateStream(s['id'], s['title'] ?? ''),
                              child: Text(tr('admin.actions.terminate')),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
