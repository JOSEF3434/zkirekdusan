// lib/features/admin/presentation/screens/admin_users_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_search_bar.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_filter_chips.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_status_badge.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_confirmation_dialog.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final List<AdminUserItemDto> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _page = 1;
  bool _hasNext = false;
  String _search = '';
  String _selectedStatus = 'ALL';
  String _selectedRole = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchUsers(reset: true);
  }

  Future<void> _fetchUsers({bool reset = false}) async {
    if (_isLoading) return;
    if (reset) {
      setState(() {
        _page = 1;
        _users.clear();
        _isLoading = true;
      });
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.getUsers(
        page: _page,
        limit: 20,
        search: _search,
        status: _selectedStatus,
        role: _selectedRole,
      );

      final rawItems = res['items'];
      final List<AdminUserItemDto> newItems = rawItems is List<AdminUserItemDto>
          ? rawItems
          : ((rawItems as List?) ?? []).whereType<AdminUserItemDto>().toList();
      final hasNext = res['hasNext'] as bool? ?? false;

      setState(() {
        if (reset) {
          _users.clear();
        }
        _users.addAll(newItems);
        _hasNext = hasNext;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _handleUserAction(AdminUserItemDto user, String action) async {
    final tr = ref.read(trProvider);
    final repo = ref.read(adminRepositoryProvider);

    String title = '';
    String message = '';
    Color color = Colors.red;
    bool requireReason = false;

    if (action == 'BAN') {
      title = tr('admin.confirm.ban_title');
      message = 'Ban user @${user.username ?? user.id}? They will be completely restricted.';
      color = Colors.red;
      requireReason = true;
    } else if (action == 'SUSPEND') {
      title = 'Suspend Account';
      message = 'Temporarily suspend user @${user.username ?? user.id}?';
      color = Colors.orange;
      requireReason = true;
    } else if (action == 'DEACTIVATE') {
      title = 'Deactivate Account';
      message = 'Deactivate user @${user.username ?? user.id}?';
      color = Colors.blueGrey;
    } else if (action == 'ACTIVATE') {
      title = 'Reactivate Account';
      message = 'Reactivate user @${user.username ?? user.id}?';
      color = Colors.green;
    }

    final reason = await AdminConfirmationDialog.show(
      context,
      title: title,
      message: message,
      confirmColor: color,
      requireReason: requireReason,
    );

    if (reason == null && requireReason) return;

    bool ok = false;
    if (action == 'BAN') {
      ok = await repo.banUser(user.id, reason: reason);
    } else if (action == 'SUSPEND') {
      ok = await repo.updateUserStatus(user.id, 'SUSPENDED', reason: reason);
    } else if (action == 'DEACTIVATE') {
      ok = await repo.deactivateUser(user.id, reason: reason);
    } else if (action == 'ACTIVATE') {
      ok = await repo.activateUser(user.id);
    }

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action $action applied successfully')),
      );
      _fetchUsers(reset: true);
    }
  }

  Future<void> _handleChangeRole(AdminUserItemDto user) async {
    final perms = ref.read(adminPermissionsProvider);
    if (!perms.canManageRoles) return;

    final roles = perms.isSuperAdmin
        ? ['SUPER_ADMIN', 'ADMIN', 'MODERATOR', 'SUPPORT', 'USER']
        : ['MODERATOR', 'SUPPORT', 'USER'];

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Assign Role to @${user.username ?? user.id}'),
        children: roles
            .map(
              (r) => SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(r),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r),
                      if (user.role == r) const Icon(Icons.check, color: Colors.green),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );

    if (selected != null && selected != user.role) {
      final ok = await ref.read(adminRepositoryProvider).assignUserRole(user.id, selected);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role updated to $selected')),
        );
        _fetchUsers(reset: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final perms = ref.watch(adminPermissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.users')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchUsers(reset: true),
          ),
        ],
      ),
      body: AdminResponsiveLayout(
        child: Column(
          children: [
            AdminSearchBar(
              hintText: 'Search by username or email...',
              onSearch: (val) {
                _search = val;
                _fetchUsers(reset: true);
              },
            ),
            const SizedBox(height: 12),
            AdminFilterChips(
              filters: const [
                AdminFilterChipItem(label: 'All Status', value: 'ALL'),
                AdminFilterChipItem(label: 'Active', value: 'ACTIVE'),
                AdminFilterChipItem(label: 'Suspended', value: 'SUSPENDED'),
                AdminFilterChipItem(label: 'Banned', value: 'BANNED'),
                AdminFilterChipItem(label: 'Inactive', value: 'INACTIVE'),
              ],
              selectedValue: _selectedStatus,
              onSelected: (val) {
                setState(() => _selectedStatus = val);
                _fetchUsers(reset: true);
              },
            ),
            const SizedBox(height: 8),
            AdminFilterChips(
              filters: const [
                AdminFilterChipItem(label: 'All Roles', value: 'ALL'),
                AdminFilterChipItem(label: 'Super Admin', value: 'SUPER_ADMIN'),
                AdminFilterChipItem(label: 'Admin', value: 'ADMIN'),
                AdminFilterChipItem(label: 'Moderator', value: 'MODERATOR'),
                AdminFilterChipItem(label: 'Support', value: 'SUPPORT'),
                AdminFilterChipItem(label: 'User', value: 'USER'),
              ],
              selectedValue: _selectedRole,
              onSelected: (val) {
                setState(() => _selectedRole = val);
                _fetchUsers(reset: true);
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetchUsers(reset: true),
                child: _isLoading && _users.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null && _users.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Failed to load users',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () => _fetchUsers(reset: true),
                                    icon: const Icon(Icons.refresh),
                                    label: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('common.retry'))),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _users.isEmpty
                            ? Center(child: Text(tr('admin.no_records')))
                            : ListView.separated(
                        itemCount: _users.length + (_hasNext ? 1 : 0),
                        separatorBuilder: (_, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index == _users.length) {
                            if (!_isLoading) {
                              _page++;
                              _fetchUsers();
                            }
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final user = _users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: user.avatarUrl == null
                                  ? Text((user.username ?? 'U').substring(0, 1).toUpperCase())
                                  : null,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.displayName ?? user.username ?? 'User',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                AdminStatusBadge(status: user.role),
                                const SizedBox(width: 4),
                                AdminStatusBadge(status: user.status),
                              ],
                            ),
                            subtitle: Text(
                              '@${user.username ?? user.id} ${user.email != null ? '• ${user.email}' : ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'ROLE') {
                                  _handleChangeRole(user);
                                } else {
                                  _handleUserAction(user, val);
                                }
                              },
                              itemBuilder: (ctx) => [
                                if (perms.canManageRoles)
                                  const PopupMenuItem(
                                    value: 'ROLE',
                                    child: Row(
                                      children: [
                                        Icon(Icons.shield_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Change Role'),
                                      ],
                                    ),
                                  ),
                                if (user.status != 'ACTIVE')
                                  const PopupMenuItem(
                                    value: 'ACTIVATE',
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                                        SizedBox(width: 8),
                                        Text('Activate'),
                                      ],
                                    ),
                                  ),
                                if (user.status == 'ACTIVE')
                                  const PopupMenuItem(
                                    value: 'SUSPEND',
                                    child: Row(
                                      children: [
                                        Icon(Icons.pause_circle_outline, color: Colors.orange, size: 18),
                                        SizedBox(width: 8),
                                        Text('Suspend'),
                                      ],
                                    ),
                                  ),
                                if (user.status != 'BANNED')
                                  const PopupMenuItem(
                                    value: 'BAN',
                                    child: Row(
                                      children: [
                                        Icon(Icons.block, color: Colors.red, size: 18),
                                        SizedBox(width: 8),
                                        Text('Ban User'),
                                      ],
                                    ),
                                  ),
                                if (user.status != 'INACTIVE')
                                  const PopupMenuItem(
                                    value: 'DEACTIVATE',
                                    child: Row(
                                      children: [
                                        Icon(Icons.cancel_outlined, color: Colors.grey, size: 18),
                                        SizedBox(width: 8),
                                        Text('Deactivate'),
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
            if (_isLoading && _users.isNotEmpty)
              const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

