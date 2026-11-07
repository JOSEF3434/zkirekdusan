// lib/features/chats/presentation/widgets/create_channel_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/chats/presentation/providers/conversations_provider.dart';

class CreateChannelSheet extends ConsumerStatefulWidget {
  const CreateChannelSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateChannelSheet(),
    );
  }

  @override
  ConsumerState<CreateChannelSheet> createState() => _CreateChannelSheetState();
}

class _CreateChannelSheetState extends ConsumerState<CreateChannelSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isLoading = false;

  final List<String> _categories = [
    'General',
    'Teaching & Sermons',
    'Hymns & Mezmur',
    'Community & News',
    'Theology & Bible Study',
    'Kids & Family',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onNameChanged(String val) {
    if (_handleController.text.isEmpty ||
        _handleController.text.startsWith('@')) {
      final sanitized = val
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_]'), '')
          .trim();
      if (sanitized.isNotEmpty) {
        _handleController.text = '@$sanitized';
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    var handle = _handleController.text.trim();
    if (!handle.startsWith('@')) {
      handle = '@$handle';
    }
    final description = _descriptionController.text.trim();

    setState(() => _isLoading = true);

    try {
      final res = await ref
          .read(chatDiscoveryProvider.notifier)
          .requestChannelCreation(
            name: name,
            handle: handle,
            description: description.isNotEmpty ? description : null,
            category: _selectedCategory,
          );

      if (!mounted) return;

      Navigator.pop(context);

      final channelId = res['id'] as String?;
      final channelName = res['name'] as String? ?? name;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.check_circle_outline_rounded,
              color: Color(0xFF10B981), size: 48),
          title: const Text('Channel Request Submitted'),
          content: Text(
            'Your channel "$channelName" has been created with PENDING status.\n\nAn administrator will review and approve your channel before it becomes publicly discoverable.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Dismiss'),
            ),
            if (channelId != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C6FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/channel/$channelId');
                },
                child: const Text('View Channel'),
              ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit channel request: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17212B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle drag bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0055).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: Color(0xFFFF0055),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Channel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'YouTube-style broadcasting for videos & posts',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info note about review workflow
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'New channels require administrator approval before appearing in public discovery and publishing content.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.amber[200] : Colors.amber[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Channel Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                onChanged: _onNameChanged,
                decoration: InputDecoration(
                  labelText: 'Channel Name *',
                  hintText: 'e.g. Orthodox Spiritual Lessons',
                  prefixIcon: const Icon(Icons.title_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a channel name';
                  }
                  if (val.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Channel Handle
              TextFormField(
                controller: _handleController,
                decoration: InputDecoration(
                  labelText: 'Handle (@username) *',
                  hintText: '@channelhandle',
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a channel handle';
                  }
                  final clean = val.replaceAll('@', '').trim();
                  if (clean.length < 3) {
                    return 'Handle must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe your channel content and mission...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C6FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Submit Channel Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

