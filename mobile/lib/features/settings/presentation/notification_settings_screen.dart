// lib/features/settings/presentation/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/settings/presentation/providers/social_settings_provider.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_widgets.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(socialSettingsProvider);
    final n = ref.read(socialSettingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Master Toggle ──────────────────────────────────────────────────
          SettingsGroup(
            label: 'MASTER CONTROL',
            children: [
              SettingsSwitchTile(
                icon: Icons.do_not_disturb_on_outlined,
                iconColor: Colors.red,
                title: 'Pause All Notifications',
                subtitle: 'Temporarily silence all notifications',
                value: s.pauseAllNotifications,
                onChanged: n.setPauseAllNotifications,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Messages ──────────────────────────────────────────────────────
          SettingsGroup(
            label: 'MESSAGES',
            children: [
              SettingsSwitchTile(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF00C6FF),
                title: 'Message Notifications',
                subtitle: 'Notify me of new direct messages',
                value: s.messageNotifications && !s.pauseAllNotifications,
                onChanged: s.pauseAllNotifications
                    ? (_) {}
                    : n.setMessageNotifications,
              ),
              SettingsSwitchTile(
                icon: Icons.volume_up_outlined,
                iconColor: const Color(0xFF43E97B),
                title: 'Message Sound',
                subtitle: 'Play a sound for new messages',
                value: s.messageSound && !s.pauseAllNotifications,
                onChanged: s.pauseAllNotifications ? (_) {} : n.setMessageSound,
              ),
              SettingsSwitchTile(
                icon: Icons.vibration_rounded,
                iconColor: const Color(0xFFFF9F43),
                title: 'Vibration',
                subtitle: 'Vibrate when a message is received',
                value: s.messageVibrate && !s.pauseAllNotifications,
                onChanged:
                    s.pauseAllNotifications ? (_) {} : n.setMessageVibrate,
              ),
              SettingsSwitchTile(
                icon: Icons.preview_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: 'Message Preview',
                subtitle: 'Show message content in notification',
                value: s.messagePreview && !s.pauseAllNotifications,
                onChanged:
                    s.pauseAllNotifications ? (_) {} : n.setMessagePreview,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Groups & Communities ───────────────────────────────────────────
          SettingsGroup(
            label: 'GROUPS & COMMUNITIES',
            children: [
              SettingsSwitchTile(
                icon: Icons.groups_outlined,
                iconColor: const Color(0xFF9B59B6),
                title: 'Group Notifications',
                subtitle: 'Alerts for new group messages',
                value: s.groupNotifications && !s.pauseAllNotifications,
                onChanged:
                    s.pauseAllNotifications ? (_) {} : n.setGroupNotifications,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Content ───────────────────────────────────────────────────────
          SettingsGroup(
            label: 'CONTENT',
            children: [
              SettingsSwitchTile(
                icon: Icons.auto_stories_outlined,
                iconColor: const Color(0xFFFF6584),
                title: 'Story Notifications',
                subtitle: 'Notify when contacts post stories',
                value: s.storyNotifications && !s.pauseAllNotifications,
                onChanged:
                    s.pauseAllNotifications ? (_) {} : n.setStoryNotifications,
              ),
              SettingsSwitchTile(
                icon: Icons.live_tv_outlined,
                iconColor: Colors.red,
                title: 'Live Alerts',
                subtitle: 'Notify when someone I follow goes live',
                value: s.liveAlerts && !s.pauseAllNotifications,
                onChanged: s.pauseAllNotifications ? (_) {} : n.setLiveAlerts,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── In-App ────────────────────────────────────────────────────────
          SettingsGroup(
            label: 'IN-APP',
            children: [
              SettingsSwitchTile(
                icon: Icons.music_note_outlined,
                iconColor: const Color(0xFF00B894),
                title: 'In-App Sounds',
                subtitle: 'Play sounds within the app',
                value: s.inAppSounds,
                onChanged: n.setInAppSounds,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
