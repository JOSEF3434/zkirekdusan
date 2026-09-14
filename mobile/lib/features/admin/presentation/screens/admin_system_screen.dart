// lib/features/admin/presentation/screens/admin_system_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';

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
                      title: const Text('Maintenance Mode'),
                      subtitle: const Text('Restrict public app access to administrators only'),
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
                      title: const Text('Open User Registrations'),
                      subtitle: const Text('Allow new visitors to register accounts'),
                      value: _registrationsOpen,
                      onChanged: (val) {
                        setState(() => _registrationsOpen = val);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Require Email Verification'),
                      subtitle: const Text('Require email OTP confirmation before full access'),
                      value: _requireEmailVerification,
                      onChanged: (val) {
                        setState(() => _requireEmailVerification = val);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('AI Content Pre-screening'),
                      subtitle: const Text('Scan posts and media for toxicity before publishing'),
                      value: _aiModerationEnabled,
                      onChanged: (val) {
                        setState(() => _aiModerationEnabled = val);
                      },
                    ),
                  ],
                ),
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
