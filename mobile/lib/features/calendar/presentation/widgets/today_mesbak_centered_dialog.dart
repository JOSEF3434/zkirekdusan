// lib/features/calendar/presentation/widgets/today_mesbak_centered_dialog.dart
import 'package:abushakir/abushakir.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/data/calendar_offline_repository.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/presentation/widgets/mesbak_popup_dialog.dart';

class TodayMesbakCenteredDialog extends ConsumerWidget {
  final CalendarNoteModel mesbak;
  final EtDatetime today;

  const TodayMesbakCenteredDialog({
    super.key,
    required this.mesbak,
    required this.today,
  });

  /// Checks if there is an unseen today mesbak and displays the small centered dialog.
  static Future<void> checkAndShow(BuildContext context, WidgetRef ref) async {
    try {
      final now = EthiopianCalendarUtil.now();
      final todayKey = '${now.year}-${now.month}-${now.day}';

      final prefs = ref.read(sharedPreferencesProvider);
      final lastSeenDate = prefs.getString('last_seen_mesbak_date');
      final lastSeenId = prefs.getString('last_seen_mesbak_id');

      // Fetch today's notes
      final repository = ref.read(calendarOfflineRepositoryProvider);
      final notes = await repository.getNotesForDate(
        year: now.year,
        month: now.month,
        day: now.day,
      );

      final validNotes = notes.where((n) => n.deletedAt == null).toList();
      if (validNotes.isEmpty) return;

      final todayMesbak = validNotes.first;

      // If already seen this specific mesbak today, do not show
      if (lastSeenDate == todayKey && lastSeenId == todayMesbak.id) {
        return;
      }

      // Mark as seen immediately in SharedPreferences
      await prefs.setString('last_seen_mesbak_date', todayKey);
      await prefs.setString('last_seen_mesbak_id', todayMesbak.id);

      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => TodayMesbakCenteredDialog(
          mesbak: todayMesbak,
          today: now,
        ),
      );
    } catch (_) {
      // Non-critical background check — ignore silently
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    final dayName = EthiopianCalendarUtil.getWeekdayName(today.weekday);
    final monthName = EthiopianCalendarUtil.getMonthName(today.month);
    final dateSubtitle = '$dayName፣ ${today.day} $monthName ${today.year} ዓ.ም.';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top decorative circular badge
              Container(
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFDF7A),
                      Color(0xFFE5A93C),
                      Color(0xFFB8860B),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB8860B).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFF4A3400),
                  size: 28,
                ),
              ),

              const SizedBox(height: 14),

              // Title: የእለቱ ምስባክ
              Text(
                tr('calendar.today_mesbak', {'fallback': 'የእለቱ ምስባክ'}),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamilyFallback: const [
                    'Noto Serif Ethiopic',
                    'Noto Sans Ethiopic',
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              // Date pill badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  dateSubtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7A5800),
                    fontFamilyFallback: [
                      'Noto Serif Ethiopic',
                      'Noto Sans Ethiopic',
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Mesbak title if available
              if (mesbak.title != null && mesbak.title!.isNotEmpty) ...[
                Text(
                  mesbak.title!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontFamilyFallback: const [
                      'Noto Serif Ethiopic',
                      'Noto Sans Ethiopic',
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Content box with psalm verses
              if (mesbak.content != null && mesbak.content!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      mesbak.content!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.55,
                        fontSize: 13.5,
                        fontFamilyFallback: const [
                          'Noto Serif Ethiopic',
                          'Noto Sans Ethiopic',
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      tr('common.close', {'fallback': 'ዝጋ'}),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      MesbakPopupDialog.show(context);
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(
                      tr('calendar.view_full', {'fallback': 'ሙሉውን እይ'}),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
