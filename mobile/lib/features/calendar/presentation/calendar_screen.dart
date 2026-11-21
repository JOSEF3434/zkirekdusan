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
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/admin/presentation/widgets/manage_calendar_event_dialog.dart';
import 'package:mobile/features/calendar/alephat/presentation/providers/alephat_providers.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/alephat_learning_view.dart';
import 'package:mobile/features/calendar/presentation/providers/fasting_holiday_notification_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/fasting_holiday_notification_sheet.dart';
import 'package:mobile/features/calendar/presentation/widgets/create_user_event_dialog.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  bool _canManage(WidgetRef ref) {
    final role = ref.watch(authProvider).user?.role ?? '';
    final canManageCal = ref.watch(adminPermissionsProvider).canManageCalendar;
    return role == 'SUPER_ADMIN' || canManageCal;
  }

  double _getHorizontalMargin(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > 1200) return 36.0;
    if (width > 800) return 24.0;
    return 16.0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canManage = _canManage(ref);
    final calendarState = ref.watch(calendarProvider);
    final fastingHolidayState = ref.watch(fastingHolidayNotificationProvider);
    final tr = ref.watch(trProvider);
    final topTab = ref.watch(calendarTopTabProvider);
    final horizontalMargin = _getHorizontalMargin(context);

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
              toolbarHeight: 56,
              titleSpacing: horizontalMargin > 16 ? horizontalMargin : 12,
              centerTitle: false,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      EthiopianCalendarUtil.getMonthName(calendarState.month),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamilyFallback: const [
                          'Noto Serif Ethiopic',
                          'Noto Sans Ethiopic',
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${calendarState.year}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                // Add Event / Reminder button for any user
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.add_alarm_rounded, size: 20),
                  tooltip: tr(
                    'calendar.add_user_event',
                    {'fallback': 'ሁነት / ማሳሰቢያ አክል'},
                  ),
                  onPressed: () {
                    CreateUserEventDialog.show(
                      context,
                      initialYear: calendarState.year,
                      initialMonth: calendarState.month,
                      initialDay: calendarState.selectedDate?.day,
                    );
                  },
                ),
                // Fasting & Holiday Notifications settings shortcut
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    fastingHolidayState.isEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: fastingHolidayState.isEnabled
                        ? const Color(0xFFF59E0B)
                        : null,
                    size: 20,
                  ),
                  tooltip: tr(
                    'calendar.fasting_holiday_notif_title',
                    {'fallback': 'የአጽዋማት እና የበዓላት ማሳወቂያ'},
                  ),
                  onPressed: () {
                    FastingHolidayNotificationSheet.show(context);
                  },
                ),
                // Sync status indicator
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.0),
                  child: SyncStatusIndicator(),
                ),
                // Today button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.today, size: 20),
                  tooltip: tr('calendar.today_tooltip'),
                  onPressed: () =>
                      ref.read(calendarProvider.notifier).goToToday(),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.chevron_left, size: 20),
                  tooltip: tr('calendar.prev_month'),
                  onPressed: () =>
                      ref.read(calendarProvider.notifier).previousMonth(),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.chevron_right, size: 20),
                  tooltip: tr('calendar.next_month'),
                  onPressed: () =>
                      ref.read(calendarProvider.notifier).nextMonth(),
                ),
                SizedBox(width: horizontalMargin > 16 ? horizontalMargin - 12 : 4),
              ],
            ),

            // Gregorian equivalent
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalMargin,
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
            SliverToBoxAdapter(child: _buildWeekdayHeader(theme, horizontalMargin)),

            // Calendar grid
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 8),
              sliver: _buildCalendarGrid(theme, calendarState, ref, canManage),
            ),

            // Selected date info
            if (calendarState.selectedDate != null)
              SliverToBoxAdapter(
                child: _buildSelectedDateInfo(theme, calendarState, horizontalMargin),
              ),

            // Monthly Fasting & Holiday Summary
            SliverToBoxAdapter(
              child: MonthlyFastsHolidaysSummary(
                year: calendarState.year,
                month: calendarState.month,
                horizontalMargin: horizontalMargin,
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

  Widget _buildWeekdayHeader(ThemeData theme, double horizontalMargin) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: horizontalMargin),
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
        final hasSpecialEvent = dayEvents.any((e) => e.isSpecialEvent);
        final isFastStart = dayEvents.any((e) =>
            e.isFast &&
            !e.isSingleDay &&
            e.durationDays > 1 &&
            !e.id.contains('wed-fri') &&
            !e.name.contains('ድኅነት') &&
            !e.name.contains('የረቡዕ እና የዓርብ') &&
            e.isDayStart(day));
        final isFastEnd = dayEvents.any((e) =>
            e.isFast &&
            !e.isSingleDay &&
            e.durationDays > 1 &&
            !e.id.contains('wed-fri') &&
            !e.name.contains('ድኅነት') &&
            !e.name.contains('የረቡዕ እና የዓርብ') &&
            e.isDayEnd(day));
        final isMajorHoliday = dayEvents.any((e) => e.isMajorHoliday);
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
          hasSpecialEvent: hasSpecialEvent,
          isFastStart: isFastStart,
          isFastEnd: isFastEnd,
          isMajorHoliday: isMajorHoliday,
          isMajorFast: isMajorFast,
          onTap: () {
            ref.read(calendarProvider.notifier).selectDate(year, month, day);
            _showDayNotesSheet(context, cellDate);
          },
          onLongPress: () {
            // Holding/long pressing a specific day triggers add event functionality
            CreateUserEventDialog.show(
              context,
              initialYear: cellDate.year,
              initialMonth: cellDate.month,
              initialDay: cellDate.day,
            );
          },
          onSecondaryTap: () {
            _showDayContextMenu(context, cellDate, dayEvents);
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
    required bool hasSpecialEvent,
    required bool isFastStart,
    required bool isFastEnd,
    required bool isMajorHoliday,
    required bool isMajorFast,
    required VoidCallback onTap,
    required VoidCallback? onLongPress,
    required VoidCallback? onSecondaryTap,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    // Refined compatible liturgical colors:
    // Fasting: warm amber gold (#F59E0B / #D97706)
    // Major Holiday: crimson red (#DC2626)
    // Special Event / Feast: emerald green (#16A34A)
    final fastColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    const redColor = Color(0xFFDC2626);
    const greenColor = Color(0xFF16A34A);

    Color? textColor;
    if (isSelected) {
      textColor = theme.colorScheme.onPrimaryContainer;
    } else if (isToday) {
      textColor = theme.colorScheme.primary;
    } else if (hasFast) {
      // Clean readable text: warm ivory in dark mode, deep amber in light mode
      textColor = isDark ? const Color(0xFFFEF3C7) : const Color(0xFFB45309);
    } else if (hasSpecialEvent) {
      textColor = isDark ? const Color(0xFF86EFAC) : greenColor;
    } else {
      textColor = theme.textTheme.bodyLarge?.color;
    }

    final isBold = isToday ||
        isSelected ||
        isMajorHoliday ||
        isFastStart ||
        isFastEnd ||
        hasSpecialEvent;

    // Background color:
    // For holidays, the star is enough — do NOT color the box.
    Color backgroundColor;
    if (isSelected) {
      backgroundColor = theme.colorScheme.primaryContainer;
    } else if (isToday) {
      backgroundColor = theme.colorScheme.secondaryContainer.withValues(alpha: 0.3);
    } else if (hasFast) {
      // 4.5% opacity in dark mode gives a pristine, gentle golden sheen rather than dark muddy brown
      backgroundColor = fastColor.withValues(alpha: isDark ? 0.045 : 0.06);
    } else if (hasSpecialEvent) {
      backgroundColor = greenColor.withValues(alpha: isDark ? 0.10 : 0.06);
    } else {
      backgroundColor = Colors.transparent;
    }

    // Border: highlighting today, fast, or special event.
    // For holidays, the star is enough — do NOT color the box outline.
    Border? border;
    if (isToday && !isSelected) {
      border = Border.all(color: theme.colorScheme.primary, width: 2);
    } else if (hasFast && !isSelected) {
      border = Border.all(color: fastColor.withValues(alpha: isDark ? 0.22 : 0.28), width: 1);
    } else if (hasSpecialEvent && !isSelected) {
      border = Border.all(color: greenColor.withValues(alpha: isDark ? 0.35 : 0.45), width: 1);
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: onSecondaryTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: border,
          ),
          child: Stack(
            children: [
              // Top-left badge: Fast end (Green መጨረሻ), Fast start (Green መግቢያ), or Major Holiday star (Red)
              if (isFastEnd)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: greenColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'መጨረሻ',
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
              else if (isFastStart)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: greenColor,
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
              else if (isMajorHoliday)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: redColor,
                  ),
                )
              else if (hasSpecialEvent)
                Positioned(
                  top: 3,
                  left: 3,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: greenColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

              // If day has both fasting and holiday, show holiday star at top right when start/end badge occupies top-left
              if (isMajorHoliday && (isFastStart || isFastEnd))
                Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: redColor,
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

              // Bottom Indicator Row: Fast Dot (Orange) + Holiday Dot (Red) + Special Dot (Green) + Note Count Badge
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
                            color: fastColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (hasHoliday && !isMajorHoliday)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD97706),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (hasSpecialEvent)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: const BoxDecoration(
                            color: greenColor,
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

              // Top-right Icons: Media & Reminder (when not occupied by holiday star)
              if ((hasReminder || hasMedia) && !(isMajorHoliday && (isFastStart || isFastEnd)))
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

  void _showDayContextMenu(
    BuildContext context,
    EtDatetime cellDate,
    List<CalendarEventModel> dayEvents,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final tr = ref.watch(trProvider);
          final canManage = _canManage(ref);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          EthiopianCalendarUtil.formatEthiopianDate(cellDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  if (dayEvents.isNotEmpty)
                    ListTile(
                      leading: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFF59E0B),
                      ),
                      title: Text(
                        dayEvents.length > 1
                            ? '${tr('calendar.multiple_events', {'fallback': 'ሁነቶች'})} (${dayEvents.length})'
                            : dayEvents.first.name,
                      ),
                      subtitle: Text(
                        dayEvents.map((e) => e.name).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        CalendarEventDetailsDialog.show(
                          context,
                          events: dayEvents,
                          selectedDay: cellDate.day,
                          selectedMonth: cellDate.month,
                          selectedYear: cellDate.year,
                        );
                      },
                    ),
                  if (canManage)
                    ListTile(
                      leading: const Icon(
                        Icons.app_registration_rounded,
                        color: Color(0xFF16A34A),
                      ),
                      title: Text(
                        tr(
                          'calendar.configure_day',
                          {'fallback': 'ይህንን ቀን አመቻች/መዝግብ'},
                        ),
                      ),
                      subtitle: const Text('ጾም፣ በዓል ወይም የቀን ቀለም አዋቅር'),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ManageCalendarEventDialog.show(
                          context,
                          prefillYear: cellDate.year,
                          prefillMonth: cellDate.month,
                          prefillDay: cellDate.day,
                        );
                      },
                    ),
                  ListTile(
                    leading: const Icon(
                      Icons.add_alarm_rounded,
                      color: Color(0xFF00C6FF),
                    ),
                    title: Text(
                      tr(
                        'calendar.add_user_event',
                        {'fallback': 'ለዚህ ቀን ሁነት / ማሳሰቢያ መዝግብ'},
                      ),
                    ),
                    subtitle: const Text('የግል ማስታወሻ እና የማሳወቂያ ሰዓት ያስቀምጡ'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      CreateUserEventDialog.show(
                        context,
                        initialYear: cellDate.year,
                        initialMonth: cellDate.month,
                        initialDay: cellDate.day,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.note_alt_outlined),
                    title: Text(
                      tr('calendar.tab_calendar', {'fallback': 'ማስታወሻዎች'}),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ref.read(calendarProvider.notifier).selectDate(
                            cellDate.year,
                            cellDate.month,
                            cellDate.day,
                          );
                      _showDayNotesSheet(context, cellDate);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDateInfo(
    ThemeData theme,
    CalendarState state,
    double horizontalMargin,
  ) {
    final selected = state.selectedDate!;
    final gregorian = EthiopianCalendarUtil.toGregorian(selected);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 8),
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
