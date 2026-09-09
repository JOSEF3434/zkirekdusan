// lib/features/calendar/presentation/widgets/add_note_sheet.dart
import 'dart:io';
import 'package:abushakir/abushakir.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';
import 'package:mobile/features/calendar/data/calendar_media_service.dart';
import 'package:mobile/features/calendar/presentation/widgets/media_picker_sheet.dart';
import 'package:mobile/features/calendar/presentation/widgets/reminder_picker_widget.dart';

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
  late bool _hasReminder;
  late DateTime? _reminderDateTime;

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
    _hasReminder = widget.existingNote?.hasReminder ?? false;
    _reminderDateTime = widget.existingNote?.reminderDateTime;
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
                'Attachments',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMediaPaths.length,
                  itemBuilder: (context, index) {
                    final path = _selectedMediaPaths[index];
                    final progress = _uploadProgress[path];

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 100,
                                    height: 100,
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: const Icon(Icons.attach_file),
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
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                              ),
                            ),
                          if (!_isSaving)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  padding: const EdgeInsets.all(4),
                                  minimumSize: const Size(24, 24),
                                ),
                                onPressed: () => _removeMedia(index),
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
            ReminderPickerWidget(
              hasReminder: _hasReminder,
              reminderDateTime: _reminderDateTime,
              minDate: EthiopianCalendarUtil.toGregorian(widget.selectedDate),
              onChanged: (hasReminder, dateTime) {
                setState(() {
                  _hasReminder = hasReminder;
                  _reminderDateTime = dateTime;
                });
              },
            ),

            const SizedBox(height: 16),

            // Add media button
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _pickMedia,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Media'),
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
                    child: const Text('Cancel'),
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
                        : const Text('Save'),
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
