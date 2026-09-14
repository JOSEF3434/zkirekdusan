// lib/features/admin/presentation/screens/group_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_status_badge.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_confirmation_dialog.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_search_bar.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';

class GroupManagementScreen extends ConsumerStatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  ConsumerState<GroupManagementScreen> createState() =>
      _GroupManagementScreenState();
}

class _GroupManagementScreenState extends ConsumerState<GroupManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<AdminGroupItemDto> _allGroups = [];
  bool _isLoadingAll = false;
  String? _groupError;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAllGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllGroups() async {
    setState(() { _isLoadingAll = true; _groupError = null; });
    try {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.getGroups(search: _search.isEmpty ? null : _search);
      final rawItems = res['items'];
      final List<AdminGroupItemDto> items = rawItems is List<AdminGroupItemDto>
          ? rawItems
          : ((rawItems as List?) ?? []).whereType<AdminGroupItemDto>().toList();
      setState(() {
        _allGroups.clear();
        _allGroups.addAll(items);
        _isLoadingAll = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAll = false;
        _groupError = e.toString();
      });
    }
  }

  Future<void> _handleSuspendGroup(AdminGroupItemDto group) async {
    final reason = await AdminConfirmationDialog.show(
      context,
      title: 'Suspend Group',
      message: 'Suspend group "${group.name}"? Members will not be able to post.',
      confirmColor: Colors.orange,
      requireReason: true,
    );
    if (reason != null) {
      final ok = await ref.read(adminRepositoryProvider).suspendGroup(group.id, reason: reason);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "${group.name}" suspended')),
        );
        _fetchAllGroups();
      }
    }
  }

  Future<void> _handleRestoreGroup(AdminGroupItemDto group) async {
    final ok = await ref.read(adminRepositoryProvider).restoreGroup(group.id);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group "${group.name}" restored to ACTIVE')),
      );
      _fetchAllGroups();
    }
  }

  Future<void> _handleDeleteGroup(AdminGroupItemDto group) async {
    final reason = await AdminConfirmationDialog.show(
      context,
      title: 'Delete Group',
      message: 'Permanently archive/delete group "${group.name}"?',
      confirmColor: Colors.red,
      requireReason: true,
    );
    if (reason != null) {
      final ok = await ref.read(adminRepositoryProvider).deleteGroup(group.id, reason: reason);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "${group.name}" deleted')),
        );
        _fetchAllGroups();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final pendingGroupsAsync = ref.watch(pendingGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.groups')),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions_rounded), text: 'Pending Approval'),
            Tab(icon: Icon(Icons.groups_rounded), text: 'All Platform Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Pending Approvals (Original Preserved Logic)
          AdminResponsiveLayout(
            child: pendingGroupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Failed to load groups: $error'),
                    TextButton(
                      onPressed: () => ref
                          .read(pendingGroupsProvider.notifier)
                          .loadPendingGroups(),
                      child: Text(tr('common.retry')),
                    ),
                  ],
                ),
              ),
              data: (groups) {
                if (groups.isEmpty) {
                  return const Center(child: Text('No groups pending approval.'));
                }

                return ListView.separated(
                  itemCount: groups.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          group.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Handle: @${group.slug} • Visibility: ${group.visibility.name}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              tooltip: 'Approve',
                              onPressed: () async {
                                final success = await ref
                                    .read(pendingGroupsProvider.notifier)
                                    .approveGroup(group.id);
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Group ${group.name} approved.')),
                                  );
                                  _fetchAllGroups();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              tooltip: 'Reject',
                              onPressed: () async {
                                final success = await ref
                                    .read(pendingGroupsProvider.notifier)
                                    .rejectGroup(group.id);
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Group ${group.name} rejected.')),
                                  );
                                  _fetchAllGroups();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Tab 2: All Groups Lifecycle
          AdminResponsiveLayout(
            child: Column(
              children: [
                AdminSearchBar(
                  hintText: 'Search groups by name or handle...',
                  onSearch: (val) {
                    _search = val;
                    _fetchAllGroups();
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoadingAll
                      ? const Center(child: CircularProgressIndicator())
                      : _groupError != null && _allGroups.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                    const SizedBox(height: 12),
                                    const Text('Failed to load groups',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 8),
                                    Text(_groupError!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    const SizedBox(height: 16),
                                    FilledButton.icon(
                                      onPressed: _fetchAllGroups,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _allGroups.isEmpty
                              ? Center(child: Text(tr('admin.no_records')))
                              : ListView.separated(
                              itemCount: _allGroups.length,
                              separatorBuilder: (_, i) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final g = _allGroups[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(g.name.isNotEmpty ? g.name[0].toUpperCase() : 'G'),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          g.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AdminStatusBadge(status: g.status),
                                    ],
                                  ),
                                  subtitle: Text('${g.handle != null ? '@${g.handle} • ' : ''}${g.memberCount} members'),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'SUSPEND') {
                                        _handleSuspendGroup(g);
                                      } else if (val == 'RESTORE') {
                                        _handleRestoreGroup(g);
                                      } else if (val == 'DELETE') {
                                        _handleDeleteGroup(g);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      if (g.status != 'ACTIVE')
                                        const PopupMenuItem(
                                          value: 'RESTORE',
                                          child: Text('Restore to Active'),
                                        ),
                                      if (g.status == 'ACTIVE')
                                        const PopupMenuItem(
                                          value: 'SUSPEND',
                                          child: Text('Suspend Group'),
                                        ),
                                      const PopupMenuItem(
                                        value: 'DELETE',
                                        child: Text('Delete Group', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
