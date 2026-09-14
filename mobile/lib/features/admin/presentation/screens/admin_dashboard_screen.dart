// lib/features/admin/presentation/screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_stat_card.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_status_badge.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final perms = ref.watch(adminPermissionsProvider);
    final dashboardState = ref.watch(adminDashboardProvider);

    if (!perms.hasAdminAccess) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('admin.title'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gavel_rounded, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  tr('admin.unauthorized'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.title')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AdminStatusBadge(status: perms.role),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: tr('common.retry'),
            onPressed: () => ref.read(adminDashboardProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminDashboardProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: AdminResponsiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Metrics Grid
                dashboardState.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Text('${tr('common.error')}: $err'),
                  ),
                  data: (data) => _buildMetricsGrid(context, ref, data, perms),
                ),

                const SizedBox(height: 24),

                // Management Sections
                _buildManagementSections(context, ref, perms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
    AdminPermissions perms,
  ) {
    final tr = ref.watch(trProvider);
    final payload = safeMap(data['data']) ?? data;

    final users = safeMap(payload['users']);
    final groups = safeMap(payload['groups']);
    final content = safeMap(payload['content']);
    final reports = safeMap(payload['reports']);
    final live = safeMap(payload['live']);

    final int totalUsers = users?['total'] ?? payload['totalUsers'] ?? 0;
    final int activeUsers = users?['active'] ?? totalUsers;
    final int totalGroups = groups?['total'] ?? payload['totalGroups'] ?? 0;
    final int pendingGroups = groups?['pending'] ?? 0;
    final int activeGroups = groups?['active'] ?? (totalGroups - pendingGroups);
    final int pendingReports = reports?['pending'] ?? 0;
    final int totalReports = reports?['total'] ?? payload['totalReports'] ?? 0;
    final int totalPosts = content?['posts'] ?? payload['totalPosts'] ?? 0;
    final int totalVideos = content?['videos'] ?? payload['totalVideos'] ?? 0;
    final int totalContent = content?['total'] ?? (totalPosts + totalVideos);
    final int activeStreams = live?['activeStreams'] ?? 0;
    final int totalStreams = live?['total'] ?? payload['totalStreams'] ?? activeStreams;

    final cards = <Widget>[];

    if (perms.canManageUsers) {
      cards.add(
        AdminStatCard(
          title: tr('admin.stats.users'),
          value: '$totalUsers',
          icon: Icons.people_alt_rounded,
          color: Colors.blue,
          subtitle: '$activeUsers ${tr('admin.stats.active_users')}',
          onTap: () => context.push('/admin/users'),
        ),
      );
    }

    if (perms.canManageGroups) {
      cards.add(
        AdminStatCard(
          title: tr('admin.stats.groups'),
          value: '$totalGroups',
          icon: Icons.groups_rounded,
          color: Colors.deepPurple,
          subtitle: pendingGroups > 0
              ? '$pendingGroups ${tr('admin.stats.pending_groups')}'
              : '$activeGroups active',
          onTap: () => context.push('/admin/groups'),
        ),
      );
    }

    if (perms.canManageReports) {
      cards.add(
        AdminStatCard(
          title: tr('admin.stats.reports'),
          value: '$pendingReports',
          icon: Icons.flag_rounded,
          color: Colors.orange,
          subtitle: '$totalReports ${tr('admin.stats.total_reports')}',
          onTap: () => context.push('/admin/reports'),
        ),
      );
    }

    if (perms.canManageContent) {
      cards.add(
        AdminStatCard(
          title: tr('admin.stats.content'),
          value: '$totalContent',
          icon: Icons.article_rounded,
          color: Colors.teal,
          subtitle: '$totalVideos videos • $totalPosts posts',
          onTap: () => context.push('/admin/content'),
        ),
      );
    }

    if (perms.canManageLive) {
      cards.add(
        AdminStatCard(
          title: tr('admin.stats.live'),
          value: '$totalStreams',
          icon: Icons.live_tv_rounded,
          color: Colors.red,
          subtitle: '$activeStreams ${tr('admin.stats.active_streams')}',
          onTap: () => context.push('/admin/live'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 130,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  Widget _buildManagementSections(
    BuildContext context,
    WidgetRef ref,
    AdminPermissions perms,
  ) {
    final tr = ref.watch(trProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Community & Users
        if (perms.canManageUsers || perms.canManageGroups || perms.canManageRoles)
          AdminSectionCard(
            title: tr('admin.section.directory'),
            subtitle: tr('admin.section.directory_sub'),
            child: Column(
              children: [
                if (perms.canManageUsers)
                  ListTile(
                    leading: const Icon(Icons.person_search_rounded, color: Colors.blue),
                    title: Text(tr('admin.users')),
                    subtitle: Text(tr('admin.users_sub')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/users'),
                  ),
                if (perms.canManageRoles)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_rounded, color: Colors.indigo),
                    title: Text(tr('admin.roles')),
                    subtitle: Text(tr('admin.roles_sub')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/roles'),
                  ),
                if (perms.canManageGroups)
                  ListTile(
                    leading: const Icon(Icons.groups_rounded, color: Colors.deepPurple),
                    title: Text(tr('admin.groups')),
                    subtitle: Text(tr('admin.groups_sub')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/groups'),
                  ),
                if (perms.canManageChannels)
                  ListTile(
                    leading: const Icon(Icons.tag_rounded, color: Colors.purple),
                    title: Text(tr('admin.channels')),
                    subtitle: Text(tr('admin.channels_sub')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/channels'),
                  ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Moderation & Safety
        if (perms.canManageReports || perms.canManageContent || perms.canManageLive || perms.canManageChat)
          AdminSectionCard(
            title: tr('admin.section.moderation'),
            subtitle: tr('admin.section.moderation_sub'),
            child: Column(
              children: [
                if (perms.canManageReports)
                  ListTile(
                    leading: const Icon(Icons.flag_rounded, color: Colors.orange),
                    title: Text(tr('admin.reports')),
                    subtitle: Text(tr('admin.reports_sub')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/reports'),
                  ),
                if (perms.canManageContent)
                  ListTile(
                    leading: const Icon(Icons.article_rounded, color: Colors.teal),
                    title: Text(tr('admin.content')),
                    subtitle: Text(tr('admin.content_sub')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/content'),
                  ),
                if (perms.canManageLive)
                  ListTile(
                    leading: const Icon(Icons.live_tv_rounded, color: Colors.red),
                    title: Text(tr('admin.live')),
                    subtitle: Text(tr('admin.live_sub')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/live'),
                  ),
                if (perms.canManageChat)
                  ListTile(
                    leading: const Icon(Icons.chat_bubble_rounded, color: Colors.blueAccent),
                    title: Text(tr('admin.chat')),
                    subtitle: Text(tr('admin.chat_sub')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/chat'),
                  ),
                ListTile(
                  leading: const Icon(Icons.security_rounded, color: Colors.amber),
                  title: Text(tr('admin.spam')),
                  subtitle: Text(tr('admin.spam_sub')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin/spam'),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // System & Operations
        if (perms.canManageStorage || perms.canManageNotifications || perms.canViewAudit || perms.canManageSystem)
          AdminSectionCard(
            title: tr('admin.section.system'),
            subtitle: tr('admin.section.system_sub'),
            child: Column(
              children: [
                if (perms.canManageStorage)
                  ListTile(
                    leading: const Icon(Icons.cloud_queue_rounded, color: Colors.cyan),
                    title: Text(tr('admin.storage')),
                    subtitle: Text(tr('admin.storage_sub')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/storage'),
                  ),
                if (perms.canManageNotifications)
                  ListTile(
                    leading: const Icon(Icons.campaign_rounded, color: Colors.deepOrange),
                    title: Text(tr('admin.notifications')),
                    subtitle: Text(tr('admin.notifications_sub')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/notifications'),
                  ),
                if (perms.canViewAudit)
                  ListTile(
                    leading: const Icon(Icons.history_rounded, color: Colors.grey),
                    title: Text(tr('admin.audit')),
                    subtitle: Text(tr('admin.audit_sub')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/audit'),
                  ),
                if (perms.canManageSystem)
                  ListTile(
                    leading: const Icon(Icons.settings_applications_rounded, color: Colors.blueGrey),
                    title: Text(tr('admin.system')),
                    subtitle: Text(tr('admin.system_sub')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/system'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
