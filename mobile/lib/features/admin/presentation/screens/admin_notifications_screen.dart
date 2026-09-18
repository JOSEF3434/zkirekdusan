// lib/features/admin/presentation/screens/admin_notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'ALL';
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _handleBroadcast() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('admin.actions.broadcast'))),
        content: Text(
          'Send this alert to ${_selectedRole == 'ALL' ? 'ALL active platform users' : 'users with role $_selectedRole'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('common.cancel'))),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('admin.actions.broadcast'))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSending = true);
    try {
      final ok = await ref.read(adminRepositoryProvider).broadcastNotification(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            targetRole: _selectedRole,
          );

      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Broadcast sent successfully!')),
        );
        _titleController.clear();
        _bodyController.clear();
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.notifications')),
      ),
      body: SingleChildScrollView(
        child: AdminResponsiveLayout(
          child: Column(
            children: [
              AdminSectionCard(
                title: 'Broadcast Announcement',
                subtitle: 'Push system notification to platform users',
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Notification Title *',
                          hintText: 'e.g. Scheduled Maintenance, Important Update',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bodyController,
                        decoration: const InputDecoration(
                          labelText: 'Message Body *',
                          hintText: 'Enter announcement details...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Message is required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Target Audience',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Active Users')),
                          DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('Super Admins Only')),
                          DropdownMenuItem(value: 'ADMIN', child: Text('Admins & Above')),
                          DropdownMenuItem(value: 'MODERATOR', child: Text('Moderators')),
                          DropdownMenuItem(value: 'SUPPORT', child: Text('Support Team')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(_isSending ? 'Sending...' : 'Send Broadcast Notification'),
                        onPressed: _isSending ? null : _handleBroadcast,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



