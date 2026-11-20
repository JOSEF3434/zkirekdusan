// lib/features/calendar/presentation/calendar_screen.dart
// Ethiopian Calendar with modern UI, month navigation, date selection, and notes

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abushakir/abushakir.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_state_provider.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/day_notes_sheet.dart';
import 'package:mobile/features/calendar/presentation/widgets/add_note_sheet.dart';
import 'package:mobile/features/calendar/presentation/widgets/sync_status_indicator.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_sync_provider.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/domain/calendar_event_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_events_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/monthly_fasts_holidays_summary.dart';
import 'package:mobile/features/calendar/presentation/widgets/calendar_event_details_dialog.dart';
import 'package:mobile/features/calendar/alephat/presentation/providers/alephat_providers.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/alephat_learning_view.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  bool _canManage(WidgetRef ref) {
    final role = ref.watch(authProvider).user?.role ?? '';
    return role == 'SUPER_ADMIN';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canManage = _canManage(ref);
    final calendarState = ref.watch(calendarProvider);
    final tr = ref.watch(trProvider);
    final topTab = ref.watch(calendarTopTabProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Container(
                margin: const EdgeInsets.only(
                  top: 10,
                  bottom: 6,
                  left: 20,
                  right: 20,
                ),
                child: SegmentedButton<int>(
              segments: [
                ButtonSegment<int>(
                  value: 0,
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(
                    tr('calendar.tab_calendar', {'fallback': 'ቀን መቁጠሪያ'}),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamilyFallback: [
                        'Noto Serif Ethiopic',
                        'Noto Sans Ethiopic',
                      ],
                    ),
                  ),
                ),
                ButtonSegment<int>(
                  value: 1,
                  icon: const Icon(Icons.school_outlined, size: 18),
                  label: Text(
                    tr('calendar.tab_alephat', {'fallback': 'ትምህርተ አሌፋት'}),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamilyFallback: [
                        'Noto Serif Ethiopic',
                        'Noto Sans Ethiopic',
                      ],
                    ),
                  ),
                ),
              ],
              selected: {topTab},
              onSelectionChanged: (newSelection) {
                ref.read(calendarTopTabProvider.notifier).state =
                    newSelection.first;
              },
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
  body: topTab == 0
          ? RefreshIndicator(
              onRefresh: () async {
                // Trigger manual sync
                final quickSync = ref.read(quickSyncProvider);
                await quickSync();

                // Refresh current month notes & fasts/holidays
                ref.invalidate(calendarNotesForMonthProvider);
                ref.invalidate(calendarEventsForMonthProvider((
                  year: calendarState.year,
                  month: calendarState.month,
                )));
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
                  tooltip: tr('calendar.today_tooltip'),
                  onPressed: () =>
                      ref.read(calendarProvider.notifier).goToToday(),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: tr('calendar.prev_month'),
                  onPressed: () =>
                      ref.read(calendarProvider.notifier).previousMonth(),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: tr('calendar.next_month'),
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
              sliver: _buildCalendarGrid(theme, calendarState, ref, canManage),
            ),

            // Selected date info
            if (calendarState.selectedDate != null)
              SliverToBoxAdapter(
                child: _buildSelectedDateInfo(theme, calendarState),
              ),

            // Monthly Fasting & Holiday Summary
            SliverToBoxAdapter(
              child: MonthlyFastsHolidaysSummary(
                year: calendarState.year,
                month: calendarState.month,
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      )
    : const AlephatLearningView(),
      floatingActionButton: topTab == 0 && canManage && calendarState.selectedDate != null
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () {
                _showAddNoteSheet(context, calendarState.selectedDate!);
              },
              icon: const Icon(Icons.add),
              label: Text(tr('calendar.add_note')),
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
    bool canManage,
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
    final monthNotesAsync = ref.watch(
      calendarNotesForMonthProvider((year: year, month: month)),
    );
    final monthNotes =
        monthNotesAsync.valueOrNull ?? const <CalendarNoteModel>[];
    final monthEventsAsync = ref.watch(
      calendarEventsForMonthProvider((year: year, month: month)),
    );
    final monthEvents =
        monthEventsAsync.valueOrNull ?? const <CalendarEventModel>[];

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

        // Check if there are notes for this day (month provider with day-provider fallback)
        final dayNotesFromMonth =
            monthNotes.where((note) => note.ethiopianDay == day).toList();
        final dateNotesAsync = ref.watch(
          calendarNotesForDateProvider((year: year, month: month, day: day)),
        );
        final notes = (dateNotesAsync.valueOrNull?.isNotEmpty ?? false)
            ? dateNotesAsync.valueOrNull!
            : dayNotesFromMonth;
        final hasNotes = notes.isNotEmpty;
        final noteCount = notes.length;
        final hasReminder = notes.any((note) => note.hasReminder);
        final hasMedia = notes.any((note) => note.media.isNotEmpty);

        // Check if there are fasts or holidays covering this day
        final dayEvents = monthEvents.where((e) {
          if (e.coverage != null) {
            return e.coverage!.days.contains(day);
          }
          return false;
        }).toList();

        final hasFast = dayEvents.any((e) => e.isFast);
        final hasHoliday = dayEvents.any((e) => e.isHoliday);
        final isFastStart = dayEvents.any((e) => e.isFast && e.isDayStart(day));
        final isFastEnd = dayEvents.any((e) => e.isFast && e.isDayEnd(day));
        final isMajorHoliday = dayEvents.any((e) => e.isHoliday && e.isMajor);
        final isMajorFast = dayEvents.any((e) => e.isFast && e.isMajor);

        return _buildDayCell(
          context: context,
          theme: theme,
          day: day,
          isToday: isToday,
          isSelected: isSelected,
          hasNotes: hasNotes,
          noteCount: noteCount,
          hasReminder: hasReminder,
          hasMedia: hasMedia,
          dayEvents: dayEvents,
          hasFast: hasFast,
          hasHoliday: hasHoliday,
          isFastStart: isFastStart,
          isFastEnd: isFastEnd,
          isMajorHoliday: isMajorHoliday,
          isMajorFast: isMajorFast,
          onTap: () {
            ref.read(calendarProvider.notifier).selectDate(year, month, day);
            _showDayNotesSheet(context, cellDate);
          },
          onLongPress: () {
            if (dayEvents.isNotEmpty) {
              CalendarEventDetailsDialog.show(
                context,
                event: dayEvents.first,
                selectedDay: day,
                selectedMonth: month,
                selectedYear: year,
              );
            } else if (canManage) {
              ref.read(calendarProvider.notifier).selectDate(year, month, day);
              _showAddNoteSheet(context, cellDate);
            }
          },
          onSecondaryTap: () {
            if (dayEvents.isNotEmpty) {
              CalendarEventDetailsDialog.show(
                context,
                event: dayEvents.first,
                selectedDay: day,
                selectedMonth: month,
                selectedYear: year,
              );
            } else {
              ref.read(calendarProvider.notifier).selectDate(year, month, day);
              _showDayNotesSheet(context, cellDate);
            }
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
    required List<CalendarEventModel> dayEvents,
    required bool hasFast,
    required bool hasHoliday,
    required bool isFastStart,
    required bool isFastEnd,
    required bool isMajorHoliday,
    required bool isMajorFast,
    required VoidCallback onTap,
    required VoidCallback? onLongPress,
    required VoidCallback? onSecondaryTap,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    Color? textColor;
    if (isSelected) {
      textColor = theme.colorScheme.onPrimaryContainer;
    } else if (isToday) {
      textColor = theme.colorScheme.primary;
    } else if (isMajorHoliday) {
      textColor = isDark ? Colors.amber.shade300 : Colors.amber.shade900;
    } else if (hasFast) {
      textColor = isDark ? Colors.purple.shade200 : Colors.purple.shade800;
    } else {
      textColor = theme.textTheme.bodyLarge?.color;
    }

    final isBold = isToday ||
        isSelected ||
        isMajorHoliday ||
        isFastStart ||
        isFastEnd;

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : (isToday
              ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.3)
              : (hasFast
                  ? Colors.purple.withValues(alpha: isDark ? 0.08 : 0.04)
                  : Colors.transparent)),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: onSecondaryTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isToday && !isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : (isMajorHoliday && !isSelected
                    ? Border.all(
                        color: Colors.amber.withValues(alpha: 0.6),
                        width: 1,
                      )
                    : null),
          ),
          child: Stack(
            children: [
              // Top-left badge: Fast start/end or Major Holiday star
              if (isFastStart)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'መግቢያ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        fontFamilyFallback: [
                          'Noto Serif Ethiopic',
                          'Noto Sans Ethiopic',
                        ],
                      ),
                    ),
                  ),
                )
              else if (isFastEnd)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ፍጻሜ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        fontFamilyFallback: [
                          'Noto Serif Ethiopic',
                          'Noto Sans Ethiopic',
                        ],
                      ),
                    ),
                  ),
                )
              else if (isMajorHoliday)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Colors.amber.shade800,
                  ),
                ),

              // Day Number
              Center(
                child: Text(
                  '$day',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    color: textColor,
                  ),
                ),
              ),

              // Bottom Indicator Row: Fast Dot + Holiday Dot + Note Count Badge
              Positioned(
                bottom: 3,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasFast)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: isFastStart
                                ? Colors.green.shade700
                                : (isFastEnd
                                    ? Colors.deepOrange.shade700
                                    : const Color(0xFF7C3AED)),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (hasHoliday)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: isMajorHoliday
                                ? Colors.amber.shade800
                                : Colors.teal.shade700,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (hasNotes)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            noteCount > 9 ? '9+' : '$noteCount',
                            style: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.onPrimary,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Top-right Icons: Media & Reminder
              if (hasReminder || hasMedia)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasMedia)
                        Icon(
                          Icons.attach_file,
                          size: 10,
                          color: theme.colorScheme.secondary,
                        ),
                      if (hasReminder)
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 11,
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
      child: Consumer(
        builder: (context, ref, _) {
          final tr = ref.watch(trProvider);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('calendar.selected_date'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
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
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
            ],
          );
        },
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
