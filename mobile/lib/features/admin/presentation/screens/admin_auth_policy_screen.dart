// lib/features/admin/presentation/screens/admin_auth_policy_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';
import 'package:mobile/features/auth/data/models/login_policy_model.dart';
import 'package:mobile/features/auth/presentation/providers/login_policy_provider.dart';

class AdminAuthPolicyScreen extends ConsumerStatefulWidget {
  const AdminAuthPolicyScreen({super.key});

  @override
  ConsumerState<AdminAuthPolicyScreen> createState() =>
      _AdminAuthPolicyScreenState();
}

class _AdminAuthPolicyScreenState extends ConsumerState<AdminAuthPolicyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Form state
  String _selectedPolicy = 'SINGLE_IDENTIFIER';
  bool _allowEmail = true;
  bool _allowPhone = true;
  bool _allowUsername = true;
  String _dualCombination = 'EMAIL_PHONE';
  final _reasonCtrl = TextEditingController();

  // Audit logs state
  List<LoginPolicyAuditItem> _auditLogs = [];
  bool _isLoadingLogs = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPolicy();
    _loadAuditLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPolicy() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(adminRepositoryProvider);
      final data = await repo.getLoginPolicy();
      if (mounted) {
        setState(() {
          _selectedPolicy = data['activePolicy'] as String? ?? 'SINGLE_IDENTIFIER';
          _allowEmail = data['allowEmail'] as bool? ?? true;
          _allowPhone = data['allowPhone'] as bool? ?? true;
          _allowUsername = data['allowUsername'] as bool? ?? true;
          _dualCombination =
              data['dualCombination'] as String? ?? 'EMAIL_PHONE';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoadingLogs = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.getLoginPolicyAuditLogs();
      final items = (res['items'] as List?) ?? [];
      if (mounted) {
        setState(() {
          _auditLogs = items
              .whereType<Map>()
              .map((e) =>
                  LoginPolicyAuditItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          _isLoadingLogs = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingLogs = false);
      }
    }
  }

  Future<void> _confirmAndSave() async {
    final tr = ref.read(trProvider);

    // Validation
    if (_selectedPolicy == 'SINGLE_IDENTIFIER') {
      if (!_allowEmail && !_allowPhone && !_allowUsername) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('admin.auth_policy.error_select_at_least_one')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final isDisruptive = _selectedPolicy != 'SINGLE_IDENTIFIER';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isDisruptive ? Icons.warning_amber_rounded : Icons.security_rounded,
              color: isDisruptive ? Colors.amber : Colors.indigo,
            ),
            const SizedBox(width: 8),
            Text(tr('admin.auth_policy.confirm_title')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDisruptive
                  ? tr('admin.auth_policy.confirm_disruptive_warning')
                  : tr('admin.auth_policy.confirm_message'),
            ),
            const SizedBox(height: 12),
            Text(
              '${tr('admin.auth_policy.new_policy')}: ${_policyLabel(_selectedPolicy)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: isDisruptive
                ? FilledButton.styleFrom(backgroundColor: Colors.amber.shade800)
                : null,
            child: Text(tr('common.apply')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _executeSave();
    }
  }

  Future<void> _executeSave() async {
    setState(() => _isSaving = true);
    final tr = ref.read(trProvider);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.updateLoginPolicy(
        activePolicy: _selectedPolicy,
        allowEmail: _allowEmail,
        allowPhone: _allowPhone,
        allowUsername: _allowUsername,
        dualCombination:
            _selectedPolicy == 'DUAL_IDENTIFIER' ? _dualCombination : null,
        reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
        acknowledgeUserImpact: true,
      );

      // Invalidate and update local provider
      final updatedConfig = LoginPolicyConfig(
        activePolicy: res['activePolicy'] as String? ?? _selectedPolicy,
        allowEmail: res['allowEmail'] as bool? ?? _allowEmail,
        allowPhone: res['allowPhone'] as bool? ?? _allowPhone,
        allowUsername: res['allowUsername'] as bool? ?? _allowUsername,
        dualCombination: res['dualCombination'] as String?,
      );
      ref.read(loginPolicyProvider.notifier).updateLocalPolicy(updatedConfig);

      if (mounted) {
        _reasonCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('admin.auth_policy.save_success')),
            backgroundColor: Colors.green,
          ),
        );
        _loadAuditLogs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr('common.error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _policyLabel(String policy) {
    final tr = ref.read(trProvider);
    switch (policy) {
      case 'SINGLE_IDENTIFIER':
        return tr('admin.auth_policy.policy_single');
      case 'DUAL_IDENTIFIER':
        return tr('admin.auth_policy.policy_dual');
      case 'ALL_IDENTIFIERS':
        return tr('admin.auth_policy.policy_all');
      default:
        return policy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final perms = ref.watch(adminPermissionsProvider);
    final cs = Theme.of(context).colorScheme;

    if (!perms.canManageLoginPolicy) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('admin.auth_policy.title'))),
        body: Center(
          child: Text(tr('admin.unauthorized')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.auth_policy.title')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.settings_outlined),
              text: tr('admin.auth_policy.tab_settings'),
            ),
            Tab(
              icon: const Icon(Icons.history_rounded),
              text: tr('admin.auth_policy.tab_audit'),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${tr('common.error')}: $_errorMessage'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadPolicy,
                        child: Text(tr('common.retry')),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSettingsTab(cs, tr),
                    _buildAuditTab(cs, tr),
                  ],
                ),
    );
  }

  Widget _buildSettingsTab(ColorScheme cs, String Function(String) tr) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AdminResponsiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info Card
            Card(
              elevation: 0,
              color: cs.primaryContainer.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.shield_rounded, size: 36, color: cs.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('admin.auth_policy.banner_title'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('admin.auth_policy.banner_desc'),
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Choose Active Policy
            Text(
              tr('admin.auth_policy.section_choose_policy'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Option 1: Single Identifier
            _buildPolicyOptionCard(
              cs: cs,
              title: tr('admin.auth_policy.policy_single'),
              subtitle: tr('admin.auth_policy.policy_single_desc'),
              value: 'SINGLE_IDENTIFIER',
              icon: Icons.person_pin_circle_outlined,
            ),
            const SizedBox(height: 8),

            // Option 2: Dual Identifier
            _buildPolicyOptionCard(
              cs: cs,
              title: tr('admin.auth_policy.policy_dual'),
              subtitle: tr('admin.auth_policy.policy_dual_desc'),
              value: 'DUAL_IDENTIFIER',
              icon: Icons.people_outline,
            ),
            const SizedBox(height: 8),

            // Option 3: All Three Identifiers
            _buildPolicyOptionCard(
              cs: cs,
              title: tr('admin.auth_policy.policy_all'),
              subtitle: tr('admin.auth_policy.policy_all_desc'),
              value: 'ALL_IDENTIFIERS',
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: 24),

            // Section 2: Policy Details Configuration
            if (_selectedPolicy == 'SINGLE_IDENTIFIER') ...[
              Text(
                tr('admin.auth_policy.permitted_identifiers'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(tr('auth.email_label')),
                      subtitle: Text(tr('admin.auth_policy.allow_email_desc')),
                      value: _allowEmail,
                      onChanged: (val) => setState(() => _allowEmail = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(tr('admin.auth_policy.allow_phone')),
                      subtitle: Text(tr('admin.auth_policy.allow_phone_desc')),
                      value: _allowPhone,
                      onChanged: (val) => setState(() => _allowPhone = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(tr('auth.username_label')),
                      subtitle: Text(tr('admin.auth_policy.allow_username_desc')),
                      value: _allowUsername,
                      onChanged: (val) => setState(() => _allowUsername = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (_selectedPolicy == 'DUAL_IDENTIFIER') ...[
              Text(
                tr('admin.auth_policy.required_dual_combo'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(tr('admin.auth_policy.combo_email_phone')),
                      subtitle: Text(tr('admin.auth_policy.combo_email_phone_sub')),
                      value: 'EMAIL_PHONE',
                      groupValue: _dualCombination,
                      onChanged: (v) =>
                          setState(() => _dualCombination = v ?? 'EMAIL_PHONE'),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: Text(tr('admin.auth_policy.combo_email_username')),
                      subtitle: Text(tr('admin.auth_policy.combo_email_username_sub')),
                      value: 'EMAIL_USERNAME',
                      groupValue: _dualCombination,
                      onChanged: (v) =>
                          setState(() => _dualCombination = v ?? 'EMAIL_USERNAME'),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: Text(tr('admin.auth_policy.combo_phone_username')),
                      subtitle: Text(tr('admin.auth_policy.combo_phone_username_sub')),
                      value: 'PHONE_USERNAME',
                      groupValue: _dualCombination,
                      onChanged: (v) =>
                          setState(() => _dualCombination = v ?? 'PHONE_USERNAME'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Section 3: Live Preview
            Text(
              tr('admin.auth_policy.preview_title'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _buildLivePreviewCard(cs, tr),
            const SizedBox(height: 24),

            // Section 4: Audit Reason Input
            Text(
              tr('admin.auth_policy.reason_label'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonCtrl,
              decoration: InputDecoration(
                hintText: tr('admin.auth_policy.reason_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: 24),

            // Save Action Button
            FilledButton.icon(
              onPressed: _isSaving ? null : _confirmAndSave,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isSaving
                    ? tr('common.loading')
                    : tr('admin.auth_policy.btn_save_changes'),
                style: const TextStyle(fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyOptionCard({
    required ColorScheme cs,
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedPolicy == value;
    return InkWell(
      onTap: () => setState(() => _selectedPolicy = value),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? cs.primaryContainer.withValues(alpha: 0.15)
              : cs.surface,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPolicy,
              onChanged: (v) => setState(() => _selectedPolicy = v!),
              activeColor: cs.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreviewCard(ColorScheme cs, String Function(String) tr) {
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.visibility_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  tr('admin.auth_policy.preview_badge'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Form inputs mockup based on policy
            if (_selectedPolicy == 'SINGLE_IDENTIFIER') ...[
              _buildMockupField(
                label: _allowEmail && !_allowPhone && !_allowUsername
                    ? tr('auth.email_label')
                    : !_allowEmail && _allowPhone && !_allowUsername
                        ? tr('admin.auth_policy.phone_label')
                        : !_allowEmail && !_allowPhone && _allowUsername
                            ? tr('auth.username_label')
                            : tr('auth.identifier_label'),
                icon: Icons.person_outline,
                hint: _allowEmail && !_allowPhone && !_allowUsername
                    ? 'user@example.com'
                    : !_allowEmail && _allowPhone && !_allowUsername
                        ? '+1234567890'
                        : 'email / phone / username',
              ),
            ] else if (_selectedPolicy == 'DUAL_IDENTIFIER') ...[
              if (_dualCombination == 'EMAIL_PHONE') ...[
                _buildMockupField(
                  label: tr('auth.email_label'),
                  icon: Icons.email_outlined,
                  hint: 'user@example.com',
                ),
                const SizedBox(height: 8),
                _buildMockupField(
                  label: tr('admin.auth_policy.phone_label'),
                  icon: Icons.phone_outlined,
                  hint: '+1234567890',
                ),
              ] else if (_dualCombination == 'EMAIL_USERNAME') ...[
                _buildMockupField(
                  label: tr('auth.email_label'),
                  icon: Icons.email_outlined,
                  hint: 'user@example.com',
                ),
                const SizedBox(height: 8),
                _buildMockupField(
                  label: tr('auth.username_label'),
                  icon: Icons.account_circle_outlined,
                  hint: 'username',
                ),
              ] else ...[
                _buildMockupField(
                  label: tr('admin.auth_policy.phone_label'),
                  icon: Icons.phone_outlined,
                  hint: '+1234567890',
                ),
                const SizedBox(height: 8),
                _buildMockupField(
                  label: tr('auth.username_label'),
                  icon: Icons.account_circle_outlined,
                  hint: 'username',
                ),
              ],
            ] else ...[
              _buildMockupField(
                label: tr('auth.email_label'),
                icon: Icons.email_outlined,
                hint: 'user@example.com',
              ),
              const SizedBox(height: 8),
              _buildMockupField(
                label: tr('admin.auth_policy.phone_label'),
                icon: Icons.phone_outlined,
                hint: '+1234567890',
              ),
              const SizedBox(height: 8),
              _buildMockupField(
                label: tr('auth.username_label'),
                icon: Icons.account_circle_outlined,
                hint: 'username',
              ),
            ],
            const SizedBox(height: 8),
            _buildMockupField(
              label: tr('auth.password_label'),
              icon: Icons.lock_outline,
              hint: '••••••••',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockupField({
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTab(ColorScheme cs, String Function(String) tr) {
    if (_isLoadingLogs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_auditLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                tr('admin.auth_policy.no_audit_logs'),
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAuditLogs,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _auditLogs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (ctx, idx) {
          final log = _auditLogs[idx];
          final afterPolicy = log.after?['activePolicy'] as String? ?? 'N/A';
          final beforePolicy = log.before?['activePolicy'] as String? ?? 'N/A';

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 18, color: cs.primary),
                          const SizedBox(width: 6),
                          Text(
                            log.actorUsername ?? 'Admin',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        '${log.createdAt.year}-${log.createdAt.month.toString().padLeft(2, '0')}-${log.createdAt.day.toString().padLeft(2, '0')} ${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$beforePolicy → $afterPolicy',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  if (log.reason != null && log.reason!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${tr('admin.auth_policy.reason_label')}: ${log.reason}',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
