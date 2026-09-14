// lib/features/admin/presentation/screens/admin_spam_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';

class AdminSpamScreen extends ConsumerStatefulWidget {
  const AdminSpamScreen({super.key});

  @override
  ConsumerState<AdminSpamScreen> createState() => _AdminSpamScreenState();
}

class _AdminSpamScreenState extends ConsumerState<AdminSpamScreen> {
  final List<String> _blockedKeywords = [
    'crypto giveaway',
    'free bitcoin',
    'whatsapp donation',
    'telegram bot link',
    'lottery prize winner',
  ];
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addKeyword() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !_blockedKeywords.contains(text.toLowerCase())) {
      setState(() {
        _blockedKeywords.add(text.toLowerCase());
        _controller.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "$text" to spam blacklist')),
      );
    }
  }

  void _removeKeyword(String keyword) {
    setState(() {
      _blockedKeywords.remove(keyword);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.spam')),
      ),
      body: SingleChildScrollView(
        child: AdminResponsiveLayout(
          child: Column(
            children: [
              AdminSectionCard(
                title: 'Add Blocked Keyword / Pattern',
                subtitle: 'Messages or posts containing these phrases will be automatically flagged',
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Enter word or phrase...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addKeyword(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _addKeyword,
                      child: const Text('Add Term'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              AdminSectionCard(
                title: 'Active Blacklist (${_blockedKeywords.length} rules)',
                subtitle: 'Monitored across comments, posts, and chats',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _blockedKeywords.map((k) {
                    return Chip(
                      label: Text(k),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeKeyword(k),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
