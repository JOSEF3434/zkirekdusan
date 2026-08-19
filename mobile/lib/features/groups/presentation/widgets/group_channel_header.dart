// lib/features/groups/presentation/widgets/group_channel_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/groups/data/group_repository.dart';
import 'package:mobile/features/groups/domain/group_context_dto.dart';
import 'package:mobile/features/groups/presentation/widgets/group_role_badge.dart';

class GroupChannelHeader extends ConsumerStatefulWidget {
  final GroupContextDto contextDto;
  final VideoChannelSummaryDto? selectedChannel;
  final ValueChanged<VideoChannelSummaryDto>? onChannelSelected;

  const GroupChannelHeader({
    super.key,
    required this.contextDto,
    this.selectedChannel,
    this.onChannelSelected,
  });

  @override
  ConsumerState<GroupChannelHeader> createState() => _GroupChannelHeaderState();
}

class _GroupChannelHeaderState extends ConsumerState<GroupChannelHeader> {
  bool _isSubscribing = false;
  bool _isSubscribed = false;

  Future<void> _toggleSubscribe() async {
    final channel = widget.selectedChannel ?? widget.contextDto.primaryChannel;
    if (channel == null) return;

    setState(() => _isSubscribing = true);
    try {
      final repo = ref.read(groupRepositoryProvider);
      if (_isSubscribed) {
        await repo.unsubscribeFromChannel(widget.contextDto.id, channel.id);
        if (mounted) setState(() => _isSubscribed = false);
      } else {
        await repo.subscribeToChannel(widget.contextDto.id, channel.id);
        if (mounted) setState(() => _isSubscribed = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = widget.contextDto;
    final primaryChannel = widget.selectedChannel ?? group.primaryChannel;
    final channels = group.videoChannels;

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Avatar
              CircleAvatar(
                radius: 36,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: group.avatarUrl != null
                    ? NetworkImage(group.avatarUrl!)
                    : null,
                child: group.avatarUrl == null
                    ? Text(
                        group.name.isNotEmpty
                            ? group.name.substring(0, 1).toUpperCase()
                            : 'G',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Group & Channel Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (group.callerRole != null) ...[
                          const SizedBox(width: 8),
                          GroupRoleBadge(role: group.callerRole!, compact: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (primaryChannel != null)
                      Text(
                        '@${primaryChannel.handle}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${group.membersCount} ${group.membersCount == 1 ? "member" : "members"}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        if (primaryChannel != null) ...[
                          Text(
                            ' • ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          Text(
                            '${primaryChannel.subscribersCount} subscribers',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          Text(
                            '${primaryChannel.videosCount} videos',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (group.description != null && group.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              group.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          // Actions row: Channel Picker (if multiple) + Subscribe/Joined Button
          Row(
            children: [
              if (channels.length > 1) ...[
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<VideoChannelSummaryDto>(
                        value: primaryChannel,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        items: channels.map((c) {
                          return DropdownMenuItem<VideoChannelSummaryDto>(
                            value: c,
                            child: Text(
                              c.name,
                              style: theme.textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (newCh) {
                          if (newCh != null && widget.onChannelSelected != null) {
                            widget.onChannelSelected!(newCh);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (primaryChannel != null)
                FilledButton.tonalIcon(
                  onPressed: _isSubscribing ? null : _toggleSubscribe,
                  icon: _isSubscribing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isSubscribed
                              ? Icons.notifications_active
                              : Icons.notifications_none,
                          size: 18,
                        ),
                  label: Text(_isSubscribed ? 'Subscribed' : 'Subscribe'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
