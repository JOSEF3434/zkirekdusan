// lib/features/calendar/presentation/widgets/calendar_event_details_dialog.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/domain/calendar_event_model.dart';

class CalendarEventDetailsDialog extends ConsumerWidget {
  final CalendarEventModel event;
  final int? selectedDay;
  final int? selectedMonth;
  final int? selectedYear;

  const CalendarEventDetailsDialog({
    super.key,
    required this.event,
    this.selectedDay,
    this.selectedMonth,
    this.selectedYear,
  });

  static Future<void> show(
    BuildContext context, {
    required CalendarEventModel event,
    int? selectedDay,
    int? selectedMonth,
    int? selectedYear,
  }) async {
    final isWide = MediaQuery.of(context).size.width > 600 || kIsWeb;
    if (isWide) {
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
            child: CalendarEventDetailsDialog(
              event: event,
              selectedDay: selectedDay,
              selectedMonth: selectedMonth,
              selectedYear: selectedYear,
            ),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: CalendarEventDetailsDialog(
              event: event,
              selectedDay: selectedDay,
              selectedMonth: selectedMonth,
              selectedYear: selectedYear,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    final eventColor = _parseColor(event.primaryColor) ??
        (event.isFast
            ? Colors.purple.shade700
            : (event.isMajor ? Colors.amber.shade800 : Colors.teal.shade700));

    final dayRoleLabel = _getDayRoleLabel(tr);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: eventColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  event.isFast
                      ? Icons.hourglass_top_rounded
                      : (event.isMajor
                          ? Icons.stars_rounded
                          : Icons.celebration_rounded),
                  color: eventColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamilyFallback: const [
                          'Noto Serif Ethiopic',
                          'Noto Sans Ethiopic',
                        ],
                      ),
                    ),
                    if (event.nameEn != null && event.nameEn!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.nameEn!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Chips: Type, Category, Day Role
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Fast vs Holiday
              Chip(
                backgroundColor: eventColor.withValues(alpha: 0.12),
                label: Text(
                  event.isFast
                      ? tr('calendar.event_type_fast', {'fallback': 'ጾም'})
                      : tr('calendar.event_type_holiday', {'fallback': 'በዓል'}),
                  style: TextStyle(
                    color: eventColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
              ),

              // Category Label
              Chip(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                label: Text(
                  _getCategoryLabel(tr),
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
              ),

              // Day Role if applicable (e.g. Beginning of Fast, Ending, Holiday)
              if (dayRoleLabel != null)
                Chip(
                  avatar: Icon(
                    event.isDayStart(selectedDay ?? 0)
                        ? Icons.flag_rounded
                        : (event.isDayEnd(selectedDay ?? 0)
                            ? Icons.check_circle_rounded
                            : Icons.calendar_today_rounded),
                    size: 14,
                    color: Colors.white,
                  ),
                  backgroundColor: event.isDayStart(selectedDay ?? 0)
                      ? Colors.green.shade700
                      : (event.isDayEnd(selectedDay ?? 0)
                          ? Colors.deepOrange.shade700
                          : eventColor),
                  label: Text(
                    dayRoleLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),

              // Duration Badge
              if (event.durationDays > 1)
                Chip(
                  backgroundColor:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  label: Text(
                    tr('calendar.duration_days', {
                      'count': event.durationDays,
                      'fallback': '${event.durationDays} ቀናት',
                    }),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Date & Time Details Box
          _buildInfoRow(
            context,
            icon: Icons.calendar_month_outlined,
            title: tr('calendar.ethiopian_date', {'fallback': 'የኢትዮጵያ ቀን'}),
            content: _formatEthiopianRange(),
          ),

          if (event.startGregorianDate != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.public_rounded,
              title: tr('calendar.gregorian_equiv',
                  {'fallback': 'የፈረንጆች አቆጣጠር'}),
              content: _formatGregorianRange(),
            ),
          ],

          if (event.description != null &&
              event.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: tr('calendar.description', {'fallback': 'መግለጫ'}),
              content: event.description!,
              theme: theme,
            ),
          ],

          if (event.spiritualMeaning != null &&
              event.spiritualMeaning!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: tr('calendar.spiritual_meaning',
                  {'fallback': 'መንፈሳዊ እና ታሪካዊ ትርጉም'}),
              content: event.spiritualMeaning!,
              theme: theme,
              icon: Icons.auto_stories_rounded,
            ),
          ],

          if (event.fastingRules != null &&
              event.fastingRules!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: tr('calendar.fasting_rules',
                  {'fallback': 'የጾም ሥርዓት እና መመሪያ'}),
              content: event.fastingRules!,
              theme: theme,
              icon: Icons.rule_rounded,
            ),
          ],

          const SizedBox(height: 24),

          // Close button
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr('common.close', {'fallback': 'ዝጋ'})),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: const [
                    'Noto Serif Ethiopic',
                    'Noto Sans Ethiopic',
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
    required ThemeData theme,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontFamilyFallback: const [
                    'Noto Serif Ethiopic',
                    'Noto Sans Ethiopic',
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              fontFamilyFallback: const [
                'Noto Serif Ethiopic',
                'Noto Sans Ethiopic',
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEthiopianRange() {
    final startM = EthiopianCalendarUtil.getMonthName(event.startMonth);
    final endM = EthiopianCalendarUtil.getMonthName(event.endMonth);
    final year = selectedYear ?? event.ethiopianYear;
    final yearSuffix = year != null ? ' $year' : '';

    if (event.startMonth == event.endMonth) {
      if (event.startDay == event.endDay) {
        return '${event.startDay} $startM$yearSuffix';
      }
      return 'ከ ${event.startDay} - ${event.endDay} $startM$yearSuffix';
    }

    return 'ከ ${event.startDay} $startM እስከ ${event.endDay} $endM$yearSuffix';
  }

  String _formatGregorianRange() {
    if (event.startGregorianDate == null) return '';
    try {
      final start = DateTime.parse(event.startGregorianDate!);
      final end = event.endGregorianDate != null
          ? DateTime.parse(event.endGregorianDate!)
          : start;

      if (start.year == end.year &&
          start.month == end.month &&
          start.day == end.day) {
        return EthiopianCalendarUtil.formatGregorianDate(start);
      }

      return '${EthiopianCalendarUtil.formatGregorianDate(start)} – ${EthiopianCalendarUtil.formatGregorianDate(end)}';
    } catch (_) {
      return '';
    }
  }

  String _getCategoryLabel(String Function(String, [Map<String, dynamic>?]) tr) {
    switch (event.category) {
      case CalendarEventCategory.majorFast:
        return tr('calendar.major_fast', {'fallback': 'ዐቢይ ጾም'});
      case CalendarEventCategory.minorFast:
        return tr('calendar.minor_fast', {'fallback': 'ንኡስ ጾም'});
      case CalendarEventCategory.majorHoliday:
        return tr('calendar.major_holiday', {'fallback': 'ዓቢይ በዓል'});
      case CalendarEventCategory.minorHoliday:
        return tr('calendar.minor_holiday', {'fallback': 'ንኡስ በዓል'});
      case CalendarEventCategory.monthlyFeast:
        return tr('calendar.monthly_feast', {'fallback': 'ወርሃዊ በዓል'});
      case CalendarEventCategory.annualFeast:
        return tr('calendar.annual_feast', {'fallback': 'ዓመታዊ በዓል'});
    }
  }

  String? _getDayRoleLabel(
      String Function(String, [Map<String, dynamic>?]) tr) {
    if (selectedDay == null) return null;

    if (event.isFast) {
      if (event.isDayStart(selectedDay!)) {
        return tr('calendar.fast_start', {'fallback': 'ጾም መግቢያ'});
      }
      if (event.isDayEnd(selectedDay!)) {
        return tr('calendar.fast_end', {'fallback': 'ጾም መፍቻ / ፍጻሜ'});
      }
      return tr('calendar.fast_ongoing', {'fallback': 'የጾም ዕለት'});
    } else {
      return tr('calendar.event_type_holiday', {'fallback': 'ክብረ በዓል'});
    }
  }

  Color? _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return null;
    try {
      final hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return null;
  }
}
