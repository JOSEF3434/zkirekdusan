// lib/features/books/presentation/providers/book_download_settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import '../../data/models/book_download_setting_model.dart';
export '../../data/models/book_download_setting_model.dart';
import '../../data/repositories/books_repository.dart';
import 'books_providers.dart';

const String kBookDownloadDestinationPrefKey =
    'book_download_destination_setting';

class BookDownloadSettingsState {
  final BookDownloadSettingModel setting;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const BookDownloadSettingsState({
    required this.setting,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  BookDownloadSettingsState copyWith({
    BookDownloadSettingModel? setting,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return BookDownloadSettingsState(
      setting: setting ?? this.setting,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BookDownloadSettingsNotifier
    extends StateNotifier<BookDownloadSettingsState> {
  final BooksRepository _repo;
  final SharedPreferences? _prefs;

  BookDownloadSettingsNotifier(this._repo, this._prefs)
      : super(
          BookDownloadSettingsState(
            setting: _initialSettingFromPrefs(_prefs),
          ),
        ) {
    load();
  }

  static BookDownloadSettingModel _initialSettingFromPrefs(
      SharedPreferences? prefs) {
    final cached = prefs?.getString(kBookDownloadDestinationPrefKey);
    final destination = cached != null
        ? BookDownloadDestination.fromString(cached)
        : BookDownloadDestination.inApp;
    return BookDownloadSettingModel(destination: destination);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final fetched = await _repo.getDownloadDestinationSetting();
      await _prefs?.setString(
        kBookDownloadDestinationPrefKey,
        fetched.destination.name,
      );
      if (mounted) {
        state = state.copyWith(
          setting: fetched,
          isLoading: false,
          clearError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  Future<bool> updateDestination(
    BookDownloadDestination destination, {
    String? description,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repo.updateDownloadDestinationSetting(
        destination.name,
        description: description,
      );
      await _prefs?.setString(
        kBookDownloadDestinationPrefKey,
        updated.destination.name,
      );
      if (mounted) {
        state = state.copyWith(
          setting: updated,
          isSaving: false,
          clearError: true,
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isSaving: false,
          error: e.toString().replaceAll('Exception: ', ''),
        );
      }
      return false;
    }
  }
}

final bookDownloadSettingsProvider = StateNotifierProvider<
    BookDownloadSettingsNotifier, BookDownloadSettingsState>((ref) {
  final repo = ref.watch(booksRepositoryProvider);
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {}
  return BookDownloadSettingsNotifier(repo, prefs);
});
