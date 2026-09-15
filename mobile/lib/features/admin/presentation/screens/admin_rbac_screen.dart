// lib/features/admin/presentation/screens/admin_rbac_screen.dart
//
// Full Role-Based Access Control (RBAC) Management Screen.
// Allows Super Admins (and Admins) to view and toggle every platform-level
// permission for each role, with audit-safe confirmation dialogs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';


// ─────────────────────────────────────────────
// Domain models
// ─────────────────────────────────────────────

/// One specific permission that can be granted/revoked per role.
class RbacPermission {
  final String key;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final String category;

  const RbacPermission({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
  });
}

/// A platform role with its current permission map.
class RbacRole {
  final String name;
  final Color color;
  final IconData icon;
  final String description;
  final bool isEditable; // Super Admin itself is never editable
  final Map<String, bool> permissions;

  const RbacRole({
    required this.name,
    required this.color,
    required this.icon,
    required this.description,
    required this.isEditable,
    required this.permissions,
  });

  RbacRole copyWith({Map<String, bool>? permissions}) => RbacRole(
        name: name,
        color: color,
        icon: icon,
        description: description,
        isEditable: isEditable,
        permissions: permissions ?? this.permissions,
      );
}

// ─────────────────────────────────────────────
// Static catalogue of all permissions
// ─────────────────────────────────────────────

const List<RbacPermission> _allPermissions = [
  // ── User Management ──
  RbacPermission(
    key: 'users.read',
    label: 'View Users',
    description: 'List and search platform users',
    icon: Icons.person_search_rounded,
    color: Color(0xFF2196F3),
    category: 'User Management',
  ),
  RbacPermission(
    key: 'users.update',
    label: 'Edit Users',
    description: 'Update user profile and metadata',
    icon: Icons.edit_rounded,
    color: Color(0xFF2196F3),
    category: 'User Management',
  ),
  RbacPermission(
    key: 'users.ban',
    label: 'Ban Users',
    description: 'Permanently ban a user from the platform',
    icon: Icons.block_rounded,
    color: Color(0xFFE53935),
    category: 'User Management',
  ),
  RbacPermission(
    key: 'users.suspend',
    label: 'Suspend Users',
    description: 'Temporarily suspend user accounts',
    icon: Icons.pause_circle_rounded,
    color: Color(0xFFFF9800),
    category: 'User Management',
  ),
  RbacPermission(
    key: 'users.activate',
    label: 'Activate Users',
    description: 'Reactivate suspended or deactivated accounts',
    icon: Icons.check_circle_rounded,
    color: Color(0xFF4CAF50),
    category: 'User Management',
  ),
  RbacPermission(
    key: 'users.assign_role',
    label: 'Assign Roles',
    description: 'Change the platform role of any user',
    icon: Icons.manage_accounts_rounded,
    color: Color(0xFF9C27B0),
    category: 'User Management',
  ),
  // ── Groups & Channels ──
  RbacPermission(
    key: 'groups.read',
    label: 'View Groups',
    description: 'List and inspect all groups',
    icon: Icons.groups_rounded,
    color: Color(0xFF673AB7),
    category: 'Groups & Channels',
  ),
  RbacPermission(
    key: 'groups.approve',
    label: 'Approve Groups',
    description: 'Approve pending group creation requests',
    icon: Icons.thumb_up_rounded,
    color: Color(0xFF4CAF50),
    category: 'Groups & Channels',
  ),
  RbacPermission(
    key: 'groups.suspend',
    label: 'Suspend Groups',
    description: 'Temporarily suspend a group',
    icon: Icons.pause_circle_outline_rounded,
    color: Color(0xFFFF9800),
    category: 'Groups & Channels',
  ),
  RbacPermission(
    key: 'groups.delete',
    label: 'Delete Groups',
    description: 'Permanently delete groups and their content',
    icon: Icons.delete_forever_rounded,
    color: Color(0xFFE53935),
    category: 'Groups & Channels',
  ),
  RbacPermission(
    key: 'channels.read',
    label: 'View Channels',
    description: 'List and inspect group channels',
    icon: Icons.tag_rounded,
    color: Color(0xFF3F51B5),
    category: 'Groups & Channels',
  ),
  RbacPermission(
    key: 'channels.delete',
    label: 'Delete Channels',
    description: 'Delete specific group channels',
    icon: Icons.delete_outline_rounded,
    color: Color(0xFFE53935),
    category: 'Groups & Channels',
  ),
  // ── Content Moderation ──
  RbacPermission(
    key: 'content.read',
    label: 'View Content',
    description: 'View posts, videos and reels for moderation',
    icon: Icons.article_rounded,
    color: Color(0xFF009688),
    category: 'Content Moderation',
  ),
  RbacPermission(
    key: 'content.update_status',
    label: 'Update Content Status',
    description: 'Feature, pin, or change content visibility',
    icon: Icons.edit_note_rounded,
    color: Color(0xFF00BCD4),
    category: 'Content Moderation',
  ),
  RbacPermission(
    key: 'content.delete',
    label: 'Delete Content',
    description: 'Remove posts, videos and reels',
    icon: Icons.delete_rounded,
    color: Color(0xFFE53935),
    category: 'Content Moderation',
  ),
  RbacPermission(
    key: 'reports.read',
    label: 'View Reports',
    description: 'See all user-submitted reports',
    icon: Icons.flag_rounded,
    color: Color(0xFFFF9800),
    category: 'Content Moderation',
  ),
  RbacPermission(
    key: 'reports.resolve',
    label: 'Resolve Reports',
    description: 'Mark reports as resolved or dismissed',
    icon: Icons.verified_rounded,
    color: Color(0xFF4CAF50),
    category: 'Content Moderation',
  ),
  // ── Live & Chat ──
  RbacPermission(
    key: 'live.read',
    label: 'View Live Streams',
    description: 'Monitor active and past live streams',
    icon: Icons.live_tv_rounded,
    color: Color(0xFFE53935),
    category: 'Live & Chat',
  ),
  RbacPermission(
    key: 'live.terminate',
    label: 'Terminate Streams',
    description: 'Force-end any active live stream',
    icon: Icons.stop_circle_rounded,
    color: Color(0xFFE53935),
    category: 'Live & Chat',
  ),
  RbacPermission(
    key: 'chat.read',
    label: 'View Chats',
    description: 'Inspect conversations for moderation',
    icon: Icons.chat_bubble_rounded,
    color: Color(0xFF2196F3),
    category: 'Live & Chat',
  ),
  RbacPermission(
    key: 'chat.delete_message',
    label: 'Delete Messages',
    description: 'Remove individual chat messages',
    icon: Icons.remove_circle_rounded,
    color: Color(0xFFFF5722),
    category: 'Live & Chat',
  ),
  RbacPermission(
    key: 'chat.purge',
    label: 'Purge Conversations',
    description: 'Delete all messages in a conversation',
    icon: Icons.cleaning_services_rounded,
    color: Color(0xFFE53935),
    category: 'Live & Chat',
  ),
  // ── Platform Operations ──
  RbacPermission(
    key: 'storage.read',
    label: 'View Storage',
    description: 'Inspect platform storage statistics',
    icon: Icons.cloud_queue_rounded,
    color: Color(0xFF00BCD4),
    category: 'Platform Operations',
  ),
  RbacPermission(
    key: 'storage.cleanup',
    label: 'Cleanup Storage',
    description: 'Run orphan file cleanup tasks',
    icon: Icons.delete_sweep_rounded,
    color: Color(0xFFFF9800),
    category: 'Platform Operations',
  ),
  RbacPermission(
    key: 'notifications.broadcast',
    label: 'Broadcast Notifications',
    description: 'Send platform-wide push notifications',
    icon: Icons.campaign_rounded,
    color: Color(0xFFFF5722),
    category: 'Platform Operations',
  ),
  RbacPermission(
    key: 'audit.read',
    label: 'View Audit Logs',
    description: 'Read the platform admin audit trail',
    icon: Icons.history_rounded,
    color: Color(0xFF607D8B),
    category: 'Platform Operations',
  ),
  RbacPermission(
    key: 'system.settings',
    label: 'System Settings',
    description: 'Manage platform-level configuration',
    icon: Icons.settings_applications_rounded,
    color: Color(0xFF795548),
    category: 'Platform Operations',
  ),
  RbacPermission(
    key: 'rbac.manage',
    label: 'Manage RBAC',
    description: 'Edit role permissions (this screen)',
    icon: Icons.key_rounded,
    color: Color(0xFF9C27B0),
    category: 'Platform Operations',
  ),
];

// Default permission sets per role (mirrors backend defaults)
Map<String, bool> _defaultPermsFor(String roleName) {
  const all = true;
  const no = false;
  switch (roleName) {
    case 'SUPER_ADMIN':
      return {for (final p in _allPermissions) p.key: all};
    case 'ADMIN':
      return {
        'users.read': all,
        'users.update': all,
        'users.ban': all,
        'users.suspend': all,
        'users.activate': all,
        'users.assign_role': all,
        'groups.read': all,
        'groups.approve': all,
        'groups.suspend': all,
        'groups.delete': all,
        'channels.read': all,
        'channels.delete': all,
        'content.read': all,
        'content.update_status': all,
        'content.delete': all,
        'reports.read': all,
        'reports.resolve': all,
        'live.read': all,
        'live.terminate': all,
        'chat.read': all,
        'chat.delete_message': all,
        'chat.purge': all,
        'storage.read': all,
        'storage.cleanup': all,
        'notifications.broadcast': all,
        'audit.read': all,
        'system.settings': no,
        'rbac.manage': no,
      };
    case 'MODERATOR':
      return {
        'users.read': all,
        'users.update': no,
        'users.ban': no,
        'users.suspend': all,
        'users.activate': all,
        'users.assign_role': no,
        'groups.read': all,
        'groups.approve': all,
        'groups.suspend': all,
        'groups.delete': no,
        'channels.read': all,
        'channels.delete': no,
        'content.read': all,
        'content.update_status': all,
        'content.delete': all,
        'reports.read': all,
        'reports.resolve': all,
        'live.read': all,
        'live.terminate': all,
        'chat.read': all,
        'chat.delete_message': all,
        'chat.purge': no,
        'storage.read': no,
        'storage.cleanup': no,
        'notifications.broadcast': no,
        'audit.read': no,
        'system.settings': no,
        'rbac.manage': no,
      };
    case 'SUPPORT':
      return {
        'users.read': all,
        'users.update': all,
        'users.ban': no,
        'users.suspend': no,
        'users.activate': all,
        'users.assign_role': no,
        'groups.read': all,
        'groups.approve': no,
        'groups.suspend': no,
        'groups.delete': no,
        'channels.read': all,
        'channels.delete': no,
        'content.read': all,
        'content.update_status': no,
        'content.delete': no,
        'reports.read': all,
        'reports.resolve': all,
        'live.read': all,
        'live.terminate': no,
        'chat.read': all,
        'chat.delete_message': no,
        'chat.purge': no,
        'storage.read': no,
        'storage.cleanup': no,
        'notifications.broadcast': no,
        'audit.read': no,
        'system.settings': no,
        'rbac.manage': no,
      };
    default: // USER
      return {for (final p in _allPermissions) p.key: false};
  }
}

List<RbacRole> _buildDefaultRoles() => [
      RbacRole(
        name: 'SUPER_ADMIN',
        color: const Color(0xFFE53935),
        icon: Icons.military_tech_rounded,
        description: 'Full platform authority. Cannot be restricted.',
        isEditable: false,
        permissions: _defaultPermsFor('SUPER_ADMIN'),
      ),
      RbacRole(
        name: 'ADMIN',
        color: Colors.indigo,
        icon: Icons.admin_panel_settings_rounded,
        description: 'Platform administrator with broad operational access.',
        isEditable: true,
        permissions: _defaultPermsFor('ADMIN'),
      ),
      RbacRole(
        name: 'MODERATOR',
        color: const Color(0xFFF57C00),
        icon: Icons.gavel_rounded,
        description: 'Trust & Safety moderator. Content and community focus.',
        isEditable: true,
        permissions: _defaultPermsFor('MODERATOR'),
      ),
      RbacRole(
        name: 'SUPPORT',
        color: Colors.teal,
        icon: Icons.support_agent_rounded,
        description: 'Customer & user operations. Account support.',
        isEditable: true,
        permissions: _defaultPermsFor('SUPPORT'),
      ),
      RbacRole(
        name: 'USER',
        color: Colors.blueGrey,
        icon: Icons.person_outline_rounded,
        description: 'Standard registered user. No admin permissions.',
        isEditable: false,
        permissions: _defaultPermsFor('USER'),
      ),
    ];

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────

class RbacState {
  final List<RbacRole> roles;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final Set<String> pendingChanges; // role names with unsaved changes

  const RbacState({
    required this.roles,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.pendingChanges = const {},
  });

  RbacState copyWith({
    List<RbacRole>? roles,
    bool? isLoading,
    bool? isSaving,
    String? error,
    Set<String>? pendingChanges,
  }) =>
      RbacState(
        roles: roles ?? this.roles,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: error,
        pendingChanges: pendingChanges ?? this.pendingChanges,
      );
}

class RbacNotifier extends StateNotifier<RbacState> {
  final AdminRepository _repo;

  RbacNotifier(this._repo)
      : super(RbacState(roles: _buildDefaultRoles(), isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final serverRoles = await _repo.getRbacRoles();
      if (serverRoles != null && serverRoles.isNotEmpty) {
        final merged = _buildDefaultRoles().map((localRole) {
          final serverPerms = serverRoles[localRole.name];
          if (serverPerms != null) {
            return localRole.copyWith(permissions: {
              ...localRole.permissions,
              ...serverPerms,
            });
          }
          return localRole;
        }).toList();
        state = state.copyWith(roles: merged, isLoading: false, error: null);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      // Gracefully fall back to defaults
      state = state.copyWith(isLoading: false);
    }
  }

  void togglePermission(String roleName, String permKey, bool value) {
    final updated = state.roles.map((r) {
      if (r.name != roleName || !r.isEditable) return r;
      final newPerms = Map<String, bool>.from(r.permissions)..[permKey] = value;
      return r.copyWith(permissions: newPerms);
    }).toList();
    final pending = Set<String>.from(state.pendingChanges)..add(roleName);
    state = state.copyWith(roles: updated, pendingChanges: pending);
  }

  Future<bool> saveRole(String roleName) async {
    final role = state.roles.firstWhere((r) => r.name == roleName);
    state = state.copyWith(isSaving: true);
    try {
      final ok = await _repo.updateRbacRolePermissions(
          roleName, role.permissions);
      final pending = Set<String>.from(state.pendingChanges)..remove(roleName);
      state = state.copyWith(isSaving: false, pendingChanges: pending);
      return ok;
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  void resetRole(String roleName) {
    final defaultPerms = _defaultPermsFor(roleName);
    final updated = state.roles.map((r) {
      if (r.name != roleName) return r;
      return r.copyWith(permissions: defaultPerms);
    }).toList();
    final pending = Set<String>.from(state.pendingChanges)..remove(roleName);
    state = state.copyWith(roles: updated, pendingChanges: pending);
  }
}

final rbacProvider =
    StateNotifierProvider<RbacNotifier, RbacState>((ref) {
  return RbacNotifier(ref.watch(adminRepositoryProvider));
});

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────

class AdminRbacScreen extends ConsumerStatefulWidget {
  const AdminRbacScreen({super.key});

  @override
  ConsumerState<AdminRbacScreen> createState() => _AdminRbacScreenState();
}

class _AdminRbacScreenState extends ConsumerState<AdminRbacScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _roleOrder = [
    'SUPER_ADMIN',
    'ADMIN',
    'MODERATOR',
    'SUPPORT',
    'USER',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _roleOrder.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rbacState = ref.watch(rbacProvider);
    final perms = ref.watch(adminPermissionsProvider);
    final canEdit = perms.isSuperAdmin || perms.isAdmin;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0E1621) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.key_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('RBAC Management'),
          ],
        ),
        backgroundColor:
            isDark ? const Color(0xFF0E1621) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: rbacState.isLoading
              ? const LinearProgressIndicator()
              : TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: rbacState.roles.map((role) {
                    final hasPending =
                        rbacState.pendingChanges.contains(role.name);
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(role.icon, size: 14, color: role.color),
                          const SizedBox(width: 6),
                          Text(
                            _shortName(role.name),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: role.color,
                            ),
                          ),
                          if (hasPending) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF9800),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        actions: [
          if (!rbacState.isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reload from server',
              onPressed: () => ref.invalidate(rbacProvider),
            ),
        ],
      ),
      body: rbacState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: rbacState.roles
                  .map((role) => _RolePermissionsTab(
                        role: role,
                        canEdit: canEdit && role.isEditable,
                        hasPendingChanges:
                            rbacState.pendingChanges.contains(role.name),
                        isSaving: rbacState.isSaving,
                        onToggle: (permKey, value) => ref
                            .read(rbacProvider.notifier)
                            .togglePermission(role.name, permKey, value),
                        onSave: () => _onSave(role.name),
                        onReset: () => _onReset(role.name),
                      ))
                  .toList(),
            ),
    );
  }

  String _shortName(String name) {
    switch (name) {
      case 'SUPER_ADMIN':
        return 'Super Admin';
      case 'ADMIN':
        return 'Admin';
      case 'MODERATOR':
        return 'Moderator';
      case 'SUPPORT':
        return 'Support';
      default:
        return 'User';
    }
  }

  Future<void> _onSave(String roleName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.save_rounded, color: Color(0xFF9C27B0), size: 32),
        title: const Text('Save Permission Changes'),
        content: Text(
          'You are about to apply the updated permission set for the $roleName role.\n\n'
          'This change will take effect immediately for all users with this role.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(rbacProvider.notifier).saveRole(roleName);
    if (!mounted) return;

    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? 'Permissions for $roleName saved successfully.'
          : 'Failed to save. Please retry.'),
      backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
    ));
  }

  Future<void> _onReset(String roleName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.restore_rounded,
            color: Colors.orange, size: 32),
        title: const Text('Reset to Defaults'),
        content: Text(
          'This will reset the permission set for the $roleName role to '
          'the platform defaults.\n\nYour unsaved edits will be discarded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(rbacProvider.notifier).resetRole(roleName);
    }
  }
}

// ─────────────────────────────────────────────
// Per-Role Tab Content
// ─────────────────────────────────────────────

class _RolePermissionsTab extends StatelessWidget {
  final RbacRole role;
  final bool canEdit;
  final bool hasPendingChanges;
  final bool isSaving;
  final void Function(String permKey, bool value) onToggle;
  final VoidCallback onSave;
  final VoidCallback onReset;

  const _RolePermissionsTab({
    required this.role,
    required this.canEdit,
    required this.hasPendingChanges,
    required this.isSaving,
    required this.onToggle,
    required this.onSave,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Group permissions by category
    final grouped = <String, List<RbacPermission>>{};
    for (final p in _allPermissions) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }

    final grantedCount =
        role.permissions.values.where((v) => v).length;
    final totalCount = _allPermissions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: AdminResponsiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Role header card ──
            _RoleHeaderCard(
              role: role,
              grantedCount: grantedCount,
              totalCount: totalCount,
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            // ── Read-only notice for non-editable roles ──
            if (!role.isEditable)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        role.name == 'SUPER_ADMIN'
                            ? 'Super Admin has all permissions by design. This role cannot be restricted.'
                            : 'Standard users have no admin permissions. This role is read-only.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.amber.shade200
                              : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (!role.isEditable) const SizedBox(height: 16),

            // ── Permission categories ──
            ...grouped.entries.map((entry) => _PermissionCategoryCard(
                  category: entry.key,
                  permissions: entry.value,
                  role: role,
                  canEdit: canEdit,
                  onToggle: onToggle,
                  isDark: isDark,
                )),

            // ── Action buttons ──
            if (canEdit) ...[
              const SizedBox(height: 8),
              _ActionBar(
                hasPendingChanges: hasPendingChanges,
                isSaving: isSaving,
                roleName: role.name,
                onSave: onSave,
                onReset: onReset,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Role Header Card
// ─────────────────────────────────────────────

class _RoleHeaderCard extends StatelessWidget {
  final RbacRole role;
  final int grantedCount;
  final int totalCount;
  final bool isDark;

  const _RoleHeaderCard({
    required this.role,
    required this.grantedCount,
    required this.totalCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = totalCount == 0 ? 0.0 : grantedCount / totalCount;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            role.color.withValues(alpha: 0.85),
            role.color.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: role.color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(role.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$grantedCount/$totalCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'permissions',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(fraction * 100).toStringAsFixed(0)}% of platform permissions granted',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Permission Category Card
// ─────────────────────────────────────────────

class _PermissionCategoryCard extends StatelessWidget {
  final String category;
  final List<RbacPermission> permissions;
  final RbacRole role;
  final bool canEdit;
  final void Function(String permKey, bool value) onToggle;
  final bool isDark;

  const _PermissionCategoryCard({
    required this.category,
    required this.permissions,
    required this.role,
    required this.canEdit,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor =
        isDark ? theme.colorScheme.surfaceContainer : Colors.white;

    final grantedInCategory =
        permissions.where((p) => role.permissions[p.key] == true).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.withValues(alpha: 0.06),
              ),
              child: Row(
                children: [
                  Text(
                    category,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: grantedInCategory == permissions.length
                          ? Colors.green.withValues(alpha: 0.15)
                          : grantedInCategory == 0
                              ? Colors.red.withValues(alpha: 0.12)
                              : Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$grantedInCategory / ${permissions.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: grantedInCategory == permissions.length
                            ? Colors.green.shade700
                            : grantedInCategory == 0
                                ? Colors.red.shade700
                                : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Permission rows
            ...permissions.asMap().entries.map((entry) {
              final idx = entry.key;
              final perm = entry.value;
              final granted = role.permissions[perm.key] ?? false;
              return Column(
                children: [
                  _PermissionRow(
                    permission: perm,
                    granted: granted,
                    canEdit: canEdit,
                    isDark: isDark,
                    onToggle: (val) => onToggle(perm.key, val),
                  ),
                  if (idx < permissions.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Single Permission Row
// ─────────────────────────────────────────────

class _PermissionRow extends StatelessWidget {
  final RbacPermission permission;
  final bool granted;
  final bool canEdit;
  final bool isDark;
  final ValueChanged<bool> onToggle;

  const _PermissionRow({
    required this.permission,
    required this.granted,
    required this.canEdit,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: granted
                  ? permission.color.withValues(alpha: 0.15)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              permission.icon,
              size: 18,
              color: granted
                  ? permission.color
                  : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
            ),
          ),
          const SizedBox(width: 12),
          // Label & description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permission.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: granted
                        ? null
                        : (isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  permission.description,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? Colors.grey.shade500
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Toggle / badge
          if (canEdit)
            Switch(
              value: granted,
              onChanged: onToggle,
              activeThumbColor: Colors.white,
              activeTrackColor: permission.color,
              thumbIcon: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Icon(Icons.check, size: 14, color: permission.color);
                }
                return const Icon(Icons.close, size: 14, color: Colors.grey);
              }),
            )
          else
            _StatusChip(granted: granted),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool granted;
  const _StatusChip({required this.granted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: granted
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: granted
              ? Colors.green.withValues(alpha: 0.35)
              : Colors.red.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        granted ? 'Granted' : 'Denied',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: granted ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Action Bar (Save / Reset)
// ─────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final bool hasPendingChanges;
  final bool isSaving;
  final String roleName;
  final VoidCallback onSave;
  final VoidCallback onReset;

  const _ActionBar({
    required this.hasPendingChanges,
    required this.isSaving,
    required this.roleName,
    required this.onSave,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: hasPendingChanges ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 250),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasPendingChanges
                ? [
                    const Color(0xFF9C27B0).withValues(alpha: 0.12),
                    const Color(0xFF673AB7).withValues(alpha: 0.06),
                  ]
                : [Colors.transparent, Colors.transparent],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasPendingChanges
                ? const Color(0xFF9C27B0).withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            if (hasPendingChanges)
              const Row(
                children: [
                  Icon(Icons.edit_rounded,
                      color: Color(0xFFFF9800), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Unsaved changes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                ],
              ),
            const Spacer(),
            TextButton.icon(
              onPressed: hasPendingChanges ? onReset : null,
              icon: const Icon(Icons.restore_rounded, size: 16),
              label: const Text('Reset'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0)),
              onPressed: hasPendingChanges && !isSaving ? onSave : null,
              icon: isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(isSaving ? 'Saving…' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
