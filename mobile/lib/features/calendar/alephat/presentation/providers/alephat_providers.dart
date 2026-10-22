// lib/features/calendar/alephat/presentation/providers/alephat_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/calendar/alephat/data/alephat_repository.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_letter_model.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_22_model.dart';

// Top-level tab: 0 = ቀን መቁጠሪያ (Calendar), 1 = ትምህርተ አሌፋት (Alephat Learning)
final calendarTopTabProvider = StateProvider<int>((ref) => 0);

// Nested Alephat tab: 0 = ፊደላት (Letter Families), 1 = 22 አሌፋት (22 Alephats)
final alephatNestedTabProvider = StateProvider<int>((ref) => 0);

// Search queries
final alephatLetterSearchProvider = StateProvider<String>((ref) => '');
final alephat22SearchProvider = StateProvider<String>((ref) => '');

// Currently selected base letter ID
final selectedBaseLetterIdProvider = StateProvider<String?>((ref) => null);

// Currently selected family member order index (1..8). If null, base letter's default note is shown.
final selectedFamilyMemberOrderProvider = StateProvider<int?>((ref) => null);

// Selected 22 Alephat entry for detailed preview
final selected22EntryProvider = StateProvider<Alephat22Model?>((ref) => null);

// ─────────────────────────────────────────────────────────
// Layout Preference: Horizontal Scrolling vs Keyboard Grid
// ─────────────────────────────────────────────────────────

enum AlephatLayoutMode { horizontal, grid }

class AlephatLayoutNotifier extends StateNotifier<AlephatLayoutMode> {
  final SharedPreferences? _prefs;
  static const String _prefKey = 'alephat_layout_mode';

  AlephatLayoutNotifier(this._prefs) : super(_loadInitialMode(_prefs));

  static AlephatLayoutMode _loadInitialMode(SharedPreferences? prefs) {
    final saved = prefs?.getString(_prefKey);
    if (saved == 'horizontal') return AlephatLayoutMode.horizontal;
    return AlephatLayoutMode.grid;
  }

  Future<void> setLayoutMode(AlephatLayoutMode mode) async {
    if (state == mode) return;
    state = mode;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      mode == AlephatLayoutMode.grid ? 'grid' : 'horizontal',
    );
  }

  Future<void> toggleLayoutMode() async {
    final next = state == AlephatLayoutMode.horizontal
        ? AlephatLayoutMode.grid
        : AlephatLayoutMode.horizontal;
    await setLayoutMode(next);
  }
}

final alephatLayoutModeProvider =
    StateNotifierProvider<AlephatLayoutNotifier, AlephatLayoutMode>((ref) {
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {
    // If not overridden in simple widget/unit tests
  }
  return AlephatLayoutNotifier(prefs);
});

// Offline & Synchronization state flag
final alephatIsUsingOfflineCacheProvider = StateProvider<bool>((ref) => false);

// ─────────────────────────────────────────────────────────
// Tab 1: Base Letters provider (Offline-First)
// ─────────────────────────────────────────────────────────

final alephatLettersProvider =
    FutureProvider.autoDispose<List<AlephatLetterModel>>((ref) async {
  final repo = ref.watch(alephatRepositoryProvider);
  final search = ref.watch(alephatLetterSearchProvider);
  final perms = ref.watch(adminPermissionsProvider);

  // Auto-refresh when internet connectivity returns
  ref.listen(connectivityProvider, (previous, next) {
    if (previous?.isOnline == false && next.isOnline == true) {
      ref.invalidateSelf();
    }
  });

  final letters = await repo.getLetters(
    search: search.trim().isEmpty ? null : search.trim(),
    includeUnpublished: perms.canManageAlephat ? true : null,
  );

  final connState = ref.read(connectivityProvider);
  ref.read(alephatIsUsingOfflineCacheProvider.notifier).state =
      connState.isOffline;

  return letters;
});

// ─────────────────────────────────────────────────────────
// Tab 2: 22 Alephats list provider (Offline-First)
// ─────────────────────────────────────────────────────────

final alephat22ListProvider =
    FutureProvider.autoDispose<List<Alephat22Model>>((ref) async {
  final repo = ref.watch(alephatRepositoryProvider);
  final search = ref.watch(alephat22SearchProvider);
  final perms = ref.watch(adminPermissionsProvider);

  // Auto-refresh when internet connectivity returns
  ref.listen(connectivityProvider, (previous, next) {
    if (previous?.isOnline == false && next.isOnline == true) {
      ref.invalidateSelf();
    }
  });

  final entries = await repo.get22List(
    search: search.trim().isEmpty ? null : search.trim(),
    includeUnpublished: perms.canManageAlephat ? true : null,
  );

  return entries;
});
