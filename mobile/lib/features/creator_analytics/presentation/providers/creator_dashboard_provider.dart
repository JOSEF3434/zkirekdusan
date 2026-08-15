// lib/features/creator_analytics/presentation/providers/creator_dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/creator_analytics/data/creator_analytics_repository.dart';
import 'package:mobile/features/creator_analytics/domain/creator_analytics_dto.dart';

// ─── Channel Analytics Provider ───────────────────────────────────────────

class ChannelAnalyticsArgs {
  final String groupId;
  final String channelId;
  const ChannelAnalyticsArgs({required this.groupId, required this.channelId});

  @override
  bool operator ==(Object other) =>
      other is ChannelAnalyticsArgs &&
      groupId == other.groupId &&
      channelId == other.channelId;
  @override
  int get hashCode => Object.hash(groupId, channelId);
}

final channelAnalyticsProvider = StateNotifierProvider.autoDispose
    .family<
      ChannelAnalyticsNotifier,
      ChannelAnalyticsState,
      ChannelAnalyticsArgs
    >((ref, args) {
      return ChannelAnalyticsNotifier(
        ref.watch(creatorAnalyticsRepositoryProvider),
        args,
      );
    });

class ChannelAnalyticsState {
  final bool isLoading;
  final String? error;
  final CreatorChannelAnalyticsDto? analytics;

  const ChannelAnalyticsState({
    this.isLoading = true,
    this.error,
    this.analytics,
  });

  ChannelAnalyticsState copyWith({
    bool? isLoading,
    String? error,
    CreatorChannelAnalyticsDto? analytics,
    bool clearError = false,
  }) => ChannelAnalyticsState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    analytics: analytics ?? this.analytics,
  );
}

class ChannelAnalyticsNotifier extends StateNotifier<ChannelAnalyticsState> {
  final CreatorAnalyticsRepository _repo;
  final ChannelAnalyticsArgs _args;

  ChannelAnalyticsNotifier(this._repo, this._args)
    : super(const ChannelAnalyticsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final analytics = await _repo.getChannelAnalytics(
        groupId: _args.groupId,
        channelId: _args.channelId,
      );
      state = state.copyWith(isLoading: false, analytics: analytics);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() => load();
}

// ─── Admin Metrics Provider ────────────────────────────────────────────────

final adminMetricsProvider =
    StateNotifierProvider.autoDispose<AdminMetricsNotifier, AdminMetricsState>((
      ref,
    ) {
      return AdminMetricsNotifier(
        ref.watch(creatorAnalyticsRepositoryProvider),
      );
    });

class AdminMetricsState {
  final bool isLoading;
  final String? error;
  final AdminDashboardMetricsDto? metrics;

  const AdminMetricsState({this.isLoading = true, this.error, this.metrics});

  AdminMetricsState copyWith({
    bool? isLoading,
    String? error,
    AdminDashboardMetricsDto? metrics,
    bool clearError = false,
  }) => AdminMetricsState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    metrics: metrics ?? this.metrics,
  );
}

class AdminMetricsNotifier extends StateNotifier<AdminMetricsState> {
  final CreatorAnalyticsRepository _repo;

  AdminMetricsNotifier(this._repo) : super(const AdminMetricsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final metrics = await _repo.getAdminMetrics();
      state = state.copyWith(isLoading: false, metrics: metrics);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() => load();
}
