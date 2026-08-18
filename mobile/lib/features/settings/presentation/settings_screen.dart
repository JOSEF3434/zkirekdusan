import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'ADMIN' || user?.role == 'SUPER_ADMIN';

    return Scaffold(
      appBar: AppBar(title: Text(tr('settings.title'))),
      body: ListView(
        children: [
          _SettingsSection(
            title: tr('settings.account'),
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(tr('settings.profile')),
                onTap: () => context.push('/profile'),
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: Text(tr('settings.security')),
                onTap: () {},
              ),
            ],
          ),
          _SettingsSection(
            title: tr('settings.appearance'),
            children: [
              ListTile(
                leading: const Icon(Icons.color_lens_outlined),
                title: Text(tr('settings.appearance')),
                onTap: () => context.push('/settings/appearance'),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(tr('settings.language')),
                onTap: () => context.push('/settings/language'),
              ),
            ],
          ),
          _SettingsSection(
            title: tr('settings.privacy'),
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(tr('settings.privacy')),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(tr('settings.notifications')),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(tr('settings.content_preferences')),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(tr('playback.title')),
                onTap: () => context.push('/settings/playback'),
              ),
            ],
          ),
          _SettingsSection(
            title: tr('settings.downloads'),
            children: [
              ListTile(
                leading: const Icon(Icons.download_done),
                title: Text(tr('settings.downloads')),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.data_usage),
                title: Text(tr('settings.data_usage')),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep),
                title: Text(tr('settings.cache')),
                onTap: () {},
              ),
            ],
          ),
          if (isAdmin)
            _SettingsSection(
              title: tr('settings.admin'),
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    tr('settings.admin.system'),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () => context.push('/settings/admin'),
                ),
              ],
            ),
          const SizedBox(height: 32),
          Center(
            child: TextButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Log Out', style: TextStyle(color: Colors.red)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }
}
