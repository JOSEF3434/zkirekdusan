// lib/features/creator_analytics/presentation/screens/creator_video_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/creator_analytics/domain/creator_video_dto.dart';
import 'package:mobile/features/creator_analytics/domain/update_video_form.dart';
import 'package:mobile/features/creator_analytics/presentation/providers/creator_video_list_provider.dart';

class CreatorVideoEditScreen extends ConsumerStatefulWidget {
  final String channelId;
  final String videoId;
  final CreatorVideoDto? initialVideo;

  const CreatorVideoEditScreen({
    super.key,
    required this.channelId,
    required this.videoId,
    this.initialVideo,
  });

  @override
  ConsumerState<CreatorVideoEditScreen> createState() =>
      _CreatorVideoEditScreenState();
}

class _CreatorVideoEditScreenState
    extends ConsumerState<CreatorVideoEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late CreatorVideoVisibility _visibility;
  late String _downloadPerm;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialVideo?.title ?? '');
    _descCtrl = TextEditingController(
      text: widget.initialVideo?.description ?? '',
    );
    _visibility =
        widget.initialVideo?.visibility ?? CreatorVideoVisibility.private;
    _downloadPerm = widget.initialVideo?.downloadPermission ?? 'MEMBERS_ONLY';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final form = UpdateVideoForm(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        visibility: _visibility.value,
        downloadPermission: _downloadPerm,
      );

      // Need a way to call update on the provider.
      // Easiest is to construct args assuming no filters, though this could be brittle if list is filtered.
      // A better way is using the repo directly and invalidating, or having a dedicated detail provider.
      // For now, we'll use a generic args to get the provider instance and call update.
      final args = VideoListArgs(channelId: widget.channelId);
      await ref
          .read(creatorVideoListProvider(args).notifier)
          .updateVideo(widget.videoId, form);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Video updated')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Video'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              const Text(
                'Visibility',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<CreatorVideoVisibility>(
                initialValue: _visibility,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: CreatorVideoVisibility.values.map((v) {
                  return DropdownMenuItem(value: v, child: Text(v.value));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _visibility = val);
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Download Permission',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _downloadPerm,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                    value: 'MEMBERS_ONLY',
                    child: Text('Members Only'),
                  ),
                  DropdownMenuItem(value: 'ALL', child: Text('All Users')),
                  DropdownMenuItem(value: 'NONE', child: Text('Disabled')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _downloadPerm = val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
