// lib/features/settings/presentation/providers/user_system_report_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/admin/data/system_report_repository.dart';
import 'package:mobile/features/settings/domain/public_system_report_model.dart';

final userSystemReportProvider =
    StateNotifierProvider<UserSystemReportNotifier, AsyncValue<PublicSystemReportModel?>>(
  (ref) {
    final repo = ref.watch(systemReportRepositoryProvider);
    return UserSystemReportNotifier(repo);
  },
);

class UserSystemReportNotifier
    extends StateNotifier<AsyncValue<PublicSystemReportModel?>> {
  final SystemReportRepository _repo;

  UserSystemReportNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final report = await _repo.getActivePublicReport();
      state = AsyncValue.data(report);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    try {
      final report = await _repo.getActivePublicReport();
      state = AsyncValue.data(report);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> dismiss(String reportId, int revision) async {
    try {
      await _repo.dismissReport(reportId, revision);
      final current = state.value;
      if (current != null && current.id == reportId && current.revision == revision) {
        state = AsyncValue.data(
          PublicSystemReportModel(
            id: current.id,
            title: current.title,
            summary: current.summary,
            notes: current.notes,
            revision: current.revision,
            publishedAt: current.publishedAt,
            displayMode: current.displayMode,
            server: current.server,
            database: current.database,
            api: current.api,
            deployment: current.deployment,
            costs: current.costs,
            hasDismissed: true,
          ),
        );
      }
    } catch (_) {
      // Non-critical background call
    }
  }
}
