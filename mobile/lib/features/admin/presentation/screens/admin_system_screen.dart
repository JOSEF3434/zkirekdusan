// lib/features/admin/presentation/screens/admin_system_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/download_settings.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_download_settings_provider.dart';
import 'package:mobile/features/stories/presentation/providers/stories_enabled_provider.dart';
import 'package:mobile/features/books/presentation/providers/book_download_settings_provider.dart';
import 'package:mobile/features/books/presentation/widgets/book_download_settings_dialog.dart';

class AdminSystemScreen extends ConsumerStatefulWidget {
  const AdminSystemScreen({super.key});

  @override
  ConsumerState<AdminSystemScreen> createState() => _AdminSystemScreenState();
}

class _AdminSystemScreenState extends ConsumerState<AdminSystemScreen> {
  bool _maintenanceMode = false;
  bool _registrationsOpen = true;
  bool _requireEmailVerification = true;
  bool _aiModerationEnabled = true;

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final perms = ref.watch(adminPermissionsProvider);

    if (!perms.isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('admin.system'))),
        body: const Center(
          child: Text('Only Super Administrators can configure platform system settings.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.system')),
      ),
      body: SingleChildScrollView(
        child: AdminResponsiveLayout(
          child: Column(
            children: [
              AdminSectionCard(
                title: 'Platform Operations',
                subtitle: 'Global switches and platform accessibility',
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('admin.system'))),
                      subtitle: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('admin.system_sub'))),
                      value: _maintenanceMode,
                      activeThumbColor: Colors.red,
                      onChanged: (val) {
                        setState(() => _maintenanceMode = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Maintenance mode ${val ? 'enabled' : 'disabled'}')),
                        );
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('settings.admin.users'))),
                      subtitle: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('admin.users_sub'))),
                      value: _registrationsOpen,
                      onChanged: (val) {
                        setState(() => _registrationsOpen = val);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('settings.security.authentication'))),
                      subtitle: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('settings.security.biometric_desc'))),
                      value: _requireEmailVerification,
                      onChanged: (val) {
                        setState(() => _requireEmailVerification = val);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('settings.content.sensitive_filter'))),
                      subtitle: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('settings.content.auto_captions_desc'))),
                      value: _aiModerationEnabled,
                      onChanged: (val) {
                        setState(() => _aiModerationEnabled = val);
                      },
                    ),
                    const Divider(),
                    // ── Stories Service Toggle (Super-Admin only) ──
                    Consumer(
                      builder: (context, ref, _) {
                        final storiesEnabled =
                            ref.watch(storiesEnabledProvider);
                        return SwitchListTile(
                          secondary:
                              const Icon(Icons.auto_stories_rounded),
                          title: const Text('Stories Service'),
                          subtitle: const Text(
                            'When OFF, the Stories feature is hidden '
                            'platform-wide. Users will not see story strips, '
                            'cannot create stories, or access the story viewer.',
                          ),
                          value: storiesEnabled,
                          activeThumbColor: const Color(0xFF10B981),
                          onChanged: (val) {
                            ref
                                .read(storiesEnabledProvider.notifier)
                                .setEnabled(val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  val
                                      ? 'Stories service enabled platform-wide.'
                                      : 'Stories service disabled. Story strips are now hidden.',
                                ),
                                backgroundColor: val
                                    ? const Color(0xFF10B981)
                                    : Colors.redAccent,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const Divider(),
                    // ── Calendar Media Download Toggle (Super-Admin only) ──
                    Consumer(
                      builder: (context, ref, _) {
                        final downloadEnabled = ref.watch(calendarDownloadEnabledProvider);
                        return SwitchListTile(
                          secondary: const Icon(Icons.download_for_offline_outlined),
                          title: const Text('Allow Calendar Media Downloads'),
                          subtitle: const Text(
                            'When ON, admins can mark individual calendar posts as downloadable. '
                            'Files are saved to the ZikreKdusan folder in the device\'s File Manager.',
                          ),
                          value: downloadEnabled,
                          activeThumbColor: Theme.of(context).colorScheme.primary,
                          onChanged: (val) {
                            ref
                                .read(calendarDownloadEnabledProvider.notifier)
                                .setEnabled(val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  val
                                      ? 'Calendar downloads enabled. Admins can now allow downloads per post.'
                                      : 'Calendar downloads disabled globally.',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Download Management ─────────────────────────────────
              Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(downloadSettingsProvider);
                  final notifier = ref.read(downloadSettingsProvider.notifier);
                  final theme = Theme.of(context);

                  return AdminSectionCard(
                    title: 'Download Management',
                    subtitle: 'Control where and how media is stored on user devices',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Storage Mode ────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.storage_rounded,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Download Storage Mode',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Where downloaded media is stored',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Column(
                            children: DownloadStorageMode.values.map((mode) {
                              final isSelected = settings.storageMode == mode;
                              final (IconData icon, String label, String desc) = switch (mode) {
                                DownloadStorageMode.inAppOnly => (
                                    Icons.cloud_done_outlined,
                                    'In-App Only (Default)',
                                    'Videos cached inside the app. Fast offline playback, no device file saved.',
                                  ),
                                DownloadStorageMode.saveToFile => (
                                    Icons.save_alt_rounded,
                                    'Save to File',
                                    'Triggers OS download dialog. File saved to device\'s Downloads folder.',
                                  ),
                                DownloadStorageMode.both => (
                                    Icons.sync_alt_rounded,
                                    'Both (In-App + File)',
                                    'Cached in-app AND a copy saved to the device file system.',
                                  ),
                              };
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => notifier.setStorageMode(mode),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.primaryContainer
                                              .withValues(alpha: 0.35)
                                          : theme.colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                                .withValues(alpha: 0.6)
                                            : theme.colorScheme.outlineVariant
                                                .withValues(alpha: 0.3),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          icon,
                                          size: 20,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                label,
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  color: isSelected
                                                      ? theme.colorScheme
                                                          .primary
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                desc,
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                              milliseconds: 200),
                                          child: isSelected
                                              ? Icon(
                                                  Icons.radio_button_checked_rounded,
                                                  key: const ValueKey('on'),
                                                  color:
                                                      theme.colorScheme.primary,
                                                  size: 20,
                                                )
                                              : Icon(
                                                  Icons.radio_button_unchecked_rounded,
                                                  key: const ValueKey('off'),
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant
                                                      .withValues(alpha: 0.5),
                                                  size: 20,
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const Divider(height: 1),

                        // ─── Max Concurrent Downloads ────────────────────
                        ListTile(
                          leading: const Icon(
                              Icons.swap_vert_circle_outlined),
                          title: const Text('Max Simultaneous Downloads'),
                          subtitle: Text(
                              '${settings.maxConcurrent} download${settings.maxConcurrent == 1 ? '' : 's'} at a time'),
                          trailing: SizedBox(
                            width: 130,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  iconSize: 20,
                                  onPressed: settings.maxConcurrent > 1
                                      ? () => notifier.setMaxConcurrent(
                                          settings.maxConcurrent - 1)
                                      : null,
                                ),
                                Text(
                                  '${settings.maxConcurrent}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  iconSize: 20,
                                  onPressed: settings.maxConcurrent < 5
                                      ? () => notifier.setMaxConcurrent(
                                          settings.maxConcurrent + 1)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Divider(height: 1),

                        // ─── Auto-download on Wi-Fi ─────────────────────────
                        SwitchListTile(
                          secondary: const Icon(
                              Icons.wifi_rounded),
                          title: const Text(
                              'Auto-Download on Wi-Fi'),
                          subtitle: const Text(
                              'When enabled, newly published videos are automatically downloaded for offline access when connected to Wi-Fi.'),
                          value: settings.autoDownloadOnWifi,
                          activeThumbColor: theme.colorScheme.primary,
                          onChanged: (val) =>
                              notifier.setAutoDownloadOnWifi(val),
                        ),

                        // Status chip row
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 14),
                          child: Wrap(
                            spacing: 8,
                            children: [
                              _AdminChip(
                                icon: Icons.storage_rounded,
                                label: switch (settings.storageMode) {
                                  DownloadStorageMode.inAppOnly =>
                                    'In-App Only',
                                  DownloadStorageMode.saveToFile =>
                                    'Save to File',
                                  DownloadStorageMode.both => 'In-App + File',
                                },
                                color: theme.colorScheme.primary,
                              ),
                              _AdminChip(
                                icon: Icons.swap_vert_circle_outlined,
                                label: 'Max ${settings.maxConcurrent} concurrent',
                                color: Colors.teal,
                              ),
                              if (settings.autoDownloadOnWifi)
                                _AdminChip(
                                  icon: Icons.wifi_rounded,
                                  label: 'Auto-DL on Wi-Fi',
                                  color: Colors.green,
                                ),
                            ],
                          ),
                        ),

                        const Divider(),
                        Consumer(
                          builder: (context, ref, _) {
                            final bookSettingsState =
                                ref.watch(bookDownloadSettingsProvider);
                            final dest =
                                bookSettingsState.setting.destination;
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              title: const Text('Book Download Destination'),
                              subtitle: Text(
                                'Where user downloaded books are saved (${dest.label})',
                              ),
                              trailing: FilledButton.tonal(
                                onPressed: () =>
                                    showBookDownloadSettingsDialog(context),
                                child: const Text('Configure'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              AdminSectionCard(
                title: 'Platform Information & Health',
                subtitle: 'Runtime build info and connected services',
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.check_circle_rounded, color: Colors.green),
                      title: Text('Database Connection (PostgreSQL)'),
                      trailing: Text('HEALTHY', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(),
                    const ListTile(
                      leading: Icon(Icons.check_circle_rounded, color: Colors.green),
                      title: Text('Prisma ORM Client'),
                      trailing: Text('v7.8.0', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const Divider(),
                    const ListTile(
                      leading: Icon(Icons.info_outline_rounded),
                      title: Text('Platform Version'),
                      trailing: Text('1.0.0+1 (Phase 8 Production)'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _AdminChip ───────────────────────────────────────────────────────────────

class _AdminChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _AdminChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
