// lib/features/admin/presentation/providers/admin_system_report_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/admin/data/system_report_repository.dart';
import 'package:mobile/features/admin/domain/system_report_model.dart';
import 'package:mobile/features/settings/domain/public_system_report_model.dart';

final adminPlatformOverviewProvider =
    FutureProvider.autoDispose<PlatformOverviewModel>((ref) async {
  final repo = ref.watch(systemReportRepositoryProvider);
  return repo.getPlatformOverview();
});

final adminSystemReportProvider =
    StateNotifierProvider<AdminSystemReportNotifier, AsyncValue<SystemReportAdminModel>>(
  (ref) {
    final repo = ref.watch(systemReportRepositoryProvider);
    return AdminSystemReportNotifier(repo);
  },
);

class AdminSystemReportNotifier
    extends StateNotifier<AsyncValue<SystemReportAdminModel>> {
  final SystemReportRepository _repo;

  AdminSystemReportNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final report = await _repo.getActiveAdminReport();
      state = AsyncValue.data(report);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    try {
      final report = await _repo.getActiveAdminReport();
      state = AsyncValue.data(report);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateReport(Map<String, dynamic> data) async {
    final current = state.value;
    if (current == null) return;
    try {
      final updated = await _repo.updateReport(current.id, data);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateVisibility(Map<String, dynamic> visibilityData) async {
    final current = state.value;
    if (current == null) return;
    try {
      final updated = await _repo.updateVisibility(current.id, visibilityData);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> publishReport({String? displayMode}) async {
    final current = state.value;
    if (current == null) return;
    try {
      final updated = await _repo.publishReport(current.id, displayMode: displayMode);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> unpublishReport() async {
    final current = state.value;
    if (current == null) return;
    try {
      final updated = await _repo.unpublishReport(current.id);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<PublicSystemReportModel> preview() async {
    final current = state.value;
    if (current == null) throw Exception('No report loaded');
    return _repo.previewPublicReport(current.id);
  }

  Future<void> addCost(Map<String, dynamic> costData) async {
    final current = state.value;
    if (current == null) return;
    try {
      await _repo.addCostItem(current.id, costData);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateCost(String costId, Map<String, dynamic> costData) async {
    try {
      await _repo.updateCostItem(costId, costData);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteCost(String costId) async {
    try {
      await _repo.deleteCostItem(costId);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
