// lib/features/live/presentation/widgets/scheduled_live_card_widget.dart
// Modern card for upcoming scheduled live streams with multi-interval reminder bell.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/presentation/widgets/app_network_image.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/presentation/services/live_notification_service.dart';

class ScheduledLiveCardWidget extends ConsumerWidget {
  final LiveStreamDto stream;

  const ScheduledLiveCardWidget({super.key, required this.stream});

  String _formatCountdown(DateTime scheduledTime) {
    final now = DateTime.now();
    final diff = scheduledTime.difference(now);

    if (diff.isNegative) {
      return 'Starting soon';
    }
    if (diff.inDays > 1) {
      return 'Starts in ${diff.inDays} days';
    } else if (diff.inDays == 1) {
      return 'Starts tomorrow at ${DateFormat.jm().format(scheduledTime)}';
    } else if (diff.inHours > 0) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      return 'Starts in ${hours}h ${minutes}m';
    } else if (diff.inMinutes > 0) {
      return 'Starts in ${diff.inMinutes} minutes';
    } else {
      return 'Starting any moment';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheduledDate = stream.scheduledAt != null
        ? DateTime.tryParse(stream.scheduledAt!)
        : null;

    final reminders = ref.watch(liveRemindersStateProvider);
    final hasReminder = reminders.contains(stream.id);
    final currentUserId = ref.watch(authProvider).user?.id;
    final isCreator = currentUserId != null && currentUserId == stream.createdById;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail Banner with Countdown Overlay ─────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: stream.thumbnailUrl != null
                    ? AppNetworkImage(
                        imageUrl: stream.thumbnailUrl!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _fallbackBanner(),
                      )
                    : _fallbackBanner(),
              ),

              // Gradient shade overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Scheduled Badge (Top Left)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'SCHEDULED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Countdown Pill (Bottom Left)
              if (scheduledDate != null)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: Colors.amberAccent),
                        const SizedBox(width: 6),
                        Text(
                          _formatCountdown(scheduledDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Exact Scheduled Date & Time (Bottom Right)
              if (scheduledDate != null)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormat('MMM d, h:mm a').format(scheduledDate),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Stream Info Section ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  stream.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),

                // Channel Info Row
                _buildChannelInfo(theme),

                // Categories
                if (stream.categories.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: stream.categories.take(3).map((c) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // ── Action Buttons Row ────────────────────────────────────────
                Row(
                  children: [
                    // Remind Me Button
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          final nowSet = await ref
                              .read(liveRemindersStateProvider.notifier)
                              .toggle(stream);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  nowSet
                                      ? '🔔 Reminder set! You will be notified 1 day, 5h, 1h, 30m before and at start time.'
                                      : '🔕 Reminder cancelled.',
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: hasReminder
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          foregroundColor: hasReminder
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          hasReminder
                              ? Icons.notifications_active_rounded
                              : Icons.notification_add_outlined,
                          size: 18,
                        ),
                        label: Text(
                          hasReminder ? 'Reminder Set' : 'Remind Me',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    // If user is creator: quick Go To Studio / Start Live button
                    if (isCreator) ...[
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () => context.push('/live/studio'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.videocam_rounded, size: 18),
                        label: const Text(
                          'Start Live',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
    );
  }

  Widget _fallbackBanner() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.calendar_month_rounded, color: Colors.white30, size: 48),
      ),
    );
  }

  Widget _buildChannelInfo(ThemeData theme) {
    final channelName =
        stream.videoChannel?.name ?? stream.group?.name ?? 'Live Channel';
    final avatarUrl = stream.videoChannel?.avatarUrl;

    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundImage:
              avatarUrl != null ? AppNetworkImage.provider(avatarUrl) : null,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          child: avatarUrl == null
              ? Text(
                  channelName.isNotEmpty ? channelName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            channelName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
