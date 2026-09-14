// lib/features/settings/presentation/privacy_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/settings/presentation/providers/social_settings_provider.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_widgets.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  static const _whoCanSeeOptions = ['Everyone', 'My Contacts', 'Nobody'];
  static const _groupOptions = ['Everyone', 'My Contacts', 'Nobody'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final s = ref.watch(socialSettingsProvider);
    final n = ref.read(socialSettingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final optionLabels = {
      'Everyone': tr('settings.privacy.option.everyone'),
      'My Contacts': tr('settings.privacy.option.my_contacts'),
      'Nobody': tr('settings.privacy.option.nobody'),
    };

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(tr('settings.privacy')),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Who can see ────────────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.privacy.who_can_see'),
            children: [
              SettingsDropdownTile(
                icon: Icons.access_time_rounded,
                iconColor: const Color(0xFF00C6FF),
                title: tr('settings.privacy.last_seen'),
                value: s.lastSeenPrivacy,
                options: _whoCanSeeOptions,
                optionLabels: optionLabels,
                onChanged: n.setLastSeenPrivacy,
              ),
              SettingsDropdownTile(
                icon: Icons.photo_outlined,
                iconColor: const Color(0xFF43E97B),
                title: tr('settings.privacy.profile_photo'),
                value: s.profilePhotoPrivacy,
                options: _whoCanSeeOptions,
                optionLabels: optionLabels,
                onChanged: n.setProfilePhotoPrivacy,
              ),
              SettingsDropdownTile(
                icon: Icons.auto_stories_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: tr('settings.privacy.stories'),
                value: s.storyPrivacy,
                options: _whoCanSeeOptions,
                optionLabels: optionLabels,
                onChanged: n.setStoryPrivacy,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Messaging ─────────────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.privacy.messaging'),
            children: [
              SettingsSwitchTile(
                icon: Icons.done_all_rounded,
                iconColor: const Color(0xFF00C6FF),
                title: tr('settings.privacy.read_receipts'),
                subtitle: tr('settings.privacy.read_receipts_desc'),
                value: s.readReceipts,
                onChanged: n.setReadReceipts,
              ),
              SettingsDropdownTile(
                icon: Icons.group_add_outlined,
                iconColor: const Color(0xFFFF9F43),
                title: tr('settings.privacy.who_can_add_to_group'),
                value: s.groupAddPrivacy,
                options: _groupOptions,
                optionLabels: optionLabels,
                onChanged: n.setGroupAddPrivacy,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Blocked Users ─────────────────────────────────────────────────
          SettingsGroup(
            label: '${tr('settings.privacy.blocked_users')} (${s.blockedUsers.length})',
            children: [
              if (s.blockedUsers.isEmpty)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.block, color: Colors.grey),
                  title: Text(tr('settings.privacy.no_blocked_users')),
                  subtitle: Text(tr('settings.privacy.no_blocked_users_desc')),
                ),
              ...s.blockedUsers.asMap().entries.map((entry) {
                final i = entry.key;
                final u = entry.value;
                return Column(
                  children: [
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.red.withValues(alpha: 0.15),
                        child: Text(
                          u.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(u.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(u.username,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: TextButton(
                        onPressed: () => _confirmUnblock(context, ref, u, tr),
                        child: Text(tr('settings.privacy.unblock'),
                            style: const TextStyle(color: Color(0xFF00C6FF))),
                      ),
                    ),
                    if (i < s.blockedUsers.length - 1)
                      const Divider(height: 1, indent: 66),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // ── Data & Privacy ────────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.privacy.data_privacy'),
            children: [
              SettingsNavTile(
                icon: Icons.download_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: tr('settings.privacy.download_data'),
                subtitle: tr('settings.privacy.download_data_desc'),
                onTap: () => _requestDataExport(context, tr),
              ),
              SettingsNavTile(
                icon: Icons.delete_forever_outlined,
                iconColor: Colors.red,
                title: tr('settings.privacy.delete_account'),
                subtitle: tr('settings.privacy.delete_account_desc'),
                onTap: () => _showDeleteAccountWarning(context, tr),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _confirmUnblock(BuildContext context, WidgetRef ref, BlockedUserItem u, String Function(String, [Map<String, dynamic>?]) tr) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('settings.privacy.unblock_title', {'name': u.name})),
        content: Text(tr('settings.privacy.unblock_desc', {'name': u.name})),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(tr('common.cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C6FF)),
            onPressed: () {
              Navigator.pop(context);
              ref.read(socialSettingsProvider.notifier).unblockUser(u.id);
            },
            child: Text(tr('settings.privacy.unblock'), style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _requestDataExport(BuildContext context, String Function(String, [Map<String, dynamic>?]) tr) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(tr('settings.privacy.data_export_requested'))),
    );
  }

  void _showDeleteAccountWarning(BuildContext context, String Function(String, [Map<String, dynamic>?]) tr) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('settings.privacy.delete_account'), style: const TextStyle(color: Colors.red)),
        content: Text(tr('settings.privacy.delete_account_warning')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(tr('common.cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context),
            child: Text(tr('settings.privacy.confirm_delete'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
