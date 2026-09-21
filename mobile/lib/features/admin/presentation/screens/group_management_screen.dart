// lib/features/admin/presentation/screens/group_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_status_badge.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_confirmation_dialog.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_search_bar.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_filter_chips.dart';
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

  // Pending Tab State
  final List<AdminGroupItemDto> _pendingGroups = [];
  bool _isLoadingPending = false;
  String? _pendingError;

  // All Groups Tab State
  final List<AdminGroupItemDto> _allGroups = [];
  bool _isLoadingAll = false;
  String? _allGroupsError;
  String _search = '';
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPendingGroups();
    _fetchAllGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPendingGroups() async {
    setState(() {
      _isLoadingPending = true;
      _pendingError = null;
    });
    try {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.getGroups(status: 'PENDING_APPROVAL', limit: 50);
      final rawItems = res['items'];
      final List<AdminGroupItemDto> items = rawItems is List<AdminGroupItemDto>
          ? rawItems
          : ((rawItems as List?) ?? []).whereType<AdminGroupItemDto>().toList();
      setState(() {
        _pendingGroups.clear();
        _pendingGroups.addAll(items);
        _isLoadingPending = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPending = false;
        _pendingError = e.toString();
      });
    }
  }

  Future<void> _fetchAllGroups() async {
    setState(() {
      _isLoadingAll = true;
      _allGroupsError = null;
    });
    try {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.getGroups(
        search: _search.isEmpty ? null : _search,
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
        limit: 50,
      );
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
        _allGroupsError = e.toString();
      });
    }
  }

  void _refreshAll() {
    _fetchPendingGroups();
    _fetchAllGroups();
  }

  Future<void> _handleApproveGroup(AdminGroupItemDto group) async {
    final reason = await AdminConfirmationDialog.show(
      context,
      title: 'Approve Group',
      message:
          'Approve group "${group.name}"? It will become active immediately.',
      confirmColor: Colors.green,
      confirmLabel: 'Approve',
      requireReason: false,
    );
    if (reason == null && !mounted) return;

    final ok = await ref
        .read(adminRepositoryProvider)
        .approveGroup(
          group.id,
          reason: reason?.isEmpty ?? true ? null : reason,
        );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group "${group.name}" approved successfully')),
      );
      _refreshAll();
    }
  }

  Future<void> _handleRejectGroup(AdminGroupItemDto group) async {
    final reason = await AdminConfirmationDialog.show(
      context,
      title: 'Reject Group',
      message: 'Reject group "${group.name}"? Please specify a reason.',
      confirmColor: Colors.red,
      confirmLabel: 'Reject',
      requireReason: true,
    );
    if (reason != null && reason.isNotEmpty) {
      final ok = await ref
          .read(adminRepositoryProvider)
          .rejectGroup(group.id, reason: reason);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "${group.name}" rejected')),
        );
        _refreshAll();
      }
    }
  }

  Future<void> _handleSuspendGroup(AdminGroupItemDto group) async {
    final reason = await AdminConfirmationDialog.show(
      context,
      title: 'Suspend Group',
      message:
          'Suspend group "${group.name}"? Members will not be able to post.',
      confirmColor: Colors.orange,
      confirmLabel: 'Suspend',
      requireReason: true,
    );
    if (reason != null && reason.isNotEmpty) {
      final ok = await ref
          .read(adminRepositoryProvider)
          .suspendGroup(group.id, reason: reason);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "${group.name}" suspended')),
        );
        _refreshAll();
      }
    }
  }

  Future<void> _handleRestoreGroup(AdminGroupItemDto group) async {
    final ok = await ref.read(adminRepositoryProvider).restoreGroup(group.id);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group "${group.name}" restored to ACTIVE')),
      );
      _refreshAll();
    }
  }

  Future<void> _handleDeleteGroup(AdminGroupItemDto group) async {
    final reason = await AdminConfirmationDialog.show(
      context,
      title: 'Delete Group',
      message: 'Permanently archive/delete group "${group.name}"?',
      confirmColor: Colors.red,
      confirmLabel: 'Delete',
      requireReason: true,
    );
    if (reason != null && reason.isNotEmpty) {
      final ok = await ref
          .read(adminRepositoryProvider)
          .deleteGroup(group.id, reason: reason);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "${group.name}" deleted')),
        );
        _refreshAll();
      }
    }
  }

  void _showGroupDetails(AdminGroupItemDto group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(group.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Status: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  AdminStatusBadge(status: group.status),
                ],
              ),
              const SizedBox(height: 8),
              if (group.slug != null || group.handle != null) ...[
                Text('Handle: @${group.slug ?? group.handle}'),
                const SizedBox(height: 4),
              ],
              Text('Members: ${group.memberCount}'),
              const SizedBox(height: 4),
              if (group.creatorUsername != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Created by: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Flexible(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          context.push(
                            '/profile/user/${Uri.encodeComponent(group.creatorUsername!)}',
                          );
                        },
                        child: Text(
                          '@${group.creatorUsername}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'ID: ${group.id}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'Created: ${group.createdAt.toLocal().toString().split('.')[0]}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (group.description != null &&
                  group.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Description: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(group.description!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Consumer(
              builder: (context, ref, child) =>
                  Text(ref.watch(trProvider)('common.close')),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.groups')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAll),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.pending_actions_rounded),
              text: _pendingGroups.isNotEmpty
                  ? 'Pending (${_pendingGroups.length})'
                  : 'Pending Approval',
            ),
            Tab(
              icon: const Icon(Icons.groups_rounded),
              text: _allGroups.isNotEmpty
                  ? 'All Groups (${_allGroups.length})'
                  : 'All Platform Groups',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Pending Approval
          _buildPendingTab(),

          // Tab 2: All Platform Groups
          _buildAllGroupsTab(),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return AdminResponsiveLayout(
      child: RefreshIndicator(
        onRefresh: _fetchPendingGroups,
        child: _isLoadingPending && _pendingGroups.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _pendingError != null && _pendingGroups.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Consumer(
                        builder: (context, ref, child) => Text(
                          ref.watch(trProvider)('common.error'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pendingError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _fetchPendingGroups,
                        icon: const Icon(Icons.refresh),
                        label: Consumer(
                          builder: (context, ref, child) =>
                              Text(ref.watch(trProvider)('common.retry')),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _pendingGroups.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 56,
                      color: Colors.green.shade300,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No groups pending approval.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _pendingGroups.length,
                separatorBuilder: (_, i) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final group = _pendingGroups[index];
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.amber.shade100,
                        child: Text(
                          group.name.isNotEmpty
                              ? group.name[0].toUpperCase()
                              : 'G',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const AdminStatusBadge(status: 'PENDING_APPROVAL'),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            '@${group.slug ?? group.handle ?? group.id} • ${group.memberCount} members'
                            '${group.creatorUsername != null ? ' • by @${group.creatorUsername}' : ''}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 26,
                            ),
                            tooltip: 'Approve Group',
                            onPressed: () => _handleApproveGroup(group),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: Colors.red,
                              size: 26,
                            ),
                            tooltip: 'Reject Group',
                            onPressed: () => _handleRejectGroup(group),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'DETAILS') {
                                _showGroupDetails(group);
                              } else if (val == 'DELETE') {
                                _handleDeleteGroup(group);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'DETAILS',
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'DELETE',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete Group',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildAllGroupsTab() {
    final tr = ref.watch(trProvider);

    return AdminResponsiveLayout(
      child: Column(
        children: [
          AdminSearchBar(
            hintText: 'Search groups by name or handle...',
            onSearch: (val) {
              _search = val;
              _fetchAllGroups();
            },
          ),
          const SizedBox(height: 10),
          AdminFilterChips(
            filters: const [
              AdminFilterChipItem(label: 'All Status', value: 'ALL'),
              AdminFilterChipItem(label: 'Active', value: 'ACTIVE'),
              AdminFilterChipItem(label: 'Pending', value: 'PENDING_APPROVAL'),
              AdminFilterChipItem(label: 'Suspended', value: 'SUSPENDED'),
              AdminFilterChipItem(label: 'Archived', value: 'ARCHIVED'),
              AdminFilterChipItem(label: 'Rejected', value: 'REJECTED'),
            ],
            selectedValue: _selectedStatus,
            onSelected: (val) {
              setState(() => _selectedStatus = val);
              _fetchAllGroups();
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchAllGroups,
              child: _isLoadingAll && _allGroups.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _allGroupsError != null && _allGroups.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 12),
                            Consumer(
                              builder: (context, ref, child) => Text(
                                ref.watch(trProvider)('common.error'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _allGroupsError!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _fetchAllGroups,
                              icon: const Icon(Icons.refresh),
                              label: Consumer(
                                builder: (context, ref, child) =>
                                    Text(ref.watch(trProvider)('common.retry')),
                              ),
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
                            backgroundColor: g.status == 'ACTIVE'
                                ? Colors.teal.shade100
                                : g.status == 'PENDING_APPROVAL'
                                ? Colors.amber.shade100
                                : Colors.grey.shade200,
                            child: Text(
                              g.name.isNotEmpty ? g.name[0].toUpperCase() : 'G',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: g.status == 'ACTIVE'
                                    ? Colors.teal.shade800
                                    : g.status == 'PENDING_APPROVAL'
                                    ? Colors.amber.shade900
                                    : Colors.grey.shade800,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  g.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AdminStatusBadge(status: g.status),
                            ],
                          ),
                          subtitle: Text(
                            '${g.slug != null || g.handle != null ? '@${g.slug ?? g.handle} • ' : ''}'
                            '${g.memberCount} members'
                            '${g.creatorUsername != null ? ' • by @${g.creatorUsername}' : ''}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'APPROVE') {
                                _handleApproveGroup(g);
                              } else if (val == 'REJECT') {
                                _handleRejectGroup(g);
                              } else if (val == 'SUSPEND') {
                                _handleSuspendGroup(g);
                              } else if (val == 'RESTORE') {
                                _handleRestoreGroup(g);
                              } else if (val == 'DELETE') {
                                _handleDeleteGroup(g);
                              } else if (val == 'DETAILS') {
                                _showGroupDetails(g);
                              }
                            },
                            itemBuilder: (ctx) => [
                              if (g.status == 'PENDING_APPROVAL') ...[
                                const PopupMenuItem(
                                  value: 'APPROVE',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Approve Group'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'REJECT',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Reject Group'),
                                    ],
                                  ),
                                ),
                              ],
                              if (g.status == 'ACTIVE')
                                const PopupMenuItem(
                                  value: 'SUSPEND',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.pause_circle_outline,
                                        color: Colors.orange,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Suspend Group'),
                                    ],
                                  ),
                                ),
                              if (g.status != 'ACTIVE' &&
                                  g.status != 'PENDING_APPROVAL')
                                const PopupMenuItem(
                                  value: 'RESTORE',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.restore_rounded,
                                        color: Colors.blue,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Restore to Active'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'DETAILS',
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'DELETE',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete Group',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
