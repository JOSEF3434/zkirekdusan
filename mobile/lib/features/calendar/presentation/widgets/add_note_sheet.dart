// lib/features/calendar/presentation/widgets/add_note_sheet.dart
import 'package:abushakir/abushakir.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/presentation/widgets/app_network_image.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/data/calendar_offline_repository.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';
import 'package:mobile/features/calendar/data/calendar_media_upload_queue.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_download_settings_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/media_picker_sheet.dart';
import 'package:mobile/features/calendar/presentation/widgets/recurring_reminder_picker.dart';
import 'package:mobile/features/calendar/domain/calendar_reminder_schedule.dart';
import 'package:path/path.dart' as p;

import 'dart:developer' as developer;
import 'dart:io' as io;

class AddNoteSheet extends ConsumerStatefulWidget {
  final EtDatetime selectedDate;
  final CalendarNoteModel? existingNote;

  const AddNoteSheet({
    super.key,
    required this.selectedDate,
    this.existingNote,
  });

  @override
  ConsumerState<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<AddNoteSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isSaving = false;
  final List<String> _selectedMediaPaths = [];
  bool _allowDownload = false; // per-post download flag (default OFF)

  // Existing server-side media (when editing a note)
  late List<CalendarNoteMedia> _existingMedia;

  // Reminder state - default to Monthly repeat at 12:00 PM
  DateTime? _reminderDateTime;
  ReminderRepeat _reminderRepeat = ReminderRepeat.monthly;
  int _reminderHour = 12;
  int _reminderMinute = 0;

  // Recurrence & Publication state (Admin management)
  ReminderRepeat _recurrenceType = ReminderRepeat.monthly;
  bool _isAutoPublishEnabled = false;
  String _autoPublishTime = '12:00';
  String? _category;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingNote?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.existingNote?.content ?? '',
    );

    // Initialize reminder state (defaulting to monthly and 12:00 for new notes)
    _reminderDateTime = widget.existingNote?.reminderDateTime;
    _reminderRepeat =
        widget.existingNote?.reminderRepeat ?? ReminderRepeat.monthly;
    _reminderHour = widget.existingNote?.reminderHour ?? 12;
    _reminderMinute = widget.existingNote?.reminderMinute ?? 0;

    // Initialize recurrence & publication state
    _recurrenceType = widget.existingNote?.recurrenceType ??
        widget.existingNote?.reminderRepeat ??
        ReminderRepeat.monthly;
    _isAutoPublishEnabled =
        widget.existingNote?.isAutoPublishEnabled ?? false;
    _autoPublishTime = widget.existingNote?.autoPublishTime ??
        (_recurrenceType == ReminderRepeat.yearly ? '12:10' : '12:00');
    _category = widget.existingNote?.category;

    // Initialize allowDownload from existing note if editing
    _allowDownload = widget.existingNote?.allowDownload ?? false;

    // Load existing media from the note (editable by SUPER_ADMIN)
    _existingMedia = List<CalendarNoteMedia>.from(
      widget.existingNote?.media ?? [],
    );
  }

  String _calculateNextPublicationPreview() {
    final y = widget.selectedDate.year;
    final m = widget.selectedDate.month;
    final d = widget.selectedDate.day;
    if (_recurrenceType == ReminderRepeat.none) {
      return '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')} at $_autoPublishTime';
    } else if (_recurrenceType == ReminderRepeat.monthly) {
      var nextM = m + 1;
      var nextY = y;
      if (nextM > 13) {
        nextM = 1;
        nextY++;
      }
      return '$nextY-${nextM.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')} at $_autoPublishTime';
    } else {
      // Annual
      final nextY = y + 1;
      return '$nextY-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')} at $_autoPublishTime';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MediaPickerSheet(),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _selectedMediaPaths.addAll(result);
      });
      // If note already exists (editing), start upload immediately
      final noteId = widget.existingNote?.id;
      if (noteId != null) {
        await ref
            .read(mediaUploadQueueProvider.notifier)
            .enqueueAll(
              localPaths: result,
              noteId: noteId,
              startOrder: _selectedMediaPaths.length - result.length,
            );
      }
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMediaPaths.removeAt(index);
    });
  }

  /// Delete an already-uploaded media item from the note (SUPER_ADMIN).
  Future<void> _deleteExistingMedia(CalendarNoteMedia media, int index) async {
    final noteId = widget.existingNote?.id;
    if (noteId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.read(trProvider)('calendar.delete_media')),
        content: Text(ref.read(trProvider)('calendar.delete_media_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ref.read(trProvider)('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ref.read(trProvider)('common.delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final deleteMedia = ref.read(deleteCalendarNoteMediaProvider);
      await deleteMedia(noteId, media.id);
      setState(() => _existingMedia.removeAt(index));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(trProvider)('calendar.failed_delete_media', {
                'error': e.toString(),
              }),
            ),
          ),
        );
      }
    }
  }

  /// Edit the caption of an already-uploaded media item (SUPER_ADMIN).
  Future<void> _editMediaCaption(CalendarNoteMedia media, int index) async {
    final noteId = widget.existingNote?.id;
    if (noteId == null) return;

    final captionController = TextEditingController(text: media.caption ?? '');
    final newCaption = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.read(trProvider)('calendar.edit_caption')),
        content: TextField(
          controller: captionController,
          decoration: InputDecoration(
            labelText: ref.read(trProvider)('calendar.caption'),
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.of(ctx).pop(captionController.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(ref.read(trProvider)('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(captionController.text),
            child: Text(ref.read(trProvider)('common.save')),
          ),
        ],
      ),
    );
    captionController.dispose();
    if (newCaption == null || !mounted) return;

    try {
      final updateMedia = ref.read(updateCalendarNoteMediaProvider);
      await updateMedia(noteId, media.id, caption: newCaption);
      setState(() {
        _existingMedia[index] = media.copyWith(caption: newCaption);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(trProvider)('calendar.failed_update_caption', {
                'error': e.toString(),
              }),
            ),
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    final titleText = _titleController.text.trim();
    final contentText = _contentController.text.trim();

    if (titleText.isEmpty &&
        contentText.isEmpty &&
        _selectedMediaPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(trProvider)('calendar.enter_title_content_media'),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final gregorian = EthiopianCalendarUtil.toGregorian(widget.selectedDate);

      CalendarNoteModel note;

      if (widget.existingNote != null) {
        // Update existing note
        final updateNote = ref.read(updateCalendarNoteProvider);
        note = await updateNote(
          widget.existingNote!.id,
          title: _titleController.text.isEmpty ? null : _titleController.text,
          content: _contentController.text.isEmpty
              ? null
              : _contentController.text,
          hasReminder: _reminderRepeat != ReminderRepeat.none,
          reminderDateTime: _reminderDateTime,
          reminderRepeat: _reminderRepeat,
          reminderEthiopianMonth: widget.selectedDate.month,
          reminderEthiopianDay: widget.selectedDate.day,
          reminderHour: _reminderHour,
          reminderMinute: _reminderMinute,
          reminderTimezone: 'Africa/Addis_Ababa',
          reminderNextOccurrence: _reminderDateTime,
          allowDownload: _allowDownload,
          category: _category,
          recurrenceType: _recurrenceType,
          isAutoPublishEnabled: _isAutoPublishEnabled,
          autoPublishTime: _autoPublishTime,
        );
      } else {
        // Create new note
        final createNote = ref.read(createCalendarNoteProvider);
        final userId = ref.read(authProvider).user?.id;
        if (userId == null) {
          throw StateError('A signed-in user is required to create a note');
        }
        note = await createNote(
          userId: userId,
          ethiopianYear: widget.selectedDate.year,
          ethiopianMonth: widget.selectedDate.month,
          ethiopianDay: widget.selectedDate.day,
          gregorianDate: gregorian,
          title: _titleController.text.isEmpty ? null : _titleController.text,
          content: _contentController.text.isEmpty
              ? null
              : _contentController.text,
          hasReminder: _reminderRepeat != ReminderRepeat.none,
          reminderDateTime: _reminderDateTime,
          reminderRepeat: _reminderRepeat,
          reminderEthiopianMonth: widget.selectedDate.month,
          reminderEthiopianDay: widget.selectedDate.day,
          reminderHour: _reminderHour,
          reminderMinute: _reminderMinute,
          reminderTimezone: 'Africa/Addis_Ababa',
          reminderNextOccurrence: _reminderDateTime,
          allowDownload: _allowDownload,
          category: _category,
          recurrenceType: _recurrenceType,
          isAutoPublishEnabled: _isAutoPublishEnabled,
          autoPublishTime: _autoPublishTime,
        );
      }

      // Upload media if any and note is newly created (editing uploads immediately)
      if (_selectedMediaPaths.isNotEmpty && widget.existingNote == null) {
        if (!kIsWeb) {
          try {
            await ref
                .read(calendarOfflineRepositoryProvider)
                .pushUnsyncedNotes();
          } catch (pushErr) {
            developer.log(
              '⚠️ pushUnsyncedNotes non-blocking warning: $pushErr',
              name: 'AddNoteSheet',
            );
          }
        }
        await ref
            .read(mediaUploadQueueProvider.notifier)
            .enqueueAll(localPaths: _selectedMediaPaths, noteId: note.id);
      }

      if (mounted) {
        // Invalidate cache to refresh
        ref.invalidate(
          calendarNotesForDateProvider((
            year: widget.selectedDate.year,
            month: widget.selectedDate.month,
            day: widget.selectedDate.day,
          )),
        );
        ref.invalidate(
          calendarNotesForMonthProvider((
            year: widget.selectedDate.year,
            month: widget.selectedDate.month,
          )),
        );

        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingNote != null
                  ? ref.read(trProvider)('calendar.note_updated')
                  : ref.read(trProvider)('calendar.note_created'),
            ),
          ),
        );
      }
    } catch (e, st) {
      developer.log(
        'Failed to save calendar note: $e',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  bool _isImageFile(String path) {
    if (path.startsWith('blob:') || path.startsWith('data:image/')) return true;
    final extension = path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  bool _isVideoFile(String path) {
    if (path.startsWith('data:video/')) return true;
    final extension = path.toLowerCase().split('.').last;
    return [
      'mp4',
      'mov',
      'avi',
      'mkv',
      'wmv',
      'flv',
      'webm',
    ].contains(extension);
  }

  bool _isAudioFile(String path) {
    if (path.startsWith('data:audio/')) return true;
    final extension = path.toLowerCase().split('.').last;
    return [
      'mp3',
      'wav',
      'aac',
      'flac',
      'm4a',
      'ogg',
      'wma',
    ].contains(extension);
  }

  Widget _buildFileIcon(IconData icon, String fileName, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            fileName.length > 15 ? '${fileName.substring(0, 12)}...' : fileName,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String path, ThemeData theme, String fileName) {
    if (kIsWeb) {
      return Image.network(
        path,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildFileIcon(Icons.broken_image, fileName, theme),
      );
    } else {
      try {
        return Image.file(
          io.File(path),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFileIcon(Icons.broken_image, fileName, theme),
        );
      } catch (e) {
        return _buildFileIcon(Icons.broken_image, fileName, theme);
      }
    }
  }

  Widget _buildVideoPreview(String path, ThemeData theme, String fileName) {
    Widget thumbnail;

    if (kIsWeb) {
      thumbnail = Container(
        width: 120,
        height: 120,
        color: theme.colorScheme.surfaceContainerHighest,
        child: _buildFileIcon(Icons.videocam, fileName, theme),
      );
    } else {
      try {
        thumbnail = Image.file(
          io.File(path),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFileIcon(Icons.videocam, fileName, theme),
        );
      } catch (e) {
        thumbnail = _buildFileIcon(Icons.videocam, fileName, theme);
      }
    }

    return Stack(
      children: [
        thumbnail,
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.play_circle_outline,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer(
                        builder: (_, ref, _) => Text(
                          widget.existingNote != null
                              ? ref.watch(trProvider)('calendar.edit_note')
                              : ref.watch(trProvider)('calendar.add_note'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        EthiopianCalendarUtil.formatEthiopianDate(
                          widget.selectedDate,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.7,
                          ),
                          fontFamilyFallback: const [
                            'Noto Serif Ethiopic',
                            'Noto Sans Ethiopic',
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Title field
            Consumer(
              builder: (context, ref, _) => TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: ref.watch(trProvider)('calendar.title_optional'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                textInputAction: TextInputAction.next,
                enabled: !_isSaving,
              ),
            ),

            const SizedBox(height: 16),

            // Content field
            Consumer(
              builder: (context, ref, _) => TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: ref.watch(trProvider)('calendar.content'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 5,
                textInputAction: TextInputAction.done,
                enabled: !_isSaving,
              ),
            ),

            const SizedBox(height: 16),

            // ── Existing server media (edit mode only) ────────────────────
            if (widget.existingNote != null && _existingMedia.isNotEmpty) ...[
              Consumer(
                builder: (context, ref, _) => Text(
                  ref.watch(trProvider)('calendar.current_media', {
                    'count': _existingMedia.length.toString(),
                  }),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _existingMedia.length,
                  itemBuilder: (context, index) {
                    final media = _existingMedia[index];
                    final rawUrl = media.file?['url'] as String?;
                    final resolved = MediaUrlResolver.resolve(rawUrl);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: resolved != null
                                ? AppNetworkImage(
                                    imageUrl: resolved,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorWidget: (ctx, url, err) => Container(
                                      width: 120,
                                      height: 120,
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: const Icon(
                                        Icons.attach_file,
                                        size: 36,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.attach_file,
                                      size: 36,
                                    ),
                                  ),
                          ),
                          // Caption badge (bottom-left)
                          if (media.caption != null &&
                              media.caption!.isNotEmpty)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              right: 28,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  media.caption!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          // Edit caption button (top-left)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Material(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => _editMediaCaption(media, index),
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Delete button (top-right)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Material(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => _deleteExistingMedia(media, index),
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── New media queue ────────────────────────────────────────────
            Builder(
              builder: (context) {
                final noteId = widget.existingNote?.id;
                final queueItems = noteId != null
                    ? ref.watch(noteUploadQueueProvider(noteId))
                    : <UploadQueueItem>[];
                final allPaths = _selectedMediaPaths;

                if (allPaths.isEmpty && queueItems.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer(
                      builder: (context, ref, _) => Text(
                        ref.watch(trProvider)('calendar.attachments', {
                          'count':
                              (allPaths.length +
                                      queueItems
                                          .where(
                                            (q) =>
                                                !allPaths.contains(q.localPath),
                                          )
                                          .length)
                                  .toString(),
                        }),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: allPaths.length,
                        itemBuilder: (context, index) {
                          final path = allPaths[index];
                          // Find queue item for real-time progress
                          final queueItem = queueItems
                              .where((q) => q.localPath == path)
                              .firstOrNull;
                          final progress =
                              queueItem?.status == UploadStatus.uploading
                              ? queueItem!.progress
                              : null;
                          final isDone = queueItem?.status == UploadStatus.done;
                          final isFailed =
                              queueItem?.status == UploadStatus.failed;
                          final isImage = _isImageFile(path);
                          final isVideo = _isVideoFile(path);
                          final isAudio = _isAudioFile(path);
                          final fileName = p.basename(path);

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDone
                                          ? theme.colorScheme.primary
                                          : isFailed
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.outline
                                                .withValues(alpha: 0.2),
                                      width: isDone || isFailed ? 2 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: isImage
                                        ? _buildImagePreview(
                                            path,
                                            theme,
                                            fileName,
                                          )
                                        : isVideo
                                        ? _buildVideoPreview(
                                            path,
                                            theme,
                                            fileName,
                                          )
                                        : isAudio
                                        ? _buildFileIcon(
                                            Icons.audiotrack,
                                            fileName,
                                            theme,
                                          )
                                        : _buildFileIcon(
                                            Icons.insert_drive_file,
                                            fileName,
                                            theme,
                                          ),
                                  ),
                                ),
                                // Upload progress overlay
                                if (progress != null)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(
                                              value: progress,
                                              backgroundColor: Colors.white24,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(Colors.white),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${(progress * 100).toInt()}%',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                // Done badge
                                if (isDone)
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                // Failed badge with retry
                                if (isFailed)
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: GestureDetector(
                                      onTap: () => ref
                                          .read(
                                            mediaUploadQueueProvider.notifier,
                                          )
                                          .retryFailed(),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Remove button
                                if (!_isSaving)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Material(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        onTap: () => _removeMedia(index),
                                        borderRadius: BorderRadius.circular(12),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // Add media button
            const SizedBox(height: 16),

            // ── Per-post download toggle (only shown if global download is enabled) ──
            Consumer(
              builder: (context, ref, _) {
                final globalDownloadEnabled = ref.watch(
                  calendarDownloadEnabledProvider,
                );
                if (!globalDownloadEnabled) return const SizedBox.shrink();
                return Column(
                  children: [
                    Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _allowDownload
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: CheckboxListTile(
                        value: _allowDownload,
                        onChanged: _isSaving
                            ? null
                            : (val) =>
                                  setState(() => _allowDownload = val ?? false),
                        title: Text(
                          ref.watch(trProvider)(
                            'calendar.allow_download_title',
                          ),
                        ),
                        subtitle: Text(
                          ref.watch(trProvider)(
                            'calendar.allow_download_subtitle',
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                        secondary: Icon(
                          _allowDownload
                              ? Icons.download_done_rounded
                              : Icons.download_outlined,
                          color: _allowDownload
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        controlAffinity: ListTileControlAffinity.trailing,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // ── Recurrence & Automated Publication (Feast System) ──
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'የበዓላት ድግግሞሽ (Feast Recurrence)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ReminderRepeat>(
                      segments: const [
                        ButtonSegment(
                          value: ReminderRepeat.none,
                          label: Text('አንድ ጊዜ'),
                        ),
                        ButtonSegment(
                          value: ReminderRepeat.monthly,
                          label: Text('ወርሃዊ'),
                        ),
                        ButtonSegment(
                          value: ReminderRepeat.yearly,
                          label: Text('ዓመታዊ'),
                        ),
                      ],
                      selected: {_recurrenceType},
                      onSelectionChanged: _isSaving
                          ? null
                          : (newSet) {
                              final selected = newSet.first;
                              setState(() {
                                _recurrenceType = selected;
                                if (selected == ReminderRepeat.yearly &&
                                    _autoPublishTime == '12:00') {
                                  _autoPublishTime = '12:10';
                                } else if (selected == ReminderRepeat.monthly &&
                                    _autoPublishTime == '12:10') {
                                  _autoPublishTime = '12:00';
                                }
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isAutoPublishEnabled,
                      onChanged: _isSaving
                          ? null
                          : (val) {
                              setState(() {
                                _isAutoPublishEnabled = val;
                              });
                            },
                      title: const Text('በራስ-ሰር የሚታተም (Automated Publication)'),
                      subtitle: Text(
                        _recurrenceType == ReminderRepeat.monthly
                            ? 'በየወሩ 12:00 PM ላይ በራስ-ሰር ልጥፍ ይፈጥራል'
                            : _recurrenceType == ReminderRepeat.yearly
                                ? 'በየዓመቱ 12:10 PM ላይ በራስ-ሰር ልጥፍ ይፈጥራል'
                                : 'በተመረጠው ቀን ላይ በራስ-ሰር ልጥፍ ይፈጥራል',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    if (_isAutoPublishEnabled) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('የህትመት ሰዓት (Publication Time):'),
                          Text(
                            _autoPublishTime,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ቀጣይ ህትመት ቅድመ-ዕይታ: ${_calculateNextPublicationPreview()}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reminder picker
            RecurringReminderPicker(
              selectedDate: widget.selectedDate,
              settings: ReminderSettings(
                enabled: _reminderRepeat != ReminderRepeat.none,
                repeat: _reminderRepeat,
                hour: _reminderHour,
                minute: _reminderMinute,
              ),
              onChanged: (settings) {
                final schedule = CalendarReminderSchedule.forEvent(
                  year: widget.selectedDate.year,
                  month: widget.selectedDate.month,
                  day: widget.selectedDate.day,
                  hour: settings.hour,
                  minute: settings.minute,
                );
                setState(() {
                  _reminderRepeat = settings.repeat;
                  _reminderHour = settings.hour;
                  _reminderMinute = settings.minute;
                  _reminderDateTime = settings.enabled
                      ? schedule.notificationGregorian
                      : null;
                });
              },
            ),

            const SizedBox(height: 16),

            // Add media button
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _pickMedia,
              icon: const Icon(Icons.add_photo_alternate),
              label: Consumer(
                builder: (_, ref, _) =>
                    Text(ref.watch(trProvider)('common.add')),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Consumer(
                      builder: (_, ref, _) =>
                          Text(ref.watch(trProvider)('common.cancel')),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Consumer(
                            builder: (_, ref, _) =>
                                Text(ref.watch(trProvider)('common.save')),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
