import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final user = ref.watch(authProvider).user;

    // Safety check just in case route protection failed
    if (user?.role != 'ADMIN' && user?.role != 'SUPER_ADMIN') {
      return Scaffold(
        appBar: AppBar(title: Text(tr('settings.admin'))),
        body: Center(child: Text('${tr('state.error')} Access Denied.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('settings.admin')),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.group),
            title: Text(tr('settings.admin.users')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: Text(tr('settings.admin.moderation')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/admin/moderation'),
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: Text(tr('settings.admin.reports')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          if (user?.role == 'SUPER_ADMIN')
            ListTile(
              leading: const Icon(Icons.settings_applications),
              title: Text(tr('settings.admin.system')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
        ],
      ),
    );
  }
}
