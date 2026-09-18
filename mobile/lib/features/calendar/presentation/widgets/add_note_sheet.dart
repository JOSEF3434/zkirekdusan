// lib/features/calendar/presentation/widgets/add_note_sheet.dart
import 'package:abushakir/abushakir.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';
import 'package:mobile/features/calendar/data/calendar_media_service.dart';
import 'package:mobile/features/calendar/presentation/widgets/media_picker_sheet.dart';
import 'package:mobile/features/calendar/presentation/widgets/recurring_reminder_picker.dart';
import 'package:mobile/features/calendar/domain/calendar_reminder_schedule.dart';
import 'package:path/path.dart' as p;

// Conditional imports for platform-specific code
import 'dart:io' if (dart.library.html) 'dart:html' as io;

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
  final Map<String, double> _uploadProgress = {};

  // Reminder state
  DateTime? _reminderDateTime;
  ReminderRepeat _reminderRepeat = ReminderRepeat.none;
  int _reminderHour = 8;
  int _reminderMinute = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingNote?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.existingNote?.content ?? '',
    );

    // Initialize reminder state
    _reminderDateTime = widget.existingNote?.reminderDateTime;
    _reminderRepeat =
        widget.existingNote?.reminderRepeat ?? ReminderRepeat.none;
    _reminderHour = widget.existingNote?.reminderHour ?? 8;
    _reminderMinute = widget.existingNote?.reminderMinute ?? 0;

    // Load existing media if editing
    if (widget.existingNote != null && widget.existingNote!.media.isNotEmpty) {
      // Note: For editing, we should show existing media URLs, not paths
      // For now, we'll just track new media additions
      // You may want to enhance this to show existing media from server
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
      builder: (context) => const MediaPickerSheet(),
    );

    if (result != null) {
      final paths = result;
      if (paths.isNotEmpty && mounted) {
        setState(() {
          _selectedMediaPaths.addAll(paths);
        });
      }
    }
  }

  void _removeMedia(int index) {
    setState(() {
      final path = _selectedMediaPaths[index];
      _selectedMediaPaths.removeAt(index);
      _uploadProgress.remove(path);
    });
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title or content')),
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
        );
      }

      // Upload media if any
      if (_selectedMediaPaths.isNotEmpty) {
        await _uploadMedia(note.id);
      }

      if (mounted) {
        // Invalidate cache to refresh
        ref.invalidate(calendarNotesForDateProvider);
        ref.invalidate(calendarNotesForMonthProvider);

        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingNote != null
                  ? 'Note updated successfully'
                  : 'Note created successfully',
            ),
          ),
        );
      }
    } catch (e) {
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

  Future<void> _uploadMedia(String noteId) async {
    final mediaService = ref.read(calendarMediaServiceProvider);

    for (var i = 0; i < _selectedMediaPaths.length; i++) {
      final path = _selectedMediaPaths[i];
      try {
        // Upload file
        final fileData = await mediaService.uploadFile(
          filePath: path,
          onProgress: (sent, total) {
            if (mounted) {
              setState(() {
                _uploadProgress[path] = sent / total;
              });
            }
          },
        );

        // Attach to note
        await mediaService.addMediaToNote(
          noteId: noteId,
          fileId: fileData['id'] as String,
          order: i,
        );
      } catch (e) {
        debugPrint('Error uploading media: $e');
      }
    }
  }

  bool _isImageFile(String path) {
    final extension = path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  bool _isVideoFile(String path) {
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
                      Text(
                        widget.existingNote != null ? 'Edit Note' : 'Add Note',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
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
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textInputAction: TextInputAction.next,
              enabled: !_isSaving,
            ),

            const SizedBox(height: 16),

            // Content field
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 5,
              textInputAction: TextInputAction.done,
              enabled: !_isSaving,
            ),

            const SizedBox(height: 16),

            // Media section
            if (_selectedMediaPaths.isNotEmpty) ...[
              Text(
                'Attachments (${_selectedMediaPaths.length})',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMediaPaths.length,
                  itemBuilder: (context, index) {
                    final path = _selectedMediaPaths[index];
                    final progress = _uploadProgress[path];
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
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isImage
                                  ? _buildImagePreview(path, theme, fileName)
                                  : isVideo
                                  ? _buildVideoPreview(path, theme, fileName)
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
                          if (progress != null && progress < 1.0)
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
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
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

            // Add media button
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
