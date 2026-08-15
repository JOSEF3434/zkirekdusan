// lib/features/creator_analytics/presentation/providers/admin_moderation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/creator_analytics/data/creator_analytics_repository.dart';
import 'package:mobile/features/creator_analytics/domain/creator_analytics_dto.dart';

final adminModerationProvider =
    StateNotifierProvider.autoDispose<
      AdminModerationNotifier,
      AdminModerationState
    >((ref) {
      return AdminModerationNotifier(
        ref.watch(creatorAnalyticsRepositoryProvider),
      );
    });

class AdminModerationState {
  final bool isLoading;
  final bool isPaginating;
  final String? error;
  final List<AdminReportDto> reports;
  final int currentPage;
  final bool hasMore;

  const AdminModerationState({
    this.isLoading = true,
    this.isPaginating = false,
    this.error,
    this.reports = const [],
    this.currentPage = 1,
    this.hasMore = false,
  });

  AdminModerationState copyWith({
    bool? isLoading,
    bool? isPaginating,
    String? error,
    List<AdminReportDto>? reports,
    int? currentPage,
    bool? hasMore,
    bool clearError = false,
  }) => AdminModerationState(
    isLoading: isLoading ?? this.isLoading,
    isPaginating: isPaginating ?? this.isPaginating,
    error: clearError ? null : (error ?? this.error),
    reports: reports ?? this.reports,
    currentPage: currentPage ?? this.currentPage,
    hasMore: hasMore ?? this.hasMore,
  );
}

class AdminModerationNotifier extends StateNotifier<AdminModerationState> {
  final CreatorAnalyticsRepository _repo;

  AdminModerationNotifier(this._repo) : super(const AdminModerationState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.getAdminReports(page: 1);
      state = state.copyWith(
        isLoading: false,
        reports: result.items,
        currentPage: result.currentPage,
        hasMore: result.hasNextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() => load();

  Future<void> loadMore() async {
    if (state.isLoading || state.isPaginating || !state.hasMore) return;
    state = state.copyWith(isPaginating: true, clearError: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _repo.getAdminReports(page: nextPage);
      state = state.copyWith(
        isPaginating: false,
        reports: [...state.reports, ...result.items],
        currentPage: result.currentPage,
        hasMore: result.hasNextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isPaginating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> resolveReport(String reportId) async {
    final prev = List<AdminReportDto>.from(state.reports);
    // Optimistically remove from list (assuming resolved means it's done)
    state = state.copyWith(
      reports: state.reports.where((r) => r.id != reportId).toList(),
    );
    try {
      await _repo.resolveReport(reportId: reportId);
    } catch (e) {
      state = state.copyWith(
        reports: prev,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }
}
