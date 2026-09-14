// lib/features/admin/presentation/screens/admin_roles_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_status_badge.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';

class AdminRolesScreen extends ConsumerWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.roles')),
      ),
      body: SingleChildScrollView(
        child: AdminResponsiveLayout(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Platform Tiers Overview
              AdminSectionCard(
                title: 'Platform Role Hierarchy (5 Tiers)',
                subtitle: 'Platform-level governance and administrative authority',
                child: Column(
                  children: [
                    _buildRoleTile(
                      'SUPER_ADMIN',
                      'Full platform ownership. Unrestricted bypass (*) on all services. Only role authorized to modify system settings and promote other Super Admins.',
                      Colors.red.shade700,
                      Icons.military_tech_rounded,
                    ),
                    const Divider(),
                    _buildRoleTile(
                      'ADMIN',
                      'Platform Administrator. Full operational rights across users, groups, content, streams, storage, audit logs, and broadcasts.',
                      Colors.indigo,
                      Icons.admin_panel_settings_rounded,
                    ),
                    const Divider(),
                    _buildRoleTile(
                      'MODERATOR',
                      'Trust & Safety Moderator. Oversees user reports, content moderation (posts, reels, videos), terminates live streams, and purges chat.',
                      Colors.orange.shade800,
                      Icons.gavel_rounded,
                    ),
                    const Divider(),
                    _buildRoleTile(
                      'SUPPORT',
                      'Customer & User Operations. Manages user status, assists with account verification, handles user-level reports, and reviews logs.',
                      Colors.teal,
                      Icons.support_agent_rounded,
                    ),
                    const Divider(),
                    _buildRoleTile(
                      'USER',
                      'Standard registered platform user. Subject to standard community permissions, can create groups and participate.',
                      Colors.blueGrey,
                      Icons.person_outline_rounded,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Group Scoped Roles
              AdminSectionCard(
                title: 'Group-Scoped Roles',
                subtitle: 'Granular control inside individual groups and organizations',
                child: Column(
                  children: [
                    _buildRoleTile(
                      'GROUP_ADMIN',
                      'Group Creator or designated leader. Full rights within group (manage channels, members, approve join requests).',
                      Colors.purple,
                      Icons.shield_rounded,
                    ),
                    const Divider(),
                    _buildRoleTile(
                      'MODERATOR (Group)',
                      'Group moderator. Mutes members, deletes offensive group messages, and manages group queue.',
                      Colors.deepPurpleAccent,
                      Icons.security_rounded,
                    ),
                    const Divider(),
                    _buildRoleTile(
                      'MEMBER / GUEST',
                      'Member with posting and chatting permissions within group channels.',
                      Colors.blueGrey,
                      Icons.group_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Permissions Matrix
              AdminSectionCard(
                title: 'Resource Permissions Matrix',
                subtitle: 'Explicit resource.action mapping enforced on backend routes',
                child: Table(
                  border: TableBorder.all(color: Colors.grey.withValues(alpha: 0.2)),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                  },
                  children: const [
                    TableRow(
                      decoration: BoxDecoration(color: Color(0x10000000)),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Resource Domain', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Actions & Scope', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    TableRow(children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('users.*')),
                      Padding(padding: EdgeInsets.all(8), child: Text('read, create, update, delete, ban, suspend, assign_role')),
                    ]),
                    TableRow(children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('groups.*')),
                      Padding(padding: EdgeInsets.all(8), child: Text('read, approve, reject, suspend, restore, delete, remove_member')),
                    ]),
                    TableRow(children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('channels.*')),
                      Padding(padding: EdgeInsets.all(8), child: Text('read, archive, delete, pin, reorder')),
                    ]),
                    TableRow(children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('content.*')),
                      Padding(padding: EdgeInsets.all(8), child: Text('read, update_status, feature, pin, delete (posts, reels, videos)')),
                    ]),
                    TableRow(children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('reports.*')),
                      Padding(padding: EdgeInsets.all(8), child: Text('read, resolve, dismiss, take_action, assign')),
                    ]),
                    TableRow(children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('live.*')),
                      Padding(padding: EdgeInsets.all(8), child: Text('read, terminate, mute_chat, delete')),
                    ]),
                    TableRow(children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('chat.*')),
                      Padding(padding: EdgeInsets.all(8), child: Text('read, delete_message, purge_conversation')),
                    ]),
                    TableRow(children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('storage.*')),
                      Padding(padding: EdgeInsets.all(8), child: Text('read, stats, delete, cleanup')),
                    ]),
                    TableRow(children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('audit.*')),
                      Padding(padding: EdgeInsets.all(8), child: Text('read, export, search')),
                    ]),
                    TableRow(children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('system.*')),
                      Padding(padding: EdgeInsets.all(8), child: Text('settings, maintenance, broadcast, reseed')),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTile(String role, String description, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AdminStatusBadge(status: role),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
