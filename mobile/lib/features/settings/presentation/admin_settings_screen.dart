// lib/features/settings/presentation/admin_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile/features/admin/presentation/screens/admin_dashboard_screen.dart';

/// Legacy shim directing to the complete Administration System
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminDashboardScreen();
  }
}
