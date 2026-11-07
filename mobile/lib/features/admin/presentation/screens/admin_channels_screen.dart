// lib/features/admin/presentation/screens/admin_channels_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_search_bar.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_confirmation_dialog.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';

class AdminChannelsScreen extends ConsumerStatefulWidget {
  const AdminChannelsScreen({super.key});

  @override
  ConsumerState<AdminChannelsScreen> createState() => _AdminChannelsScreenState();
}

class _AdminChannelsScreenState extends ConsumerState<AdminChannelsScreen> {
  final List<AdminChannelItemDto> _channels = [];
  bool _isLoading = false;
  String _search = '';
  String _statusFilter = 'ALL';

  final List<String> _statusOptions = [
    'ALL',
    'PENDING',
    'APPROVED',
    'ACTIVE',
    'SUSPENDED',
    'REJECTED',
  ];

  @override
  void initState() {
    super.initState();
    _fetchChannels();
  }

  Future<void> _fetchChannels([String? search]) async {
    if (search != null) _search = search;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.getChannels(
        search: _search.isEmpty ? null : _search,
        status: _statusFilter == 'ALL' ? null : _statusFilter,
      );
      final rawItems = res['items'];
      final List<AdminChannelItemDto> items = rawItems is List<AdminChannelItemDto>
          ? rawItems
          : ((rawItems as List?) ?? []).whereType<AdminChannelItemDto>().toList();
      setState(() {
        _channels.clear();
        _channels.addAll(items);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load channels: $e')),
        );
      }
    }
  }

  Future<void> _approveChannel(AdminChannelItemDto item) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Approve Channel Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Approve "${item.name}" (@${item.handle})? This will make the channel publicly discoverable and enable content broadcasting.'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Review Notes (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await ref.read(adminRepositoryProvider).approveChannel(
            item.id,
            notes: notesController.text.trim().isNotEmpty
                ? notesController.text.trim()
                : null,
          );
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Channel "${item.name}" approved successfully!')),
        );
        _fetchChannels();
      }
    }
  }

  Future<void> _rejectChannel(AdminChannelItemDto item) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Reject Channel Request'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please provide a reason for rejecting "${item.name}". The channel creator will be notified of this reason.'),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason *',
                  hintText: 'e.g. Inappropriate handle or duplicate channel name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Rejection reason is required'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await ref.read(adminRepositoryProvider).rejectChannel(
            item.id,
            reason: reasonController.text.trim(),
          );
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Channel "${item.name}" has been rejected.')),
        );
        _fetchChannels();
      }
    }
  }

  Future<void> _suspendChannel(AdminChannelItemDto item) async {
    final reason = await AdminConfirmationDialog.show(
      context,
      title: 'Suspend Channel',
      message: 'Suspend broadcasting for "${item.name}" (@${item.handle})? Content will become hidden from public discovery.',
      confirmColor: Colors.orange,
      requireReason: true,
    );

    if (reason != null && mounted) {
      final ok = await ref.read(adminRepositoryProvider).suspendChannel(
            item.id,
            reason: reason,
          );
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Channel "${item.name}" suspended.')),
        );
        _fetchChannels();
      }
    }
  }

  Future<void> _activateChannel(AdminChannelItemDto item) async {
    final ok = await ref.read(adminRepositoryProvider).activateChannel(item.id);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Channel "${item.name}" activated.')),
      );
      _fetchChannels();
    }
  }

  Future<void> _deleteChannel(String id, String name) async {
    final reason = await AdminConfirmationDialog.show(
      context,
      title: 'Delete Channel',
      message: 'Are you sure you want to permanently delete channel "$name"? All videos and content will be removed.',
      confirmColor: Colors.red,
      requireReason: true,
    );
    if (reason != null && mounted) {
      final ok = await ref.read(adminRepositoryProvider).deleteChannel(id, reason: reason);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Channel deleted')),
        );
        _fetchChannels();
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.amber[700]!;
      case 'APPROVED':
      case 'ACTIVE':
        return const Color(0xFF10B981);
      case 'SUSPENDED':
        return Colors.orange;
      case 'REJECTED':
      case 'DISABLED':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.channels')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _fetchChannels(),
          ),
        ],
      ),
      body: AdminResponsiveLayout(
        child: Column(
          children: [
            // Search Bar
            AdminSearchBar(
              hintText: 'Search channels by name, handle, or description...',
              onSearch: (val) {
                _fetchChannels(val);
              },
            ),
            const SizedBox(height: 12),

            // Status Filter Tabs
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _statusOptions.length,
                itemBuilder: (context, index) {
                  final status = _statusOptions[index];
                  final isSelected = _statusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status),
                      selected: isSelected,
                      selectedColor: const Color(0xFF00C6FF).withValues(alpha: 0.25),
                      checkmarkColor: const Color(0xFF00C6FF),
                      onSelected: (val) {
                        setState(() => _statusFilter = status);
                        _fetchChannels();
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Channels List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C6FF)))
                  : _channels.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.campaign_outlined, size: 56, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                'No channels found for "$_statusFilter"',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(tr('admin.no_records'), style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _channels.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _channels[index];
                            final statusColor = _getStatusColor(item.status);

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                              color: isDark ? const Color(0xFF17212B) : Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: Avatar, Name, Handle, Status Pill
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: const Color(0xFFFF0055).withValues(alpha: 0.15),
                                          backgroundImage: item.avatarUrl != null && item.avatarUrl!.isNotEmpty
                                              ? CachedNetworkImageProvider(item.avatarUrl!)
                                              : null,
                                          child: item.avatarUrl == null || item.avatarUrl!.isEmpty
                                              ? const Icon(Icons.campaign_rounded, color: Color(0xFFFF0055), size: 24)
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      item.name.isNotEmpty ? item.name : item.slug,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (item.isVerified) ...[
                                                    const SizedBox(width: 4),
                                                    const Icon(Icons.verified, color: Color(0xFF00C6FF), size: 16),
                                                  ],
                                                ],
                                              ),
                                              Text(
                                                item.handle.isNotEmpty
                                                    ? (item.handle.startsWith('@') ? item.handle : '@${item.handle}')
                                                    : '@${item.slug}',
                                                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                          ),
                                          child: Text(
                                            item.status,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Owner and Statistics
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 6,
                                      children: [
                                        if (item.ownerUsername != null)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.person_outline, size: 15, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text('Owner: @${item.ownerUsername}', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                                            ],
                                          ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.people_outline, size: 15, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text('${item.subscribersCount} subs', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.video_library_outlined, size: 15, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text('${item.videosCount} videos', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(DateFormat('MMM d, y').format(item.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Rejection Reason if any
                                    if (item.rejectionReason != null && item.rejectionReason!.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          'Rejection Reason: ${item.rejectionReason}',
                                          style: TextStyle(color: isDark ? Colors.red[200] : Colors.red[900], fontSize: 12),
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 14),
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),

                                    // Action buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // View / Inspect
                                        TextButton.icon(
                                          onPressed: () => context.push('/channel/${item.id}'),
                                          icon: const Icon(Icons.visibility_outlined, size: 16),
                                          label: const Text('View'),
                                        ),

                                        // Status-specific workflow actions
                                        if (item.status == 'PENDING') ...[
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: () => _approveChannel(item),
                                            icon: const Icon(Icons.check, size: 16),
                                            label: const Text('Approve'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF10B981),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            onPressed: () => _rejectChannel(item),
                                            icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                                            label: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Colors.redAccent),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                          ),
                                        ] else if (item.status == 'APPROVED' || item.status == 'ACTIVE') ...[
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            onPressed: () => _suspendChannel(item),
                                            icon: const Icon(Icons.pause, size: 16, color: Colors.orange),
                                            label: const Text('Suspend', style: TextStyle(color: Colors.orange)),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Colors.orange),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                          ),
                                        ] else if (item.status == 'SUSPENDED') ...[
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: () => _activateChannel(item),
                                            icon: const Icon(Icons.play_arrow, size: 16),
                                            label: const Text('Activate'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF00C6FF),
                                              foregroundColor: Colors.black,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                          ),
                                        ],

                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                          tooltip: 'Delete Channel',
                                          onPressed: () => _deleteChannel(item.id, item.name),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
