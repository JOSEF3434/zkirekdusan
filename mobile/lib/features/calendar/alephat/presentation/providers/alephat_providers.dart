// lib/features/calendar/alephat/presentation/providers/alephat_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// Tab 1: Base Letters provider
final alephatLettersProvider =
    FutureProvider.autoDispose<List<AlephatLetterModel>>((ref) async {
  final repo = ref.watch(alephatRepositoryProvider);
  final search = ref.watch(alephatLetterSearchProvider);
  final perms = ref.watch(adminPermissionsProvider);

  final letters = await repo.getLetters(
    search: search.trim().isEmpty ? null : search.trim(),
    includeUnpublished: perms.canManageAlephat ? true : null,
  );

  return letters;
});

// Currently selected base letter ID
final selectedBaseLetterIdProvider = StateProvider<String?>((ref) => null);

// Currently selected family member order index (1..8). If null, the base letter's default note is shown.
final selectedFamilyMemberOrderProvider = StateProvider<int?>((ref) => null);

// Tab 2: 22 Alephats list provider
final alephat22ListProvider =
    FutureProvider.autoDispose<List<Alephat22Model>>((ref) async {
  final repo = ref.watch(alephatRepositoryProvider);
  final search = ref.watch(alephat22SearchProvider);
  final perms = ref.watch(adminPermissionsProvider);

  final entries = await repo.get22List(
    search: search.trim().isEmpty ? null : search.trim(),
    includeUnpublished: perms.canManageAlephat ? true : null,
  );

  return entries;
});

// Selected 22 Alephat entry for detailed preview
final selected22EntryProvider = StateProvider<Alephat22Model?>((ref) => null);
