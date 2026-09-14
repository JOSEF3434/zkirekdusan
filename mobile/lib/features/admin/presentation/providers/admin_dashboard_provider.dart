// lib/features/admin/presentation/providers/admin_dashboard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';

final adminDashboardProvider =
    StateNotifierProvider<AdminDashboardNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  return AdminDashboardNotifier(ref.watch(adminRepositoryProvider));
});

class AdminDashboardNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final AdminRepository _repository;

  AdminDashboardNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMetrics();
  }

  Future<void> loadMetrics() async {
    state = const AsyncValue.loading();
    try {
      final metrics = await _repository.getDashboardMetrics();
      state = AsyncValue.data(metrics);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => loadMetrics();
}
