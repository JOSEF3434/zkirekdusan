// lib/features/settings/presentation/privacy_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/settings/presentation/providers/social_settings_provider.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_widgets.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  static const _whoCanSeeOptions = ['Everyone', 'My Contacts', 'Nobody'];
  static const _groupOptions = ['Everyone', 'My Contacts', 'Nobody'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(socialSettingsProvider);
    final n = ref.read(socialSettingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Privacy'),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Who can see ────────────────────────────────────────────────────
          SettingsGroup(
            label: 'WHO CAN SEE',
            children: [
              SettingsDropdownTile(
                icon: Icons.access_time_rounded,
                iconColor: const Color(0xFF00C6FF),
                title: 'Last Seen & Online',
                value: s.lastSeenPrivacy,
                options: _whoCanSeeOptions,
                onChanged: n.setLastSeenPrivacy,
              ),
              SettingsDropdownTile(
                icon: Icons.photo_outlined,
                iconColor: const Color(0xFF43E97B),
                title: 'Profile Photo',
                value: s.profilePhotoPrivacy,
                options: _whoCanSeeOptions,
                onChanged: n.setProfilePhotoPrivacy,
              ),
              SettingsDropdownTile(
                icon: Icons.auto_stories_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: 'Stories',
                value: s.storyPrivacy,
                options: _whoCanSeeOptions,
                onChanged: n.setStoryPrivacy,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Messaging ─────────────────────────────────────────────────────
          SettingsGroup(
            label: 'MESSAGING',
            children: [
              SettingsSwitchTile(
                icon: Icons.done_all_rounded,
                iconColor: const Color(0xFF00C6FF),
                title: 'Read Receipts',
                subtitle: 'Show double blue ticks when messages are read',
                value: s.readReceipts,
                onChanged: n.setReadReceipts,
              ),
              SettingsDropdownTile(
                icon: Icons.group_add_outlined,
                iconColor: const Color(0xFFFF9F43),
                title: 'Who Can Add Me to Groups',
                value: s.groupAddPrivacy,
                options: _groupOptions,
                onChanged: n.setGroupAddPrivacy,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Blocked Users ─────────────────────────────────────────────────
          SettingsGroup(
            label: 'BLOCKED USERS (${s.blockedUsers.length})',
            children: [
              if (s.blockedUsers.isEmpty)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.block, color: Colors.grey),
                  title: const Text('No blocked users'),
                  subtitle: const Text('Blocked users cannot message you or view your profile'),
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
                        onPressed: () => _confirmUnblock(context, ref, u),
                        child: const Text('Unblock',
                            style: TextStyle(color: Color(0xFF00C6FF))),
                      ),
                    ),
                    if (i < s.blockedUsers.length - 1)
                      Divider(height: 1, indent: 66),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // ── Data & Privacy ────────────────────────────────────────────────
          SettingsGroup(
            label: 'DATA & PRIVACY',
            children: [
              SettingsNavTile(
                icon: Icons.download_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: 'Download My Data',
                subtitle: 'Request an export of all your data',
                onTap: () => _requestDataExport(context),
              ),
              SettingsNavTile(
                icon: Icons.delete_forever_outlined,
                iconColor: Colors.red,
                title: 'Delete Account',
                subtitle: 'Permanently remove your account and data',
                onTap: () => _showDeleteAccountWarning(context),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _confirmUnblock(BuildContext context, WidgetRef ref, BlockedUserItem u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Unblock ${u.name}?'),
        content:
            Text('${u.name} will be able to see your profile and contact you again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C6FF)),
            onPressed: () {
              Navigator.pop(context);
              ref.read(socialSettingsProvider.notifier).unblockUser(u.id);
            },
            child: const Text('Unblock', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _requestDataExport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Data export requested. You\'ll receive an email within 48 hours.')),
    );
  }

  void _showDeleteAccountWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
        content: const Text(
            'This action is PERMANENT and IRREVERSIBLE.\n\nAll your posts, messages, followers, and data will be deleted forever.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand, Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
