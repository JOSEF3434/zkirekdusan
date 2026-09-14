// lib/features/settings/presentation/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/settings/presentation/providers/social_settings_provider.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_widgets.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final s = ref.watch(socialSettingsProvider);
    final n = ref.read(socialSettingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(tr('settings.notifications')),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Master Toggle ──────────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.notifications.master_control'),
            children: [
              SettingsSwitchTile(
                icon: Icons.do_not_disturb_on_outlined,
                iconColor: Colors.red,
                title: tr('settings.notifications.pause_all'),
                subtitle: tr('settings.notifications.pause_all_desc'),
                value: s.pauseAllNotifications,
                onChanged: n.setPauseAllNotifications,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Messages ──────────────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.notifications.messages'),
            children: [
              SettingsSwitchTile(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF00C6FF),
                title: tr('settings.notifications.message_notifications'),
                subtitle: tr('settings.notifications.message_notifications_desc'),
                value: s.messageNotifications && !s.pauseAllNotifications,
                onChanged: s.pauseAllNotifications
                    ? (_) {}
                    : n.setMessageNotifications,
              ),
              SettingsSwitchTile(
                icon: Icons.volume_up_outlined,
                iconColor: const Color(0xFF43E97B),
                title: tr('settings.notifications.message_sound'),
                subtitle: tr('settings.notifications.message_sound_desc'),
                value: s.messageSound && !s.pauseAllNotifications,
                onChanged: s.pauseAllNotifications ? (_) {} : n.setMessageSound,
              ),
              SettingsSwitchTile(
                icon: Icons.vibration_rounded,
                iconColor: const Color(0xFFFF9F43),
                title: tr('settings.notifications.vibration'),
                subtitle: tr('settings.notifications.vibration_desc'),
                value: s.messageVibrate && !s.pauseAllNotifications,
                onChanged:
                    s.pauseAllNotifications ? (_) {} : n.setMessageVibrate,
              ),
              SettingsSwitchTile(
                icon: Icons.preview_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: tr('settings.notifications.message_preview'),
                subtitle: tr('settings.notifications.message_preview_desc'),
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
            label: tr('settings.notifications.groups'),
            children: [
              SettingsSwitchTile(
                icon: Icons.groups_outlined,
                iconColor: const Color(0xFF9B59B6),
                title: tr('settings.notifications.group_notifications'),
                subtitle: tr('settings.notifications.group_notifications_desc'),
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
            label: tr('settings.notifications.content'),
            children: [
              SettingsSwitchTile(
                icon: Icons.auto_stories_outlined,
                iconColor: const Color(0xFFFF6584),
                title: tr('settings.notifications.story_notifications'),
                subtitle: tr('settings.notifications.story_notifications_desc'),
                value: s.storyNotifications && !s.pauseAllNotifications,
                onChanged:
                    s.pauseAllNotifications ? (_) {} : n.setStoryNotifications,
              ),
              SettingsSwitchTile(
                icon: Icons.live_tv_outlined,
                iconColor: Colors.red,
                title: tr('settings.notifications.live_alerts'),
                subtitle: tr('settings.notifications.live_alerts_desc'),
                value: s.liveAlerts && !s.pauseAllNotifications,
                onChanged: s.pauseAllNotifications ? (_) {} : n.setLiveAlerts,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── In-App ────────────────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.notifications.in_app'),
            children: [
              SettingsSwitchTile(
                icon: Icons.music_note_outlined,
                iconColor: const Color(0xFF00B894),
                title: tr('settings.notifications.in_app_sounds'),
                subtitle: tr('settings.notifications.in_app_sounds_desc'),
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
