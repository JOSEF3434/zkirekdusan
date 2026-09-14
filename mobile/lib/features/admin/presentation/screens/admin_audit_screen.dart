// lib/features/admin/presentation/screens/admin_audit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_search_bar.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';

class AdminAuditScreen extends ConsumerStatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  final List<AdminAuditLogItemDto> _logs = [];
  bool _isLoading = false;
  int _page = 1;
  bool _hasNext = false;
  String _action = '';

  @override
  void initState() {
    super.initState();
    _fetchLogs(reset: true);
  }

  Future<void> _fetchLogs({bool reset = false}) async {
    if (_isLoading) return;
    if (reset) {
      setState(() {
        _page = 1;
        _logs.clear();
        _isLoading = true;
      });
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.getAuditLogs(
        page: _page,
        limit: 30,
        action: _action.isNotEmpty ? _action : null,
      );

      final rawItems = res['items'];
      final List<AdminAuditLogItemDto> newItems = rawItems is List<AdminAuditLogItemDto>
          ? rawItems
          : ((rawItems as List?) ?? []).whereType<AdminAuditLogItemDto>().toList();
      final hasNext = res['hasNext'] as bool? ?? false;

      setState(() {
        if (reset) _logs.clear();
        _logs.addAll(newItems);
        _hasNext = hasNext;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.audit')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchLogs(reset: true),
          ),
        ],
      ),
      body: AdminResponsiveLayout(
        child: Column(
          children: [
            AdminSearchBar(
              hintText: 'Filter by action (e.g. BAN, DELETE, APPROVE)...',
              onSearch: (val) {
                _action = val;
                _fetchLogs(reset: true);
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetchLogs(reset: true),
                child: _logs.isEmpty && !_isLoading
                    ? Center(child: Text(tr('admin.no_records')))
                    : ListView.separated(
                        itemCount: _logs.length + (_hasNext ? 1 : 0),
                        separatorBuilder: (_, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index == _logs.length) {
                            if (!_isLoading) {
                              _page++;
                              _fetchLogs();
                            }
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final log = _logs[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.history_edu_rounded),
                            ),
                            title: Text(
                              log.action,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Actor: @${log.username ?? 'system'} • Target: ${log.targetType ?? 'SYSTEM'}:${log.targetId ?? ''}'),
                                if (log.reason != null && log.reason!.isNotEmpty)
                                  Text(
                                    'Reason: "${log.reason}"',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Text(
                              '${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')}\n${log.createdAt.month}/${log.createdAt.day}',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
