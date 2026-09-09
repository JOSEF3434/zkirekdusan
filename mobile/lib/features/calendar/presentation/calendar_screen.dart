// lib/features/calendar/presentation/calendar_screen.dart
// Ethiopian Calendar with modern UI, month navigation, date selection, and notes

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abushakir/abushakir.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_state_provider.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/day_notes_sheet.dart';
import 'package:mobile/features/calendar/presentation/widgets/add_note_sheet.dart';
import 'package:mobile/features/calendar/presentation/widgets/sync_status_indicator.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_sync_provider.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final calendarState = ref.watch(calendarProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger manual sync
          final quickSync = ref.read(quickSyncProvider);
          await quickSync();

          // Refresh current month notes
          ref.invalidate(calendarNotesForMonthProvider);
        },
        child: CustomScrollView(
          slivers: [
            // App bar with month/year
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      EthiopianCalendarUtil.getMonthName(calendarState.month),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamilyFallback: const [
                          'Noto Serif Ethiopic',
                          'Noto Sans Ethiopic',
                        ],
                      ),
                    ),
                    Text(
                      '${calendarState.year}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // Sync status indicator
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: SyncStatusIndicator(),
                ),
                // Today button
                IconButton(
                  icon: const Icon(Icons.today),
                  tooltip: 'Today',
                  onPressed: () =>
                      ref.read(calendarProvider.notifier).goToToday(),
                ),
                // Previous month
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous Month',
                  onPressed: () =>
                      ref.read(calendarProvider.notifier).previousMonth(),
                ),
                // Next month
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next Month',
                  onPressed: () =>
                      ref.read(calendarProvider.notifier).nextMonth(),
                ),
              ],
            ),

            // Gregorian equivalent
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  _getGregorianMonthRange(
                    calendarState.year,
                    calendarState.month,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Weekday header
            SliverToBoxAdapter(child: _buildWeekdayHeader(theme)),

            // Calendar grid
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: _buildCalendarGrid(theme, calendarState, ref),
            ),

            // Selected date info
            if (calendarState.selectedDate != null)
              SliverToBoxAdapter(
                child: _buildSelectedDateInfo(theme, calendarState),
              ),
          ],
        ),
      ),
      floatingActionButton: calendarState.selectedDate != null
          ? FloatingActionButton.extended(
              onPressed: () {
                _showAddNoteSheet(context, calendarState.selectedDate!);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Note'),
            )
          : null,
    );
  }

  Widget _buildWeekdayHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: EthiopianCalendarUtil.ethiopianWeekdayNames.map((weekday) {
          return Expanded(
            child: Center(
              child: Text(
                weekday,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.6,
                  ),
                  fontFamilyFallback: const [
                    'Noto Serif Ethiopic',
                    'Noto Sans Ethiopic',
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(
    ThemeData theme,
    CalendarState state,
    WidgetRef ref,
  ) {
    final year = state.year;
    final month = state.month;
    final daysInMonth = EthiopianCalendarUtil.getDaysInMonth(year, month);
    final firstWeekday = EthiopianCalendarUtil.getFirstWeekdayOfMonth(
      year,
      month,
    );

    // Calculate leading empty cells (Monday = 1, so firstWeekday-1 empty cells)
    final leadingEmpty = firstWeekday - 1;
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index < leadingEmpty) {
          // Empty cell before first day
          return const SizedBox.shrink();
        }

        final day = index - leadingEmpty + 1;
        if (day > daysInMonth) {
          // Empty cell after last day
          return const SizedBox.shrink();
        }

        final cellDate = EthiopianCalendarUtil.create(year, month, day);
        final isToday = EthiopianCalendarUtil.isSameDay(cellDate, state.today);
        final isSelected =
            state.selectedDate != null &&
            EthiopianCalendarUtil.isSameDay(cellDate, state.selectedDate!);

        // Check if there are notes for this day
        final notesAsync = ref.watch(
          calendarNotesForDateProvider((year: year, month: month, day: day)),
        );
        final notes = notesAsync.valueOrNull ?? const <CalendarNoteModel>[];
        final hasReminder = notes.any((note) => note.hasReminder);
        final hasMedia = notes.any((note) => note.media.isNotEmpty);

        return _buildDayCell(
          context: context,
          theme: theme,
          day: day,
          isToday: isToday,
          isSelected: isSelected,
          hasNotes: notesAsync.maybeWhen(
            data: (notes) => notes.isNotEmpty,
            orElse: () => false,
          ),
          noteCount: notesAsync.maybeWhen(
            data: (notes) => notes.length,
            orElse: () => 0,
          ),
          hasReminder: hasReminder,
          hasMedia: hasMedia,
          onTap: () {
            ref.read(calendarProvider.notifier).selectDate(year, month, day);
            _showDayNotesSheet(context, cellDate);
          },
          onLongPress: () {
            ref.read(calendarProvider.notifier).selectDate(year, month, day);
            _showAddNoteSheet(context, cellDate);
          },
        );
      }, childCount: rows * 7),
    );
  }

  Widget _buildDayCell({
    required BuildContext context,
    required ThemeData theme,
    required int day,
    required bool isToday,
    required bool isSelected,
    required bool hasNotes,
    required int noteCount,
    required bool hasReminder,
    required bool hasMedia,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : (isToday
                ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.3)
                : Colors.transparent),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isToday && !isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  '$day',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: (isToday || isSelected)
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : (isToday
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodyLarge?.color),
                  ),
                ),
              ),
              // Note indicator with count
              if (hasNotes)
                Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            noteCount > 9 ? '9+' : '$noteCount',
                            style: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.onPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (hasReminder || hasMedia)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasMedia)
                        Icon(
                          Icons.attach_file,
                          size: 11,
                          color: theme.colorScheme.secondary,
                        ),
                      if (hasReminder)
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 12,
                          color: theme.colorScheme.tertiary,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayNotesSheet(BuildContext context, EtDatetime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DayNotesSheet(selectedDate: date),
    );
  }

  void _showAddNoteSheet(BuildContext context, EtDatetime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddNoteSheet(selectedDate: date),
    );
  }

  Widget _buildSelectedDateInfo(ThemeData theme, CalendarState state) {
    final selected = state.selectedDate!;
    final gregorian = EthiopianCalendarUtil.toGregorian(selected);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Date',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            EthiopianCalendarUtil.formatEthiopianDate(selected),
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
            EthiopianCalendarUtil.formatGregorianDate(gregorian),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _getGregorianMonthRange(int ethYear, int ethMonth) {
    // Get first and last day of Ethiopian month in Gregorian
    final firstDay = EthiopianCalendarUtil.create(ethYear, ethMonth, 1);
    final daysInMonth = EthiopianCalendarUtil.getDaysInMonth(ethYear, ethMonth);
    final lastDay = EthiopianCalendarUtil.create(
      ethYear,
      ethMonth,
      daysInMonth,
    );

    final firstGregorian = EthiopianCalendarUtil.toGregorian(firstDay);
    final lastGregorian = EthiopianCalendarUtil.toGregorian(lastDay);

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (firstGregorian.month == lastGregorian.month) {
      return '${months[firstGregorian.month - 1]} ${firstGregorian.day}-${lastGregorian.day}, ${firstGregorian.year}';
    } else {
      return '${months[firstGregorian.month - 1]} ${firstGregorian.day} - ${months[lastGregorian.month - 1]} ${lastGregorian.day}, ${firstGregorian.year}';
    }
  }
}
