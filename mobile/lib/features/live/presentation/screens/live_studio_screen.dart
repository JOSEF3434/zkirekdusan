// lib/features/live/presentation/screens/live_studio_screen.dart
// Broadcaster dashboard: setup, stream key, go-live, health monitoring, end stream.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:apivideo_live_stream/apivideo_live_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/live/data/live_streaming_repository.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/domain/stream_health_model.dart';
import 'package:mobile/features/live/presentation/providers/broadcaster_provider.dart';
import 'package:mobile/features/live/presentation/widgets/live_badge_widget.dart';
import 'package:mobile/app/env/env.dart';
import 'package:mobile/features/live/presentation/widgets/stream_health_indicator.dart';
import 'package:mobile/features/live/presentation/widgets/viewer_count_widget.dart';
import 'package:mobile/features/live/presentation/widgets/live_chat_widget.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/features/upload/domain/group_channel_model.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/live/presentation/providers/live_discovery_provider.dart';
import 'package:mobile/features/live/presentation/services/live_notification_service.dart';
import 'package:mobile/features/upload/data/upload_repository.dart';
import 'package:mobile/features/live/presentation/widgets/live_category_bar.dart';
import 'package:mobile/core/utils/ethiopian_calendar.dart';
import 'package:mobile/features/live/presentation/widgets/live_side_rail.dart';

// ─── Studio Channel Item (YouTube style) ──────────────────────────────────────

class LiveStudioChannelItem {
  final VideoChannelDto channel;
  final GroupDto group;

  const LiveStudioChannelItem({required this.channel, required this.group});

  String get displayName => channel.name.isNotEmpty ? channel.name : group.name;
  String get groupName => group.name;
  String? get avatarUrl =>
      channel.avatarUrl ?? group.avatarUrl ?? group.coverUrl;
  String? get handle => channel.handle;
}

class LiveStudioScreen extends ConsumerStatefulWidget {
  /// Optional pre-selected channelId. If null, the user picks from a dropdown.
  final String? channelId;

  const LiveStudioScreen({super.key, this.channelId});

  @override
  ConsumerState<LiveStudioScreen> createState() => _LiveStudioScreenState();
}

class _LiveStudioScreenState extends ConsumerState<LiveStudioScreen> {
  // Setup form controllers (shown before stream exists)
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isChatEnabled = true;
  bool _isRecordingEnabled = true;
  bool _isVideoStream = true;
  bool _isMicMuted = false;
  bool _isFrontCamera = true;
  bool _isCreating = false;
  String? _createError;
  bool _keyVisible = false;

  // Scheduling & Category state
  bool _isScheduled = false;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 18, minute: 0);
  String? _selectedCategory;
  bool _notifyAllUsers = false; // Default false per user requirement

  // Camera & Streaming hardware state (apivideo_live_stream)
  ApiVideoLiveStreamController? _liveStreamController;
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = true;
  bool _isTorchOn = false;
  bool _isInitializingCamera = false;
  bool _isStreamingRtmp = false;
  String? _streamingError;
  String? _lastStreamKey;

  // Channel picker state (YouTube style)
  List<LiveStudioChannelItem> _availableChannels = [];
  List<GroupDto> _myGroups = [];
  LiveStudioChannelItem? _selectedChannelItem;
  bool _loadingChannels = false;
  String? _loadError;

  // Set after stream is created
  String? _streamId;

  @override
  void initState() {
    super.initState();
    if (widget.channelId == null) {
      _loadChannels();
    }
    _setupCamera(front: true);
  }


  @override
  void dispose() {
    _stopRtmpBroadcast();
    _liveStreamController?.stop();
    _liveStreamController?.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ─── apivideo_live_stream callbacks ──────────────────────────────
  void _onConnectionSuccess() {
    if (mounted) {
      setState(() {
        _isStreamingRtmp = true;
        _streamingError = null;
      });
    }
  }

  void _onConnectionFailed(String reason) {
    if (mounted) {
      setState(() {
        _isStreamingRtmp = false;
        _streamingError = 'RTMP broadcast failed: $reason';
      });
    }
  }

  void _onDisconnection() {
    if (mounted) {
      setState(() {
        _isStreamingRtmp = false;
        _streamingError = 'Disconnected from RTMP broadcast';
      });
    }
  }

  void _onError(Exception error) {
    if (mounted) {
      setState(() {
        _streamingError = 'RTMP stream error: $error';
      });
    }
  }

  Future<void> _loadChannels() async {
    setState(() {
      _loadingChannels = true;
      _loadError = null;
    });
    try {
      final repo = ref.read(uploadRepositoryProvider);
      final groups = await repo.getMyGroups();
      final activeGroups = groups.where((g) => g.status == 'ACTIVE').toList();

      final List<LiveStudioChannelItem> items = [];
      final Set<String> seenIds = {};
      for (final group in activeGroups) {
        try {
          final channels = await repo.getGroupChannels(group.id);
          for (final ch in channels) {
            if (seenIds.add(ch.id)) {
              items.add(LiveStudioChannelItem(channel: ch, group: group));
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _myGroups = activeGroups;
          _availableChannels = items;
          _loadingChannels = false;
          if (widget.channelId != null) {
            _selectedChannelItem = items
                .cast<LiveStudioChannelItem?>()
                .firstWhere(
                  (it) => it?.channel.id == widget.channelId,
                  orElse: () => null,
                );
          } else if (_selectedChannelItem != null) {
            _selectedChannelItem = items
                .cast<LiveStudioChannelItem?>()
                .firstWhere(
                  (it) => it?.channel.id == _selectedChannelItem!.channel.id,
                  orElse: () => items.isNotEmpty ? items.first : null,
                );
          } else if (items.isNotEmpty) {
            _selectedChannelItem = items.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError =
              'Could not load your streaming channels. Please check your connection.';
          _loadingChannels = false;
        });
      }
    }
  }

  String get _effectiveChannelId =>
      widget.channelId ?? _selectedChannelItem?.channel.id ?? '';

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_streamId == null) {
      return _buildSetupPage(context);
    }
    return _buildStudioPage(context, _streamId!);
  }

  // ─── Setup page (create stream) ────────────────────────────────────────────

  Widget _buildSetupPage(BuildContext context) {
    final tr = ref.read(trProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('live.setup_title'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Navigation menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => context.pop(),
          ),
        ],
      ),
      drawer: _buildSideDrawer(context),
      body: Row(
        children: [
          // ── Left circular-icon rail ────────────────────────────────
          const LiveSideRail(activeItem: LiveRailItem.studio),
          // ── Main setup content ────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section header ──
                  Row(
                    children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  tr('live.stream_details'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Channel Picker (YouTube style, only if no channelId pre-supplied) ──
            if (widget.channelId == null) ...[
              _buildChannelPicker(theme),
              const SizedBox(height: 16),
            ],

            // Title
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: tr('live.stream_title_label'),
                hintText: tr('live.stream_title_hint'),
                border: const OutlineInputBorder(),
              ),
              maxLength: 300,
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: tr('live.description_label'),
                hintText: tr('live.description_hint'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 16),

            // ── Broadcast Timing: Go Live Now vs Schedule for Later ──
            Text(
              'Broadcast Timing',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  icon: Icon(Icons.sensors_rounded),
                  label: Text('Go Live Now'),
                ),
                ButtonSegment<bool>(
                  value: true,
                  icon: Icon(Icons.calendar_month_outlined),
                  label: Text('Schedule for Later'),
                ),
              ],
              selected: {_isScheduled},
              onSelectionChanged: (set) {
                setState(() => _isScheduled = set.first);
              },
            ),
            const SizedBox(height: 16),

            // If scheduled, show interactive date & time picker section
            if (_isScheduled) ...[
              _buildSchedulingSection(theme),
            ],

            // ── One-level Category Dropdown with inline Add Category ──
            _buildCategoryDropdown(theme),

            // Stream Type Selector (Video with Camera vs Audio-Only)
            Text(
              tr('live.stream_mode'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment<bool>(
                  value: true,
                  icon: const Icon(Icons.videocam_outlined),
                  label: Text(tr('live.video_stream')),
                ),
                ButtonSegment<bool>(
                  value: false,
                  icon: const Icon(Icons.mic_outlined),
                  label: Text(tr('live.audio_only')),
                ),
              ],
              selected: {_isVideoStream},
              onSelectionChanged: (set) {
                setState(() => _isVideoStream = set.first);
              },
            ),
            const SizedBox(height: 16),

            // ── Checkbox: Notify All Users in Database ──
            _buildNotificationScopeSection(theme),

            // Options
            SwitchListTile(
              title: Text(tr('live.enable_chat')),
              subtitle: Text(tr('live.enable_chat_desc')),
              value: _isChatEnabled,
              onChanged: (v) => setState(() => _isChatEnabled = v),
            ),
            SwitchListTile(
              title: Text(tr('live.enable_recording')),
              subtitle: Text(tr('live.enable_recording_desc')),
              value: _isRecordingEnabled,
              onChanged: (v) => setState(() => _isRecordingEnabled = v),
            ),

            const SizedBox(height: 8),

            if (_createError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _createError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Create button
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isCreating || _loadingChannels
                    ? null
                    : _createStream,
                icon: _isCreating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_isScheduled ? Icons.schedule_send_rounded : Icons.sensors_rounded, size: 20),
                label: Text(
                  _isScheduled ? 'Post Scheduled Live Stream' : tr('live.create_stream'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Side Drawer ─────────────────────────────────────────────────────────────

  Widget _buildSideDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.read(trProvider);
    return Drawer(
      width: 280,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sensors_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Live Studio',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Manage your broadcasts',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Navigation items
            _drawerItem(
              context,
              icon: Icons.live_tv_outlined,
              label: tr('live.title'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/live/discover');
              },
            ),
            _drawerItem(
              context,
              icon: Icons.video_library_outlined,
              label: 'Library',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/library');
              },
            ),
            _drawerItem(
              context,
              icon: Icons.analytics_outlined,
              label: 'Creator Studio',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/creator');
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 8),
            _drawerItem(
              context,
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/settings');
              },
            ),
            const Spacer(),
            // Tips card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        size: 16,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Broadcast Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Use a stable Wi-Fi connection for the best stream quality and minimal drops.',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      horizontalTitleGap: 8,
      onTap: onTap,
    );
  }

  Widget _buildSchedulingSection(ThemeData theme) {
    // Gregorian format for buttons
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(_scheduledDate);
    final timeStr = _scheduledTime.format(context);

    // Ethiopian calendar equivalents
    final ethDateStr = EthiopianCalendar.formatDateAm(_scheduledDate);
    final ethDayName = EthiopianCalendar.dayNameAm(_scheduledDate);
    final ethTimeStr = EthiopianCalendar.formatTimeOfDayAm(
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Stream Schedule Time',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Date picker chip
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickScheduledDate,
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(dateStr, style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              // Time picker chip
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickScheduledTime,
                  icon: const Icon(Icons.access_time_rounded, size: 16),
                  label: Text(timeStr, style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Ethiopian Calendar Display ──────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.primaryContainer,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🇪🇹', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'Ethiopian Calendar (ኢትዮጵያ ቀን)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$ethDayName, $ethDateStr',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ሰዓት: $ethTimeStr',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          EthiopianCalendar.formatDateEn(_scheduledDate),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Notification reminder info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  size: 14,
                  color: Colors.blueAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reminders will fire at: 1 day, 5h, 1h, 30min before & at $ethTimeStr ($timeStr) on $ethDayName',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickScheduledDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _pickScheduledTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null) {
      setState(() => _scheduledTime = picked);
    }
  }

  Widget _buildCategoryDropdown(ThemeData theme) {
    final allCategories = ref.watch(liveCategoriesProvider);
    final displayCategories = allCategories.where((c) => c != 'All').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            TextButton.icon(
              onPressed: () => LiveCategoryBar.showAddCategoryDialog(context, ref),
              icon: const Icon(Icons.add_circle_outline, size: 14),
              label: const Text('Add New Category', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          decoration: InputDecoration(
            hintText: 'Select Stream Category',
            prefixIcon: const Icon(Icons.label_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          items: [
            ...displayCategories.map(
              (cat) => DropdownMenuItem<String>(
                value: cat,
                child: Text(cat, overflow: TextOverflow.ellipsis),
              ),
            ),
            const DropdownMenuItem<String>(
              value: '__add_new__',
              child: Row(
                children: [
                  Icon(Icons.add, size: 16, color: Colors.blueAccent),
                  SizedBox(width: 6),
                  Text(
                    '+ Add New Category',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            if (val == '__add_new__') {
              LiveCategoryBar.showAddCategoryDialog(context, ref);
            } else {
              setState(() => _selectedCategory = val);
            }
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNotificationScopeSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border.all(
          color: _notifyAllUsers
              ? theme.colorScheme.primary.withValues(alpha: 0.6)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: CheckboxListTile(
        value: _notifyAllUsers,
        onChanged: (v) => setState(() => _notifyAllUsers = v ?? false),
        title: const Text(
          'Notify all users in database',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        subtitle: Text(
          _notifyAllUsers
              ? '✅ An immediate broadcast notification will be sent to ALL users in the database, with reminders at 1d, 5h, 1h, 30m before and when you start live.'
              : 'Notifications will be sent only to your channel followers and group members.',
          style: TextStyle(
            fontSize: 11,
            color: _notifyAllUsers
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  void _showScheduledSuccessDialog(LiveStreamDto stream) {
    final theme = Theme.of(context);
    final scheduledDate = stream.scheduledAt != null
        ? DateTime.tryParse(stream.scheduledAt!)
        : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 54,
          ),
          title: const Text(
            'Stream Scheduled!',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stream.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 8),
              if (scheduledDate != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy • h:mm a').format(scheduledDate),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _notifyAllUsers
                          ? '📢 Notification dispatched to ALL users in database'
                          : '🔔 Notification dispatched to channel followers',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Reminders active: 1 day, 5h, 1h, 30m before and at stream start time.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop(); // return to live discovery
              },
              child: const Text('Go to Scheduled Streams'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _streamId = stream.id);
              },
              child: const Text('Open Studio Now'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChannelPicker(ThemeData theme) {

    final tr = ref.read(trProvider);
    if (_loadingChannels && _availableChannels.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              tr('live.loading_channels'),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_loadError != null && _availableChannels.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _loadError!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
            FilledButton.tonal(
              onPressed: _loadChannels,
              child: Text(tr('common.retry')),
            ),
          ],
        ),
      );
    }

    if (_availableChannels.isEmpty) {
      // YouTube-style prompt to create a channel
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.6,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.live_tv,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('live.create_channel_to_live'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr('live.need_channel'),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(tr('creator.create_channel_btn')),
                onPressed: () async {
                  await context.push('/creator/create-group');
                  _loadChannels();
                },
              ),
            ),
          ],
        ),
      );
    }

    // YouTube-style Selected Channel Card
    final selected = _selectedChannelItem ?? _availableChannels.first;
    final initial = selected.displayName.isNotEmpty
        ? selected.displayName[0].toUpperCase()
        : '?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('live.broadcast_channel'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_availableChannels.length > 1)
              TextButton(
                onPressed: _showChannelSwitcherSheet,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(tr('live.switch_channel')),
              ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _availableChannels.length > 1
              ? _showChannelSwitcherSheet
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage:
                      selected.avatarUrl != null &&
                          selected.avatarUrl!.isNotEmpty
                      ? NetworkImage(selected.avatarUrl!)
                      : null,
                  child:
                      selected.avatarUrl == null || selected.avatarUrl!.isEmpty
                      ? Text(
                          initial,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tr('live.channel_badge'),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              selected.groupName,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_availableChannels.length > 1)
                  Icon(
                    Icons.arrow_drop_down_circle_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _confirmAndDeleteChannel(LiveStudioChannelItem item) async {
    final tr = ref.read(trProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (alertCtx) => AlertDialog(
        title: Text(tr('live.delete_channel_title')),
        content: Text(
          tr('live.delete_channel_msg', {'name': item.displayName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(alertCtx).pop(false),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(alertCtx).pop(true),
            child: Text(tr('common.delete')),
          ),
        ],
      ),
    );

    if (confirm != true) return false;

    try {
      final dio = ref.read(apiClientProvider);
      await dio.delete(
        '/groups/${item.group.id}/video-channels/${item.channel.id}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('live.channel_deleted', {'name': item.displayName}),
            ),
          ),
        );
        setState(() {
          _availableChannels.removeWhere(
            (c) => c.channel.id == item.channel.id,
          );
          if (_selectedChannelItem?.channel.id == item.channel.id) {
            _selectedChannelItem = _availableChannels.isNotEmpty
                ? _availableChannels.first
                : null;
          }
        });
        return true;
      }
    } catch (e) {
      if (mounted) {
        final msg = e
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('AppException: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('live.channel_delete_failed', {'error': msg})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return false;
  }

  Future<void> _showCreateChannelDialog() async {
    if (_myGroups.isEmpty) {
      await context.push('/creator/create-group');
      _loadChannels();
      return;
    }

    final tr = ref.read(trProvider);
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final handleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedGroupId =
        _selectedChannelItem?.group.id ?? _myGroups.first.id;
    bool isSubmitting = false;
    String? createErr;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(tr('live.create_video_channel')),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (createErr != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          createErr!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (_myGroups.length > 1) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedGroupId,
                        decoration: InputDecoration(
                          labelText: tr('live.select_group'),
                          border: const OutlineInputBorder(),
                        ),
                        items: _myGroups
                            .map(
                              (g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(
                                  g.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedGroupId = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: tr('live.channel_name_label'),
                        hintText: tr('live.channel_name_hint'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? tr('live.channel_name_required')
                          : null,
                      onChanged: (val) {
                        if (handleCtrl.text.isEmpty ||
                            handleCtrl.text.startsWith('@')) {
                          final clean = val.trim().toLowerCase().replaceAll(
                            RegExp(r'[^a-z0-9_]'),
                            '_',
                          );
                          handleCtrl.text = clean.isNotEmpty ? '@$clean' : '';
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: handleCtrl,
                      decoration: InputDecoration(
                        labelText: tr('live.handle_label'),
                        hintText: tr('live.handle_hint'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return tr('live.handle_required');
                        }
                        if (!val.startsWith('@')) {
                          return tr('live.handle_must_start');
                        }
                        if (val.length < 3) return tr('live.handle_too_short');
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: tr('live.description_optional'),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogCtx).pop(),
                child: Text(tr('common.cancel')),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          isSubmitting = true;
                          createErr = null;
                        });
                        try {
                          final dio = ref.read(apiClientProvider);
                          final name = nameCtrl.text.trim();
                          final rawHandle = handleCtrl.text.trim();
                          final slug =
                              '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '-')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                          final resp = await dio.post(
                            '/groups/$selectedGroupId/video-channels',
                            data: {
                              'name': name,
                              'slug': slug,
                              'handle': rawHandle,
                              if (descCtrl.text.trim().isNotEmpty)
                                'description': descCtrl.text.trim(),
                              'uploadPermission': 'MEMBER',
                              'downloadPermission': 'PUBLIC',
                            },
                          );
                          final newChannel = VideoChannelDto.fromJson(
                            parseEnvelope(resp.data),
                          );
                          final group = _myGroups.firstWhere(
                            (g) => g.id == selectedGroupId,
                            orElse: () => _myGroups.first,
                          );
                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                          if (mounted) {
                            await _loadChannels();
                            setState(() {
                              _selectedChannelItem = LiveStudioChannelItem(
                                channel: newChannel,
                                group: group,
                              );
                            });
                          }
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            createErr = e
                                .toString()
                                .replaceFirst('Exception: ', '')
                                .replaceFirst('AppException: ', '');
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(tr('common.create')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChannelSwitcherSheet() {
    final theme = Theme.of(context);
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filtered = _availableChannels.where((item) {
              if (query.isEmpty) return true;
              return item.displayName.toLowerCase().contains(query) ||
                  item.groupName.toLowerCase().contains(query) ||
                  (item.handle != null &&
                      item.handle!.toLowerCase().contains(query));
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(top: 8, bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Select Channel',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        ),
                      ),
                      if (_availableChannels.length > 3)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: TextField(
                            controller: searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Search channels…',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        searchCtrl.clear();
                                        setSheetState(() {});
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: theme
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (_) => setSheetState(() {}),
                          ),
                        ),
                      const Divider(height: 1),
                      Flexible(
                        child: filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Text(
                                    _availableChannels.isEmpty
                                        ? 'No channels available'
                                        : 'No matching channels found',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1, indent: 68),
                                itemBuilder: (context, i) {
                                  final item = filtered[i];
                                  final isSelected =
                                      _selectedChannelItem?.channel.id ==
                                      item.channel.id;
                                  final initial = item.displayName.isNotEmpty
                                      ? item.displayName[0].toUpperCase()
                                      : '?';

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          theme.colorScheme.primaryContainer,
                                      backgroundImage:
                                          item.avatarUrl != null &&
                                              item.avatarUrl!.isNotEmpty
                                          ? NetworkImage(item.avatarUrl!)
                                          : null,
                                      child:
                                          item.avatarUrl == null ||
                                              item.avatarUrl!.isEmpty
                                          ? Text(
                                              initial,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: theme
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                            )
                                          : null,
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.displayName,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.check_circle,
                                            color: theme.colorScheme.primary,
                                            size: 18,
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (item.handle != null &&
                                            item.handle!.isNotEmpty)
                                          Text(
                                            item.handle!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.primary,
                                              fontFamily: 'monospace',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.group_outlined,
                                              size: 13,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                item.groupName,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: theme.colorScheme.error
                                            .withValues(alpha: 0.7),
                                      ),
                                      tooltip: 'Delete channel',
                                      onPressed: () async {
                                        final deleted =
                                            await _confirmAndDeleteChannel(
                                              item,
                                            );
                                        if (deleted) {
                                          setSheetState(() {});
                                        }
                                      },
                                    ),
                                    onTap: () {
                                      setState(
                                        () => _selectedChannelItem = item,
                                      );
                                      Navigator.of(ctx).pop();
                                    },
                                  );
                                },
                              ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Create new channel',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () async {
                          Navigator.of(ctx).pop();
                          await _showCreateChannelDialog();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createStream() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _createError = 'Title is required.');
      return;
    }

    // Validate channel selected
    if (_effectiveChannelId.isEmpty) {
      setState(() => _createError = 'Please select a channel to stream to.');
      return;
    }

    DateTime? scheduledDateTime;
    if (_isScheduled) {
      scheduledDateTime = DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      );
      if (scheduledDateTime.isBefore(DateTime.now())) {
        setState(() => _createError = 'Scheduled time must be in the future.');
        return;
      }
    }

    setState(() {
      _isCreating = true;
      _createError = null;
    });

    try {
      final repo = ref.read(liveStreamingRepositoryProvider);
      final stream = await repo.createStream(
        _effectiveChannelId,
        CreateLiveStreamRequest(
          title: title,
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          scheduledAt: scheduledDateTime?.toIso8601String(),
          categories: _selectedCategory != null && _selectedCategory != 'All'
              ? [_selectedCategory!]
              : null,
          notifyAllUsers: _notifyAllUsers,
          isChatEnabled: _isChatEnabled,
          isRecordingEnabled: _isRecordingEnabled,
        ),
      );

      if (_isScheduled) {
        // Schedule multi-interval reminders on local device as well
        await ref
            .read(liveNotificationServiceProvider)
            .scheduleStreamReminders(stream);

        if (mounted) {
          setState(() {
            _isCreating = false;
          });
          _showScheduledSuccessDialog(stream);
        }
      } else {
        setState(() {
          _streamId = stream.id;
          _isCreating = false;
        });
      }
    } catch (e) {
      String msg;
      if (e is AppException) {
        msg = e.message.isNotEmpty ? e.message : 'Failed to create stream.';
      } else {
        msg = e.toString().replaceFirst('Exception: ', '');
      }
      setState(() {
        _createError = msg;
        _isCreating = false;
      });
    }
  }


  // ─── Studio page (after stream created) ───────────────────────────────────

  Widget _buildStudioPage(BuildContext context, String streamId) {
    final bState = ref.watch(
      broadcasterProvider((streamId, _effectiveChannelId)),
    );
    final theme = Theme.of(context);
    final stream = bState.stream;
    final tr = ref.read(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: stream?.status == LiveStreamStatus.live
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LiveBadgeWidget(small: true),
                  const SizedBox(width: 8),
                  Text(_formatElapsed(bState.elapsed)),
                ],
              )
            : Text(tr('live.studio_title')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmLeave(context, bState.stream),
        ),
        actions: [
          // Stream health
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: StreamHealthIndicator(health: bState.health, compact: true),
          ),
          // Viewer count
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: ViewerCountWidget(count: bState.viewerCount)),
          ),
        ],
      ),
      body: stream == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── YouTube Studio Live Monitor Banner / Camera Preview ──
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: MediaQuery.of(context).viewInsets.bottom > 0
                      ? 0
                      : 180,
                  child: MediaQuery.of(context).viewInsets.bottom > 0
                      ? const SizedBox.shrink()
                      : _buildLiveMonitor(theme, stream, bState),
                ),

                Expanded(
                  child:
                      stream.status == LiveStreamStatus.live &&
                          stream.isChatEnabled
                      ? Column(
                          children: [
                            // Collapsible stats summary when live
                            _buildLiveStatsRow(theme, stream, bState),
                            const Divider(height: 1),
                            // Live Chat takes full flexible space when live
                            Expanded(
                              child: LiveChatWidget(
                                streamId: streamId,
                                isModerator: true,
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status banner
                              _StatusBanner(status: stream.status),
                              const SizedBox(height: 16),

                              // RTMP key card
                              _StreamKeyCard(
                                streamKey: bState.streamKey,
                                isLoading: bState.isLoadingKey,
                                keyVisible: _keyVisible,
                                onToggleVisible: () =>
                                    setState(() => _keyVisible = !_keyVisible),
                                onRegenerate: () => ref
                                    .read(
                                      broadcasterProvider((
                                        streamId,
                                        _effectiveChannelId,
                                      )).notifier,
                                    )
                                    .regenerateStreamKey(),
                              ),
                              const SizedBox(height: 16),

                              // Recording & Live Settings Card
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Recording & Archive Settings',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(tr('live.record_stream')),
                                        subtitle: Text(
                                          tr('live.record_stream_desc'),
                                        ),
                                        value: stream.isRecordingEnabled,
                                        onChanged:
                                            stream.status ==
                                                LiveStreamStatus.live
                                            ? null
                                            : (v) {
                                                ref
                                                    .read(
                                                      liveStreamingRepositoryProvider,
                                                    )
                                                    .updateStream(stream.id, {
                                                      'isRecordingEnabled': v,
                                                    })
                                                    .then((updated) {
                                                      ref
                                                          .read(
                                                            broadcasterProvider((
                                                              streamId,
                                                              _effectiveChannelId,
                                                            )).notifier,
                                                          )
                                                          .updateStreamState(
                                                            updated,
                                                          );
                                                    })
                                                    .catchError((_) {});
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Health details (if available)
                              if (bState.health != null) ...[
                                StreamHealthIndicator(health: bState.health),
                                const SizedBox(height: 16),
                              ],

                              // Stream info
                              Text(
                                stream.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              if (stream.description != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  stream.description!,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),

                              // Error
                              if (bState.error != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    bState.error!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),

                // Action bar (hidden when keyboard is open to avoid taking vertical room)
                if (MediaQuery.of(context).viewInsets.bottom == 0)
                  _ActionBar(
                    status: stream.status,
                    isGoingLive: bState.isGoingLive,
                    isEndingStream: bState.isEndingStream,
                    onGoLive: () => _handleGoLive(streamId, bState),
                    onEndStream: () =>
                        _confirmEndStream(context, streamId, bState),
                    onPublishVod: () => ref
                        .read(
                          broadcasterProvider((
                            streamId,
                            _effectiveChannelId,
                          )).notifier,
                        )
                        .publishVod(),
                  ),
              ],
            ),
    );
  }

  Widget _buildLiveStatsRow(
    ThemeData theme,
    LiveStreamDto stream,
    BroadcasterState bState,
  ) {
    final tr = ref.read(trProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline, size: 16),
          const SizedBox(width: 6),
          const Flexible(
            child: Text(
              'Live Chat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          const Icon(Icons.people_outline, size: 16),
          const SizedBox(width: 4),
          Text(
            '${bState.viewerCount} watching',
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
          ),
          const SizedBox(width: 10),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.15),
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 32),
            ),
            icon: const Icon(Icons.stop_circle, size: 16),
            label: Text(
              tr('live.end_stream_btn'),
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () => _confirmEndStream(context, stream.id, bState),
          ),
        ],
      ),
    );
  }

  Future<void> _setupCamera({bool? front}) async {
    if (_isInitializingCamera) return;
    setState(() => _isInitializingCamera = true);

    try {
      final camStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (!camStatus.isGranted || !micStatus.isGranted) {
        if (mounted) {
          setState(() {
            _isCameraPermissionGranted = false;
            _isCameraInitialized = false;
            _isInitializingCamera = false;
          });
        }
        return;
      }

      final isFront = front ?? _isFrontCamera;

      final oldController = _liveStreamController;
      _liveStreamController = null;
      if (oldController != null) {
        try {
          await oldController.stop();
          await oldController.dispose();
        } catch (_) {}
      }

      final controller = ApiVideoLiveStreamController(
        initialAudioConfig: AudioConfig(),
        initialVideoConfig: VideoConfig.withDefaultBitrate(
          resolution: Resolution.RESOLUTION_720,
          fps: 30,
        ),
        initialCameraPosition: isFront
            ? CameraPosition.front
            : CameraPosition.back,
        onConnectionSuccess: _onConnectionSuccess,
        onConnectionFailed: _onConnectionFailed,
        onDisconnection: _onDisconnection,
        onError: _onError,
      );

      await controller.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception(
          'Camera initialization timed out. Please verify camera permissions and hardware availability.',
        ),
      );
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _liveStreamController = controller;
        _isCameraInitialized = true;
        _isCameraPermissionGranted = true;
        _isFrontCamera = isFront;
        _isInitializingCamera = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isInitializingCamera = false;
        });
      }
    }
  }

  Future<void> _flipCamera() async {
    HapticFeedback.lightImpact();
    if (_liveStreamController != null && _isCameraInitialized) {
      try {
        await _liveStreamController!.switchCamera();
        final pos = await _liveStreamController!.cameraPosition;
        if (mounted) {
          setState(() => _isFrontCamera = pos == CameraPosition.front);
        }
        return;
      } catch (_) {}
    }
    final nextIsFront = !_isFrontCamera;
    setState(() => _isFrontCamera = nextIsFront);
    await _setupCamera(front: nextIsFront);
  }

  Future<void> _toggleTorch() async {
    HapticFeedback.lightImpact();
    setState(() => _isTorchOn = !_isTorchOn);
  }

  Future<void> _toggleMic() async {
    HapticFeedback.lightImpact();
    final nextMute = !_isMicMuted;
    setState(() => _isMicMuted = nextMute);
    if (_liveStreamController != null && _isCameraInitialized) {
      try {
        await _liveStreamController!.setIsMuted(nextMute);
      } catch (_) {}
    }
  }

  static bool _isValidRtmpUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    if (uri.scheme != 'rtmp' && uri.scheme != 'rtmps') return false;

    final host = uri.host.toLowerCase();
    // Reject localhost / loopback
    if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
      return false;
    }

    // Reject URLs pointing to the Render web host on port 1935 (port 1935 does not exist on web servers)
    if (host == 'zikrekidusan.onrender.com' || host.endsWith('.onrender.com')) {
      return false;
    }

    final apiUri = Uri.tryParse(Env.apiBaseUrl);
    if (apiUri != null &&
        apiUri.host.isNotEmpty &&
        host == apiUri.host.toLowerCase()) {
      return false;
    }

    // Never accept port 1935 if host is an HTTP web service host
    if (uri.port == 1935 && host.contains('render')) {
      return false;
    }

    return true;
  }

  static String _resolveAuthoritativeRtmpUrl(String? backendUrl) {
    if (_isValidRtmpUrl(backendUrl)) {
      var url = backendUrl!.trim();
      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }
      return url;
    }
    return Env.rtmpServerUrl.trim();
  }

  Future<void> _startRtmpBroadcast(
    LiveStreamDto stream,
    String streamKey,
  ) async {
    if (_liveStreamController == null || !_isCameraInitialized) {
      await _setupCamera(front: _isFrontCamera);
    }
    if (_liveStreamController == null || !_isCameraInitialized) {
      throw Exception('Camera is not ready for live broadcasting.');
    }

    final targetUrl = _resolveAuthoritativeRtmpUrl(stream.rtmpIngestUrl);

    // Safely log RTMP host for debugging (never log stream keys or secrets)
    try {
      final uri = Uri.tryParse(targetUrl);
      debugPrint(
        '[LiveStudio] RTMP broadcasting to scheme=${uri?.scheme} host=${uri?.host} path=${uri?.path}',
      );
    } catch (_) {}

    final key = streamKey.trim();
    if (key.isEmpty) {
      throw Exception(
        'Stream key is missing. Please regenerate your stream key to broadcast.',
      );
    }

    _lastStreamKey = key;

    // Retry up to 3 times with increasing delays.
    // Cloudinary activation is async — even with backend polling the ingest
    // edge may not be fully ready on the very first publish attempt.
    const maxAttempts = 3;
    const retryDelays = [2000, 3000, 4000]; // ms between attempts
    Object? lastError;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        // On retry: wait before attempting again
        if (attempt > 0) {
          final waitMs = retryDelays[attempt - 1];
          debugPrint(
            '[LiveStudio] RTMP connectStream retry $attempt/$maxAttempts — waiting ${waitMs}ms',
          );
          if (mounted) {
            setState(() {
              _streamingError =
                  'Connecting to live server... (attempt ${attempt + 1}/$maxAttempts)';
            });
          }
          await Future<void>.delayed(Duration(milliseconds: waitMs));
        }

        await _liveStreamController!
            .startStreaming(streamKey: key, url: targetUrl)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw Exception(
                'Connection to RTMP broadcast server timed out. Please check your internet connection and try again.',
              ),
            );

        // Success
        if (mounted) {
          setState(() {
            _isStreamingRtmp = true;
            _streamingError = null;
          });
        }
        return;
      } catch (e) {
        lastError = e;
        final msg = e.toString();
        // Only retry on connectStream-type errors (Cloudinary not ready yet)
        final isConnectError =
            msg.contains('Failed to connectStream') ||
            msg.contains('connectStream') ||
            msg.contains('ConnectException') ||
            msg.contains('failed_to_start_stream');

        debugPrint(
          '[LiveStudio] RTMP attempt ${attempt + 1} failed: $msg '
          '(willRetry=${isConnectError && attempt < maxAttempts - 1})',
        );

        if (!isConnectError || attempt >= maxAttempts - 1) {
          // Not retryable or exhausted retries
          break;
        }
        // Otherwise loop and retry
      }
    }

    // All attempts failed
    if (mounted) {
      setState(() {
        _streamingError = 'RTMP broadcast failed: $lastError';
      });
    }
    throw Exception(lastError?.toString() ?? 'RTMP broadcast failed');
  }

  Future<void> _stopRtmpBroadcast() async {
    if (_isStreamingRtmp && _liveStreamController != null) {
      try {
        await _liveStreamController!.stopStreaming();
      } catch (_) {}
      if (mounted) {
        setState(() => _isStreamingRtmp = false);
      }
    }
  }

  Future<void> _handleGoLive(String streamId, BroadcasterState bState) async {
    try {
      final isOnline = ref.read(connectivityProvider).isOnline;
      if (!isOnline) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Live streaming requires an active internet connection.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final channelId = _effectiveChannelId;
      if (channelId.isEmpty) {
        throw Exception('Please select a streaming channel first.');
      }

      final notifier = ref.read(
        broadcasterProvider((streamId, channelId)).notifier,
      );

      // Step 1: Call go-live — backend provisions Cloudinary and embeds the key in response
      await notifier.goLive();

      final updatedState = ref.read(broadcasterProvider((streamId, channelId)));
      if (updatedState.error != null && updatedState.error!.isNotEmpty) {
        throw Exception(updatedState.error);
      }

      // Step 2: Prefer the key embedded by the go-live response (Cloudinary plain-text key)
      var key = updatedState.streamKey?.rawKey;
      if (key == null || key.isEmpty) {
        key = _lastStreamKey;
      }
      if (key == null || key.isEmpty) {
        key = bState.streamKey?.rawKey;
      }
      // If still missing, ask backend to regenerate
      if (key == null || key.isEmpty) {
        await notifier.regenerateStreamKey();
        key = ref
            .read(broadcasterProvider((streamId, channelId)))
            .streamKey
            ?.rawKey;
      }
      if (key == null || key.isEmpty) {
        throw Exception(
          'Could not obtain stream key. Please tap Regenerate Key and try again.',
        );
      }

      _lastStreamKey = key;

      final currentStream = updatedState.stream;
      if (currentStream != null) {
        await _startRtmpBroadcast(currentStream, key);
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) {
          msg = msg.substring('Exception: '.length);
        }
        if (msg.startsWith('AppException: ')) {
          msg = msg.substring('AppException: '.length);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start live broadcast: $msg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildLiveMonitor(
    ThemeData theme,
    LiveStreamDto stream,
    BroadcasterState bState,
  ) {
    final isLive = stream.status == LiveStreamStatus.live;

    return Container(
      width: double.infinity,
      height: 220,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Video Preview or Audio Waveform ──
          if (_isVideoStream)
            if (_isCameraInitialized &&
                _liveStreamController != null &&
                _liveStreamController!.isInitialized)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: 1280,
                    height: 720,
                    child: ApiVideoCameraPreview(
                      controller: _liveStreamController!,
                    ),
                  ),
                ),
              )
            else if (!_isCameraPermissionGranted)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.videocam_off,
                        size: 36,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Camera Permission Required',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FilledButton.tonal(
                        onPressed: () => _setupCamera(),
                        child: const Text(
                          'Grant Camera Access',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.redAccent,
                      strokeWidth: 2.5,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isInitializingCamera
                          ? 'Starting Camera...'
                          : 'Camera Standby',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
          else
            // Audio Stream Mode Visualizer
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isMicMuted ? Icons.mic_off : Icons.graphic_eq,
                      size: 48,
                      color: _isMicMuted ? Colors.redAccent : Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isMicMuted ? 'MICROPHONE MUTED' : 'LIVE AUDIO BROADCAST',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isMicMuted
                          ? 'Tap mic to unmute'
                          : 'High Quality Audio • 128kbps AAC',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Gradient overlay for contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Live duration badge (top-left)
          Positioned(
            top: 10,
            left: 10,
            child: isLive
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.fiber_manual_record,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isStreamingRtmp
                              ? 'LIVE (RTMP) ${_formatElapsed(bState.elapsed)}'
                              : 'LIVE ${_formatElapsed(bState.elapsed)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'STANDBY',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),

          // Top-right health & viewers badge
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (bState.health != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: bState.health!.health == StreamHealthLevel.good
                              ? Colors.greenAccent
                              : (bState.health!.health == StreamHealthLevel.fair
                                    ? Colors.amberAccent
                                    : Colors.redAccent),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          bState.health!.health.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${bState.viewerCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_streamingError != null)
            Positioned(
              bottom: 48,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _streamingError!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLive && !_isStreamingRtmp)
                      InkWell(
                        onTap: () {
                          final key =
                              _lastStreamKey ?? bState.streamKey?.rawKey ?? '';
                          if (key.isNotEmpty) {
                            _startRtmpBroadcast(stream, key);
                          } else {
                            _handleGoLive(stream.id, bState);
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            'Reconnect',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Controls Toolbar (bottom overlay)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                // REC / Mode indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isLive
                        ? Colors.red.withValues(alpha: 0.85)
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        color: isLive ? Colors.white : Colors.white70,
                        size: 9,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isVideoStream ? '720p HD' : 'AUDIO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Toggle Video/Audio Mode
                        IconButton.filledTonal(
                          icon: Icon(
                            _isVideoStream ? Icons.videocam : Icons.mic,
                            size: 17,
                            color: Colors.white,
                          ),
                          tooltip: _isVideoStream
                              ? 'Switch to Audio Mode'
                              : 'Switch to Camera Video',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 34,
                            minHeight: 34,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() => _isVideoStream = !_isVideoStream);
                            if (_isVideoStream && !_isCameraInitialized) {
                              _setupCamera();
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        // Flip Camera (only in video mode)
                        if (_isVideoStream) ...[
                          IconButton.filledTonal(
                            icon: const Icon(
                              Icons.cameraswitch,
                              size: 17,
                              color: Colors.white,
                            ),
                            tooltip: 'Flip Camera',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 34,
                              minHeight: 34,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                            onPressed: _flipCamera,
                          ),
                          const SizedBox(width: 6),
                          // Flash/Torch button
                          IconButton.filledTonal(
                            icon: Icon(
                              _isTorchOn ? Icons.flash_on : Icons.flash_off,
                              size: 17,
                              color: _isTorchOn
                                  ? Colors.amberAccent
                                  : Colors.white,
                            ),
                            tooltip: 'Toggle Flashlight',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 34,
                              minHeight: 34,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: _isTorchOn
                                  ? Colors.amber.withValues(alpha: 0.3)
                                  : Colors.black54,
                            ),
                            onPressed: _toggleTorch,
                          ),
                          const SizedBox(width: 6),
                        ],
                        // Mute/Unmute Mic Button
                        IconButton.filledTonal(
                          icon: Icon(
                            _isMicMuted ? Icons.mic_off : Icons.mic,
                            size: 17,
                            color: _isMicMuted
                                ? Colors.redAccent
                                : Colors.white,
                          ),
                          tooltip: _isMicMuted ? 'Unmute Mic' : 'Mute Mic',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 34,
                            minHeight: 34,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _isMicMuted
                                ? Colors.red.withValues(alpha: 0.35)
                                : Colors.black54,
                          ),
                          onPressed: _toggleMic,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmEndStream(
    BuildContext context,
    String streamId,
    BroadcasterState bState,
  ) async {
    final trFn = ref.read(trProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(trFn('live.end_broadcast_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trFn('live.preparing')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Duration: ${_formatElapsed(bState.elapsed)}'),
                  const Spacer(),
                  const Icon(Icons.people_outline, size: 18),
                  const SizedBox(width: 4),
                  Text('Peak: ${bState.viewerCount}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(trFn('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(trFn('profile.end_stream_btn')),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _stopRtmpBroadcast();
      await ref
          .read(broadcasterProvider((streamId, _effectiveChannelId)).notifier)
          .endStream();

      if (mounted) {
        _showPostStreamSummaryDialog(this.context, streamId, bState);
      }
    }
  }

  Future<void> _showPostStreamSummaryDialog(
    BuildContext context,
    String streamId,
    BroadcasterState bState,
  ) async {
    final trFn = ref.read(trProvider);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Broadcast Finished'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your stream recording is saved in group channel streams.',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 6),
                Text('Total Duration: ${_formatElapsed(bState.elapsed)}'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.visibility, size: 16),
                const SizedBox(width: 6),
                Text('Viewers: ${bState.viewerCount}'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: Text(trFn('common.close')),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(
                      broadcasterProvider((
                        streamId,
                        _effectiveChannelId,
                      )).notifier,
                    )
                    .publishVod();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(trFn('profile.publish_vod')),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${trFn('state.error')}: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.video_library),
            label: Text(trFn('profile.publish_vod')),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave(
    BuildContext context,
    LiveStreamDto? stream,
  ) async {
    final trFn = ref.read(trProvider);
    if (stream?.status == LiveStreamStatus.live) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(trFn('live.setup_title')),
          content: Text(trFn('live.preparing')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(trFn('common.dismiss')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(trFn('common.done')),
            ),
          ],
        ),
      );
      if (confirm == true && mounted) {
        await _stopRtmpBroadcast();
        // ignore: use_build_context_synchronously
        context.pop();
      }
    } else {
      await _stopRtmpBroadcast();
      if (context.mounted) {
        context.pop();
      }
    }
  }
}

// ─── Status banner ─────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final LiveStreamStatus status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (status) {
      LiveStreamStatus.draft => (
        Colors.grey,
        'Draft — Not live yet',
        Icons.edit_outlined,
      ),
      LiveStreamStatus.scheduled => (Colors.blue, 'Scheduled', Icons.schedule),
      LiveStreamStatus.live => (Colors.red, 'LIVE', Icons.live_tv),
      LiveStreamStatus.ended => (Colors.orange, 'Stream Ended', Icons.stop),
      LiveStreamStatus.processing => (
        Colors.purple,
        'Processing Recording...',
        Icons.autorenew,
      ),
      LiveStreamStatus.vodReady => (
        Colors.green,
        'VOD Ready',
        Icons.video_library,
      ),
      LiveStreamStatus.cancelled => (Colors.grey, 'Cancelled', Icons.cancel),
      LiveStreamStatus.failed => (Colors.red, 'Failed', Icons.error),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Stream key card ───────────────────────────────────────────────────────

class _StreamKeyCard extends StatelessWidget {
  final dynamic streamKey;
  final bool isLoading;
  final bool keyVisible;
  final VoidCallback onToggleVisible;
  final VoidCallback onRegenerate;

  const _StreamKeyCard({
    required this.streamKey,
    required this.isLoading,
    required this.keyVisible,
    required this.onToggleVisible,
    required this.onRegenerate,
  });

  String _resolveRtmpUrl(String? rawUrl) {
    return _LiveStudioScreenState._resolveAuthoritativeRtmpUrl(rawUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sk = streamKey;
    final rtmpDisplayUrl = _resolveRtmpUrl(sk?.rtmpUrl);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RTMP Stream Setup',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 12),

            const Text(
              'Server URL',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    rtmpDisplayUrl,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy server URL',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: rtmpDisplayUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Server URL copied')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            const Text(
              'Stream Key',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            isLoading
                ? const LinearProgressIndicator()
                : sk == null
                ? const Text(
                    'No key available',
                    style: TextStyle(color: Colors.grey),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          keyVisible
                              ? (sk.rawKey ?? sk.keyPrefix ?? '****')
                              : '••••••••••••••••',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          keyVisible ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: onToggleVisible,
                      ),
                      if (sk.rawKey != null)
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: sk.rawKey!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Stream key copied'),
                              ),
                            );
                          },
                        ),
                    ],
                  ),

            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: isLoading ? null : onRegenerate,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                'Regenerate Key',
                style: TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action bar ────────────────────────────────────────────────────────────

class _ActionBar extends ConsumerWidget {
  final LiveStreamStatus status;
  final bool isGoingLive;
  final bool isEndingStream;
  final VoidCallback onGoLive;
  final VoidCallback onEndStream;
  final VoidCallback onPublishVod;

  const _ActionBar({
    required this.status,
    required this.isGoingLive,
    required this.isEndingStream,
    required this.onGoLive,
    required this.onEndStream,
    required this.onPublishVod,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: switch (status) {
        LiveStreamStatus.draft || LiveStreamStatus.scheduled => SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isGoingLive ? null : onGoLive,
            icon: isGoingLive
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.live_tv),
            label: Text(tr('shell.go_live')),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        LiveStreamStatus.live => SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isEndingStream ? null : onEndStream,
            icon: isEndingStream
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.stop_circle_outlined),
            label: Text(tr('profile.end_stream_btn')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        LiveStreamStatus.ended || LiveStreamStatus.processing => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Column(
            children: [
              if (status == LiveStreamStatus.processing)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Processing recording…'),
                  ],
                )
              else
                FilledButton.icon(
                  onPressed: onPublishVod,
                  icon: const Icon(Icons.video_library),
                  label: Text(tr('profile.publish_vod')),
                ),
            ],
          ),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
