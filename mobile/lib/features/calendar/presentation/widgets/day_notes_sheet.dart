// lib/features/calendar/presentation/widgets/day_notes_sheet.dart
import 'package:abushakir/abushakir.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/add_note_sheet.dart';

class DayNotesSheet extends ConsumerWidget {
  final EtDatetime selectedDate;

  const DayNotesSheet({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notesAsync = ref.watch(
      calendarNotesForDateProvider((
        year: selectedDate.year,
        month: selectedDate.month,
        day: selectedDate.day,
      )),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        EthiopianCalendarUtil.formatEthiopianDate(selectedDate),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamilyFallback: const [
                            'Noto Serif Ethiopic',
                            'Noto Sans Ethiopic',
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        EthiopianCalendarUtil.formatGregorianDate(
                          EthiopianCalendarUtil.toGregorian(selectedDate),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Notes list
          Flexible(
            child: notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notes.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _buildNoteItem(context, ref, note);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error loading notes: $error',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // Add note button
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => _showAddNoteSheet(context, ref, selectedDate),
              icon: const Icon(Icons.add),
              label: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('calendar.add_note'))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No notes for this day',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Note" to create one',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem(
    BuildContext context,
    WidgetRef ref,
    CalendarNoteModel note,
  ) {
    final theme = Theme.of(context);
    final hasMedia = note.media.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: note.title != null && note.title!.isNotEmpty
              ? Text(
                  note.title!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          subtitle: note.content != null && note.content!.isNotEmpty
              ? Text(
                  note.content!,
                  maxLines: note.title != null ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: PopupMenuButton<String>(
            onSelected: (action) =>
                _handleNoteAction(context, ref, note, action),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 12),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          onTap: () =>
              _showAddNoteSheet(context, selectedDate, existingNote: note),
        ),
        // Media gallery
        if (hasMedia)
          Container(
            height: 80,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: note.media.length,
              itemBuilder: (context, index) {
                final media = note.media[index];
                final file = media.file;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: file != null && file['url'] != null
                        ? Image.network(
                            file['url'] as String,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 80,
                                  height: 80,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.broken_image),
                                ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.attach_file),
                          ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _handleNoteAction(
    BuildContext context,
    WidgetRef ref,
    CalendarNoteModel note,
    String action,
  ) async {
    if (action == 'edit') {
      await _showAddNoteSheet(context, ref, selectedDate, existingNote: note);
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('common.delete'))),
          content: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('admin.confirm.delete_msg'))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('common.cancel'))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('common.delete'))),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          final deleteNote = ref.read(deleteCalendarNoteProvider);
          await deleteNote(note.id);

          // Invalidate cache
          ref.invalidate(
            calendarNotesForDateProvider((
              year: selectedDate.year,
              month: selectedDate.month,
              day: selectedDate.day,
            )),
          );
          ref.invalidate(
            calendarNotesForMonthProvider((
              year: selectedDate.year,
              month: selectedDate.month,
            )),
          );

          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Note deleted')));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error deleting note: $e')));
          }
        }
      }
    }
  }

  Future<void> _showAddNoteSheet(
    BuildContext context,
    WidgetRef ref,
    EtDatetime date, {
    CalendarNoteModel? existingNote,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          AddNoteSheet(selectedDate: date, existingNote: existingNote),
    );

    if (result == true) {
      ref.invalidate(
        calendarNotesForDateProvider((
          year: date.year,
          month: date.month,
          day: date.day,
        )),
      );
      ref.invalidate(
        calendarNotesForMonthProvider((
          year: date.year,
          month: date.month,
        )),
      );
    }
  }
}



