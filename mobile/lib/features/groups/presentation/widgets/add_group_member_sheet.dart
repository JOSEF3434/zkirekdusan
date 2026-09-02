// lib/features/groups/presentation/widgets/add_group_member_sheet.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/chats/presentation/providers/conversations_provider.dart';
import 'package:mobile/features/groups/data/group_repository.dart';
import 'package:mobile/features/groups/domain/group_enums.dart';
import 'package:mobile/features/groups/presentation/providers/group_members_provider.dart';

class AddGroupMemberSheet extends ConsumerStatefulWidget {
  final String groupId;

  const AddGroupMemberSheet({super.key, required this.groupId});

  static Future<void> show(BuildContext context, String groupId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddGroupMemberSheet(groupId: groupId),
    );
  }

  @override
  ConsumerState<AddGroupMemberSheet> createState() =>
      _AddGroupMemberSheetState();
}

class _AddGroupMemberSheetState extends ConsumerState<AddGroupMemberSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  final Set<String> _selectedUserIds = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final discoveryAsync = ref.watch(chatDiscoveryProvider);
    final membersState = ref.watch(groupMembersProvider(widget.groupId));
    final existingMemberIds = membersState.members.map((m) => m.userId).toSet();

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1621) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drag Handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Add Members',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedUserIds.isNotEmpty)
                    TextButton(
                      onPressed: _isSubmitting ? null : _addSelectedMembers,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Add (${_selectedUserIds.length})',
                              style: const TextStyle(
                                color: Color(0xFF00C6FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF00C6FF),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF17212B)
                      : Colors.grey.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),

            // Users List
            Expanded(
              child: discoveryAsync.when(
                data: (disc) {
                  final availableUsers = disc.allUsers.where((u) {
                    final matchesQuery = _query.isEmpty ||
                        u.displayName.toLowerCase().contains(_query) ||
                        (u.username != null &&
                            u.username!.toLowerCase().contains(_query));
                    return matchesQuery && !existingMemberIds.contains(u.id);
                  }).toList();

                  if (availableUsers.isEmpty) {
                    return Center(
                      child: Text(
                        _query.isEmpty
                            ? 'All available contacts are already members'
                            : 'No contacts matching "$_query"',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: availableUsers.length,
                    itemBuilder: (context, index) {
                      final user = availableUsers[index];
                      final isSelected = _selectedUserIds.contains(user.id);

                      return ListTile(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedUserIds.remove(user.id);
                            } else {
                              _selectedUserIds.add(user.id);
                            }
                          });
                        },
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              const Color(0xFF00C6FF).withValues(alpha: 0.2),
                          backgroundImage: user.avatarUrl != null &&
                                  user.avatarUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null ||
                                  user.avatarUrl!.isEmpty
                              ? Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Color(0xFF00C6FF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          user.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: user.username != null
                            ? Text(
                                '@${user.username}',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              )
                            : null,
                        trailing: Checkbox(
                          value: isSelected,
                          activeColor: const Color(0xFF00C6FF),
                          checkColor: Colors.black,
                          shape: const CircleBorder(),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedUserIds.add(user.id);
                              } else {
                                _selectedUserIds.remove(user.id);
                              }
                            });
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00C6FF)),
                ),
                error: (err, stack) => Center(
                  child: Text('Error: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSelectedMembers() async {
    if (_selectedUserIds.isEmpty) return;

    setState(() => _isSubmitting = true);
    final repo = ref.read(groupRepositoryProvider);

    try {
      for (final userId in _selectedUserIds) {
        // Invite/add each member
        try {
          await repo.updateMemberRole(widget.groupId, userId, GroupRole.member);
        } catch (_) {}
      }

      await ref
          .read(groupMembersProvider(widget.groupId).notifier)
          .refresh();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedUserIds.length} member(s) added!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add members: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
