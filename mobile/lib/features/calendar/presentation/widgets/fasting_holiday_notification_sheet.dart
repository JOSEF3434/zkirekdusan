// lib/features/calendar/presentation/widgets/fasting_holiday_notification_sheet.dart
// Interactive sheet to adjust Ethiopian Orthodox fasting and holiday notification settings and times.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/presentation/providers/fasting_holiday_notification_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/calendar_color_settings_sheet.dart';

class FastingHolidayNotificationSheet extends ConsumerWidget {
  const FastingHolidayNotificationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const FastingHolidayNotificationSheet(),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref, {
    required bool isTime1,
    required TimeOfDay initialTime,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isTime1 ? '1ኛ ማሳወቂያ ሰዓት ይምረጡ' : '2ኛ ማሳወቂያ ሰዓት ይምረጡ',
      cancelText: 'ይቅር',
      confirmText: 'ምረጥ',
    );

    if (picked != null) {
      final notifier = ref.read(fastingHolidayNotificationProvider.notifier);
      if (isTime1) {
        await notifier.updateTime1(picked);
      } else {
        await notifier.updateTime2(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tr = ref.watch(trProvider);
    final state = ref.watch(fastingHolidayNotificationProvider);
    final notifier = ref.read(fastingHolidayNotificationProvider.notifier);

    final etTime1 = EthiopianCalendarUtil.toEthiopianTime(
      state.time1.hour,
      state.time1.minute,
    );
    final etTime2 = EthiopianCalendarUtil.toEthiopianTime(
      state.time2.hour,
      state.time2.minute,
    );

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(
                        'calendar.fasting_holiday_notif_title',
                        {'fallback': 'የአጽዋማት እና የበዓላት ማሳወቂያ'},
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamilyFallback: const [
                          'Noto Serif Ethiopic',
                          'Noto Sans Ethiopic',
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr(
                        'calendar.fasting_holiday_notif_sub',
                        {'fallback': 'በጾም እና በበዓል ቀናት ጠዋት በሰዓቱ ማሳወቂያ ይቀበሉ'},
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
              // Main Toggle
              Switch(
                value: state.isEnabled,
                activeThumbColor: const Color(0xFFF59E0B),
                activeTrackColor: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                onChanged: (val) async {
                  await notifier.setEnabled(val);
                },
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),

          if (!state.isEnabled)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ማሳወቂያው በአሁኑ ጊዜ ጠፍቷል። ማብሪያውን ሲያበሩ በጾም እና በበዓላት ቀናት በጠዋት 2:00 እና 5:30 ማሳወቂያ ይደርስዎታል።',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              'የማሳወቂያ ሰዓቶችን ማስተካከል (Adjust Times)',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 12),

            // Time 1 Tile (Default: ጧት 2:00 = 8:00 AM)
            _buildTimeCard(
              context: context,
              theme: theme,
              isDark: isDark,
              title: '1ኛ ማሳወቂያ (First Reminder)',
              ethiopianTime: etTime1.formatAmharic(),
              gregorianTime: etTime1.formatGregorian(),
              isDefault: state.time1.hour == 8 && state.time1.minute == 0,
              onTap: () => _pickTime(
                context,
                ref,
                isTime1: true,
                initialTime: state.time1,
              ),
            ),
            const SizedBox(height: 10),

            // Time 2 Tile (Default: ጧት 5:30 = 11:30 AM)
            _buildTimeCard(
              context: context,
              theme: theme,
              isDark: isDark,
              title: '2ኛ ማሳወቂያ (Second Reminder)',
              ethiopianTime: etTime2.formatAmharic(),
              gregorianTime: etTime2.formatGregorian(),
              isDefault: state.time1.hour == 11 && state.time1.minute == 30,
              onTap: () => _pickTime(
                context,
                ref,
                isTime1: false,
                initialTime: state.time2,
              ),
            ),

            const SizedBox(height: 16),

            // Test Notification Button
            OutlinedButton.icon(
              onPressed: () async {
                await notifier.sendTestNotification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('የሙከራ ማሳወቂያ ተልኳል!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: const Text('የሙከራ ማሳወቂያ ላክ (Send Test Alert)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B),
                side: BorderSide(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Shortcut to Calendar Color Settings
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              CalendarColorSettingsSheet.show(context);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF28283E) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.palette_rounded,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('calendar.customize_colors', {'fallback': 'የቀን መቁጠሪያ ቀለሞች'}),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tr(
                            'calendar.customize_colors_sub',
                            {'fallback': 'የጾም እና የበዓላት መለያ ቀለሞችን ያብጁ'},
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTimeCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required String title,
    required String ethiopianTime,
    required String gregorianTime,
    required bool isDefault,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.35 : 0.6,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              color: Color(0xFFF59E0B),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        ethiopianTime,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamilyFallback: const [
                            'Noto Serif Ethiopic',
                            'Noto Sans Ethiopic',
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($gregorianTime)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFF59E0B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ቀይር',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFF59E0B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
