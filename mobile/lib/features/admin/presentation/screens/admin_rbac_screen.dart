// lib/features/admin/presentation/screens/admin_rbac_screen.dart
//
// RBAC Management Screen — fully database-driven.
// Loads the permission catalogue and role assignments from the backend.
// All toggles are saved back to the DB via PUT /admin/rbac/roles/:name/permissions.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';

// ─────────────────────────────────────────────
// Local domain models
// ─────────────────────────────────────────────

/// One permission entry displayed in a row, sourced from the backend catalogue.
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

  /// Build from backend metadata. Icon and color are derived client-side.
  factory RbacPermission.fromMeta(RbacPermissionMeta meta) {
    return RbacPermission(
      key: meta.code,
      label: meta.displayName,
      description: meta.description,
      icon: _iconForCode(meta.code),
      color: _colorForRisk(meta.riskLevel),
      category: meta.category,
    );
  }
}

/// A platform role with its granted permission map.
class RbacRole {
  final String name;
  final Color color;
  final IconData icon;
  final String description;
  final bool isEditable;
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
// Helper mappings (icon / colour by code/risk)
// ─────────────────────────────────────────────

IconData _iconForCode(String code) {
  if (code.startsWith('users.')) {
    if (code.contains('ban')) return Icons.block_rounded;
    if (code.contains('suspend')) return Icons.pause_circle_rounded;
    if (code.contains('delete')) return Icons.delete_forever_rounded;
    if (code.contains('reset')) return Icons.lock_reset_rounded;
    if (code.contains('create')) return Icons.person_add_rounded;
    if (code.contains('update')) return Icons.edit_rounded;
    return Icons.person_search_rounded;
  }
  if (code.startsWith('roles.')) {
    if (code.contains('assign')) return Icons.manage_accounts_rounded;
    if (code.contains('update')) return Icons.key_rounded;
    return Icons.shield_rounded;
  }
  if (code.startsWith('groups.')) {
    if (code.contains('approve')) return Icons.thumb_up_rounded;
    if (code.contains('suspend')) return Icons.pause_circle_outline_rounded;
    if (code.contains('delete')) return Icons.delete_forever_rounded;
    if (code.contains('member')) return Icons.group_remove_rounded;
    if (code.contains('create')) return Icons.group_add_rounded;
    return Icons.groups_rounded;
  }
  if (code.startsWith('channels.')) {
    if (code.contains('delete')) return Icons.delete_outline_rounded;
    if (code.contains('member')) return Icons.group_remove_rounded;
    return Icons.tag_rounded;
  }
  if (code.startsWith('media.') || code.startsWith('videos.')) {
    if (code.contains('delete')) return Icons.delete_rounded;
    if (code.contains('moderate')) return Icons.gavel_rounded;
    if (code.contains('upload')) return Icons.upload_rounded;
    return Icons.article_rounded;
  }
  if (code.startsWith('reports.') || code.startsWith('spam.')) {
    if (code.contains('block')) return Icons.block_rounded;
    if (code.contains('resolve') || code.contains('dismiss')) return Icons.verified_rounded;
    return Icons.flag_rounded;
  }
  if (code.startsWith('chat.')) {
    if (code.contains('delete')) return Icons.remove_circle_rounded;
    return Icons.chat_bubble_rounded;
  }
  if (code.startsWith('live.')) {
    if (code.contains('stop')) return Icons.stop_circle_rounded;
    if (code.contains('moderate')) return Icons.gavel_rounded;
    return Icons.live_tv_rounded;
  }
  if (code.startsWith('notifications.')) return Icons.campaign_rounded;
  if (code.startsWith('system.')) return Icons.settings_applications_rounded;
  if (code.startsWith('audit.')) return Icons.history_rounded;
  if (code.startsWith('storage.')) return Icons.cloud_queue_rounded;
  if (code.startsWith('auth.')) return Icons.lock_rounded;
  if (code.startsWith('books.')) {
    if (code.contains('publish')) return Icons.publish_rounded;
    if (code.contains('delete')) return Icons.delete_rounded;
    if (code.contains('download')) return Icons.download_rounded;
    if (code.contains('categor')) return Icons.category_rounded;
    return Icons.menu_book_rounded;
  }
  if (code.startsWith('alephat.')) return Icons.translate_rounded;
  if (code.startsWith('profile.')) return Icons.badge_rounded;
  if (code.startsWith('posts.')) return Icons.post_add_rounded;
  if (code.startsWith('comments.')) return Icons.comment_rounded;
  if (code.startsWith('messages.')) return Icons.message_rounded;
  if (code.startsWith('stories.')) return Icons.auto_stories_rounded;
  if (code.startsWith('reels.')) return Icons.video_library_rounded;
  if (code.startsWith('uploads.')) return Icons.upload_file_rounded;
  if (code.startsWith('streams.')) return Icons.stream_rounded;
  if (code.startsWith('analytics.')) return Icons.analytics_rounded;
  return Icons.security_rounded;
}

Color _colorForRisk(String risk) {
  switch (risk) {
    case 'critical':
      return const Color(0xFFE53935);
    case 'high':
      return const Color(0xFFFF9800);
    case 'medium':
      return const Color(0xFF2196F3);
    default:
      return const Color(0xFF4CAF50);
  }
}

RbacRole _roleTemplate(String name) {
  switch (name) {
    case 'SUPER_ADMIN':
      return RbacRole(
        name: name,
        color: const Color(0xFFE53935),
        icon: Icons.military_tech_rounded,
        description: 'Full platform authority. Cannot be restricted.',
        isEditable: false,
        permissions: {},
      );
    case 'ADMIN':
      return RbacRole(
        name: name,
        color: Colors.indigo,
        icon: Icons.admin_panel_settings_rounded,
        description: 'Platform administrator with broad operational access.',
        isEditable: true,
        permissions: {},
      );
    case 'MODERATOR':
      return RbacRole(
        name: name,
        color: const Color(0xFFF57C00),
        icon: Icons.gavel_rounded,
        description: 'Trust & Safety moderator. Content and community focus.',
        isEditable: true,
        permissions: {},
      );
    case 'SUPPORT':
      return RbacRole(
        name: name,
        color: Colors.teal,
        icon: Icons.support_agent_rounded,
        description: 'Customer & user operations. Account support.',
        isEditable: true,
        permissions: {},
      );
    default:
      return RbacRole(
        name: name,
        color: Colors.blueGrey,
        icon: Icons.person_outline_rounded,
        description: 'Standard registered user. No admin permissions.',
        isEditable: false,
        permissions: {},
      );
  }
}

// ─────────────────────────────────────────────
// State & Notifier
// ─────────────────────────────────────────────

class RbacState {
  final List<RbacRole> roles;
  final List<RbacPermission> catalogue; // authoritative list from backend
  final Map<String, List<RbacPermission>> catalogueByCategory;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final Set<String> pendingChanges;

  const RbacState({
    this.roles = const [],
    this.catalogue = const [],
    this.catalogueByCategory = const {},
    this.isLoading = true,
    this.isSaving = false,
    this.error,
    this.pendingChanges = const {},
  });

  RbacState copyWith({
    List<RbacRole>? roles,
    List<RbacPermission>? catalogue,
    Map<String, List<RbacPermission>>? catalogueByCategory,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    Set<String>? pendingChanges,
  }) =>
      RbacState(
        roles: roles ?? this.roles,
        catalogue: catalogue ?? this.catalogue,
        catalogueByCategory: catalogueByCategory ?? this.catalogueByCategory,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : (error ?? this.error),
        pendingChanges: pendingChanges ?? this.pendingChanges,
      );
}

class RbacNotifier extends StateNotifier<RbacState> {
  final AdminRepository _repo;

  RbacNotifier(this._repo) : super(const RbacState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Fetch catalogue and roles in parallel
      final results = await Future.wait([
        _repo.getPermissionCatalogue(),
        _repo.getRbacRoles(),
      ]);

      final catalogueDto = results[0] as RbacPermissionCatalogueDto?;
      final serverRoles = results[1] as Map<String, Map<String, bool>>?;

      // Build local catalogue from backend metadata
      final catalogue = (catalogueDto?.permissions ?? [])
          .map((m) => RbacPermission.fromMeta(m))
          .toList();

      // Group by category (preserve backend order)
      final Map<String, List<RbacPermission>> byCategory = {};
      if (catalogueDto?.categories != null) {
        for (final cat in catalogueDto!.categories) {
          byCategory[cat.category] = cat.permissions
              .map((m) => RbacPermission.fromMeta(m))
              .toList();
        }
      }

      // Build roles: use server permissions only (no local defaults merged)
      const roleOrder = ['SUPER_ADMIN', 'ADMIN', 'MODERATOR', 'SUPPORT', 'USER'];
      final roles = roleOrder.map((name) {
        final template = _roleTemplate(name);
        final serverPerms = serverRoles?[name] ?? {};
        return template.copyWith(permissions: Map<String, bool>.from(serverPerms));
      }).toList();

      state = state.copyWith(
        roles: roles,
        catalogue: catalogue,
        catalogueByCategory: byCategory,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load permissions: $e',
      );
    }
  }

  void reload() => _load();

  void togglePermission(String roleName, String permKey, bool value) {
    final updated = state.roles.map((r) {
      if (r.name != roleName || !r.isEditable) return r;
      final newPerms = Map<String, bool>.from(r.permissions)..[permKey] = value;
      return r.copyWith(permissions: newPerms);
    }).toList();
    final pending = Set<String>.from(state.pendingChanges)..add(roleName);
    state = state.copyWith(roles: updated, pendingChanges: pending);
  }

  void toggleCategory(String roleName, String category, bool grantAll) {
    final permsInCat = state.catalogueByCategory[category] ?? [];
    final updated = state.roles.map((r) {
      if (r.name != roleName || !r.isEditable) return r;
      final newPerms = Map<String, bool>.from(r.permissions);
      for (final p in permsInCat) {
        newPerms[p.key] = grantAll;
      }
      return r.copyWith(permissions: newPerms);
    }).toList();
    final pending = Set<String>.from(state.pendingChanges)..add(roleName);
    state = state.copyWith(roles: updated, pendingChanges: pending);
  }

  Future<bool> saveRole(String roleName) async {
    final role = state.roles.firstWhere((r) => r.name == roleName);
    state = state.copyWith(isSaving: true);
    try {
      final ok = await _repo.updateRbacRolePermissions(roleName, role.permissions);
      if (ok) {
        // Reload from server so UI reflects real DB state
        final serverRoles = await _repo.getRbacRoles();
        if (serverRoles != null) {
          final updated = state.roles.map((r) {
            final sp = serverRoles[r.name];
            if (sp == null) return r;
            return r.copyWith(permissions: Map<String, bool>.from(sp));
          }).toList();
          final pending = Set<String>.from(state.pendingChanges)..remove(roleName);
          state = state.copyWith(
            roles: updated,
            isSaving: false,
            pendingChanges: pending,
          );
          return true;
        }
      }
      state = state.copyWith(isSaving: false);
      return ok;
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  void discardChanges(String roleName) {
    // Reload the specific role from the server
    _reloadRole(roleName);
  }

  Future<void> _reloadRole(String roleName) async {
    try {
      final serverRoles = await _repo.getRbacRoles();
      if (serverRoles == null) return;
      final serverPerms = serverRoles[roleName] ?? {};
      final updated = state.roles.map((r) {
        if (r.name != roleName) return r;
        return r.copyWith(permissions: Map<String, bool>.from(serverPerms));
      }).toList();
      final pending = Set<String>.from(state.pendingChanges)..remove(roleName);
      state = state.copyWith(roles: updated, pendingChanges: pending);
    } catch (_) {}
  }
}

final rbacProvider = StateNotifierProvider<RbacNotifier, RbacState>((ref) {
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
  static const _roleOrder = [
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
              child: const Icon(Icons.key_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Consumer(
              builder: (context, ref, child) =>
                  Text(ref.watch(trProvider)('admin.rbac_management')),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF0E1621) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: rbacState.isLoading
              ? const LinearProgressIndicator()
              : TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: _roleOrder.map((roleName) {
                    final role = rbacState.roles.firstWhere(
                      (r) => r.name == roleName,
                      orElse: () => _roleTemplate(roleName),
                    );
                    final hasPending = rbacState.pendingChanges.contains(roleName);
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(role.icon, size: 14, color: role.color),
                          const SizedBox(width: 6),
                          Text(
                            _shortName(roleName),
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
              onPressed: () => ref.read(rbacProvider.notifier).reload(),
            ),
        ],
      ),
      body: rbacState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rbacState.error != null && rbacState.roles.isEmpty
              ? _ErrorView(
                  message: rbacState.error!,
                  onRetry: () => ref.read(rbacProvider.notifier).reload(),
                )
              : TabBarView(
                  controller: _tabController,
                  children: _roleOrder.map((roleName) {
                    final role = rbacState.roles.firstWhere(
                      (r) => r.name == roleName,
                      orElse: () => _roleTemplate(roleName),
                    );
                    return _RolePermissionsTab(
                      role: role,
                      catalogue: rbacState.catalogue,
                      catalogueByCategory: rbacState.catalogueByCategory,
                      canEdit: canEdit && role.isEditable,
                      hasPendingChanges:
                          rbacState.pendingChanges.contains(role.name),
                      isSaving: rbacState.isSaving,
                      onToggle: (permKey, value) => ref
                          .read(rbacProvider.notifier)
                          .togglePermission(role.name, permKey, value),
                      onToggleCategory: (cat, grantAll) => ref
                          .read(rbacProvider.notifier)
                          .toggleCategory(role.name, cat, grantAll),
                      onSave: () => _onSave(role.name),
                      onDiscard: () => _onDiscard(role.name),
                    );
                  }).toList(),
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
        title: Consumer(
          builder: (context, ref, child) =>
              Text(ref.watch(trProvider)('groups.settings.save')),
        ),
        content: Text(
          'You are about to apply the updated permission set for the $roleName role.\n\n'
          'This change will take effect immediately for all users with this role.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Consumer(
              builder: (context, ref, child) =>
                  Text(ref.watch(trProvider)('common.cancel')),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Consumer(
              builder: (context, ref, child) =>
                  Text(ref.watch(trProvider)('groups.settings.save')),
            ),
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

  Future<void> _onDiscard(String roleName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.restore_rounded, color: Colors.orange, size: 32),
        title: const Text('Discard Changes'),
        content: Text(
          'Discard unsaved changes to $roleName and reload from the server?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Consumer(
              builder: (context, ref, child) =>
                  Text(ref.watch(trProvider)('common.cancel')),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(rbacProvider.notifier).discardChanges(roleName);
    }
  }
}

// ─────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Per-Role Tab Content
// ─────────────────────────────────────────────

class _RolePermissionsTab extends StatefulWidget {
  final RbacRole role;
  final List<RbacPermission> catalogue;
  final Map<String, List<RbacPermission>> catalogueByCategory;
  final bool canEdit;
  final bool hasPendingChanges;
  final bool isSaving;
  final void Function(String permKey, bool value) onToggle;
  final void Function(String category, bool grantAll) onToggleCategory;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  const _RolePermissionsTab({
    required this.role,
    required this.catalogue,
    required this.catalogueByCategory,
    required this.canEdit,
    required this.hasPendingChanges,
    required this.isSaving,
    required this.onToggle,
    required this.onToggleCategory,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  State<_RolePermissionsTab> createState() => _RolePermissionsTabState();
}

class _RolePermissionsTabState extends State<_RolePermissionsTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use the authoritative backend catalogue for totals
    final totalCount = widget.catalogue.length;
    final grantedCount =
        widget.catalogue.where((p) => widget.role.permissions[p.key] == true).length;

    // Filter by search query
    final query = _searchQuery.toLowerCase();
    Map<String, List<RbacPermission>> displayCats;
    if (query.isEmpty) {
      displayCats = widget.catalogueByCategory;
    } else {
      displayCats = {};
      for (final entry in widget.catalogueByCategory.entries) {
        final filtered = entry.value
            .where((p) =>
                p.label.toLowerCase().contains(query) ||
                p.description.toLowerCase().contains(query) ||
                p.key.toLowerCase().contains(query))
            .toList();
        if (filtered.isNotEmpty) {
          displayCats[entry.key] = filtered;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: AdminResponsiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Role header card ──
            _RoleHeaderCard(
              role: widget.role,
              grantedCount: grantedCount,
              totalCount: totalCount,
              isDark: isDark,
            ),

            const SizedBox(height: 12),

            // ── Search box ──
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search permissions…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),

            const SizedBox(height: 12),

            // ── Read-only notice for non-editable roles ──
            if (!widget.role.isEditable)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.role.name == 'SUPER_ADMIN'
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

            // ── Permission categories ──
            if (displayCats.isEmpty && _searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No permissions match "$_searchQuery"',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              )
            else
              ...displayCats.entries.map((entry) => _PermissionCategoryCard(
                    category: entry.key,
                    permissions: entry.value,
                    role: widget.role,
                    canEdit: widget.canEdit,
                    onToggle: widget.onToggle,
                    onToggleCategory: widget.onToggleCategory,
                    isDark: isDark,
                  )),

            // ── Action bar ──
            if (widget.canEdit) ...[
              const SizedBox(height: 8),
              _ActionBar(
                hasPendingChanges: widget.hasPendingChanges,
                isSaving: widget.isSaving,
                roleName: widget.role.name,
                onSave: widget.onSave,
                onDiscard: widget.onDiscard,
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
    // Clamp to [0, 1] so percentage never exceeds 100%
    final fraction =
        totalCount == 0 ? 0.0 : (grantedCount / totalCount).clamp(0.0, 1.0);
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
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
  final void Function(String category, bool grantAll) onToggleCategory;
  final bool isDark;

  const _PermissionCategoryCard({
    required this.category,
    required this.permissions,
    required this.role,
    required this.canEdit,
    required this.onToggle,
    required this.onToggleCategory,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor =
        isDark ? theme.colorScheme.surfaceContainer : Colors.white;
    final grantedInCategory =
        permissions.where((p) => role.permissions[p.key] == true).length;
    final allGranted = grantedInCategory == permissions.length;
    final noneGranted = grantedInCategory == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header with bulk toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  // Bulk Grant All / Revoke All
                  if (canEdit) ...[
                    if (!allGranted)
                      _BulkButton(
                        label: 'Grant All',
                        color: Colors.green,
                        onTap: () => onToggleCategory(category, true),
                      ),
                    if (!noneGranted) ...[
                      const SizedBox(width: 6),
                      _BulkButton(
                        label: 'Revoke All',
                        color: Colors.red,
                        onTap: () => onToggleCategory(category, false),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (allGranted) const SizedBox(width: 8),
                  ],
                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: allGranted
                          ? Colors.green.withValues(alpha: 0.15)
                          : noneGranted
                              ? Colors.red.withValues(alpha: 0.12)
                              : Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$grantedInCategory / ${permissions.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: allGranted
                            ? Colors.green.shade700
                            : noneGranted
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
// Bulk action button
// ─────────────────────────────────────────────

class _BulkButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BulkButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
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
          // Toggle or read-only badge
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
// Action Bar (Save / Discard)
// ─────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final bool hasPendingChanges;
  final bool isSaving;
  final String roleName;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  const _ActionBar({
    required this.hasPendingChanges,
    required this.isSaving,
    required this.roleName,
    required this.onSave,
    required this.onDiscard,
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
                  Icon(Icons.edit_rounded, color: Color(0xFFFF9800), size: 16),
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
              onPressed: hasPendingChanges ? onDiscard : null,
              icon: const Icon(Icons.restore_rounded, size: 16),
              label: const Text('Discard'),
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
