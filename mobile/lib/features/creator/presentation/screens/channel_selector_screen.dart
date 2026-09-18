import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/creator/domain/creator_group_dto.dart';
import 'package:mobile/features/creator/domain/creator_permission_service.dart';
import 'package:mobile/features/creator/presentation/providers/channel_selector_provider.dart';
import 'package:mobile/features/creator/presentation/widgets/creator_empty_state.dart';
import 'package:mobile/features/creator/presentation/widgets/creator_error_state.dart';
import 'package:mobile/features/creator/presentation/widgets/creator_loading_skeleton.dart';
import 'package:mobile/features/upload/presentation/providers/upload_provider.dart';
import 'package:mobile/features/upload/domain/group_channel_model.dart';

class ChannelSelectorScreen extends ConsumerWidget {
  final CreatorGroupDto group;

  const ChannelSelectorScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(channelSelectorProvider(group));
    final permissionService = ref.watch(creatorPermissionServiceProvider);

    final canCreateChannel = permissionService.canCreateChannel(group);

    return Scaffold(
      appBar: AppBar(
        title: Text('${group.name} Channels'),
        actions: [
          if (canCreateChannel)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateChannelSheet(context, ref),
              tooltip: 'Create Channel',
            ),
        ],
      ),
      body: _buildBody(context, ref, state, permissionService),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ChannelSelectorState state,
    CreatorPermissionService permissionService,
  ) {
    if (state.isLoading) {
      return const CreatorLoadingSkeleton();
    }

    if (state.error != null) {
      return CreatorErrorState(
        error: state.error!,
        onRetry: () =>
            ref.read(channelSelectorProvider(group).notifier).refresh(),
      );
    }

    if (state.channels.isEmpty) {
      return CreatorEmptyState(
        title: 'No Channels Found',
        message: 'This group doesn\'t have any active video channels yet.',
        buttonText: 'Create Channel',
        onAction: () {
          if (permissionService.canCreateChannel(group)) {
            _showCreateChannelSheet(context, ref);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Only group admins can create channels.'),
              ),
            );
          }
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(channelSelectorProvider(group).notifier).refresh(),
      child: ListView.builder(
        itemCount: state.channels.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final channel = state.channels[index];
          final canUpload = permissionService.canUploadToChannel(
            group,
            channel,
          );
          final theme = Theme.of(context);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  channel.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
              title: Text(
                channel.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                canUpload
                    ? 'Ready to upload'
                    : 'Restricted (${channel.uploadPermission.name})',
                style: TextStyle(
                  color: canUpload ? Colors.green : Colors.orange,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.upload, size: 20),
              enabled: canUpload,
              onTap: () {
                if (canUpload) {
                  // Inject the selected group & channel into the upload provider
                  // Map to the simple DTOs used by Upload flow
                  final groupDto = GroupDto(
                    id: group.id,
                    name: group.name,
                    description: group.description,
                  );
                  final channelDto = VideoChannelDto(
                    id: channel.id,
                    groupId: channel.groupId,
                    name: channel.name,
                    description: channel.description,
                    type: 'VOD', // default
                    uploadPermission: channel.uploadPermission
                        .toString()
                        .split('.')
                        .last,
                  );

                  ref
                      .read(uploadProvider.notifier)
                      .preselectChannel(groupDto, channelDto);
                  context.push('/upload');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'You do not have permission to upload to this channel. Requires: ${channel.uploadPermission.name}.',
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _showCreateChannelSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _CreateChannelForm(group: group),
      ),
    );
  }
}

class _CreateChannelForm extends ConsumerStatefulWidget {
  final CreatorGroupDto group;

  const _CreateChannelForm({required this.group});

  @override
  ConsumerState<_CreateChannelForm> createState() => _CreateChannelFormState();
}

class _CreateChannelFormState extends ConsumerState<_CreateChannelForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _handleController = TextEditingController();
  final _descController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _handleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final name = _nameController.text;
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    _slugController.text = base;
    _handleController.text = base.replaceAll('-', '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(channelSelectorProvider(widget.group).notifier)
          .createChannel(
            name: _nameController.text,
            slug: _slugController.text,
            handle: _handleController.text,
            description: _descController.text,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Channel created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Video Channel',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Channel Name',
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(
                labelText: 'Slug (URL friendly)',
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _handleController,
              decoration: const InputDecoration(
                labelText: 'Handle (@username)',
                border: OutlineInputBorder(),
                prefixText: '@',
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Consumer(
                      builder: (_, ref, _) => Text(
                        ref.watch(trProvider)('creator.create_channel_action'),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
