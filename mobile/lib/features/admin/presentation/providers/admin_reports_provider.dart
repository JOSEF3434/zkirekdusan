// lib/features/admin/presentation/providers/admin_reports_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';

final adminReportsFilterProvider = StateProvider<String>((ref) => 'PENDING');

final adminReportsProvider = StateNotifierProvider<AdminReportsNotifier, AsyncValue<List<AdminReportItemDto>>>((ref) {
  final filter = ref.watch(adminReportsFilterProvider);
  final repo = ref.watch(adminRepositoryProvider);
  return AdminReportsNotifier(repo, filter);
});

class AdminReportsNotifier extends StateNotifier<AsyncValue<List<AdminReportItemDto>>> {
  final AdminRepository _repository;
  final String _filter;

  AdminReportsNotifier(this._repository, this._filter) : super(const AsyncValue.loading()) {
    loadReports();
  }

  Future<void> loadReports() async {
    state = const AsyncValue.loading();
    try {
      final reports = await _repository.getReports(status: _filter);
      state = AsyncValue.data(reports);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> banTargetUser(AdminReportItemDto report) async {
    final targetUserId = report.targetUserId ?? (report.targetType == 'USER' ? report.targetId : null);
    if (targetUserId == null) return false;

    try {
      await _repository.performReportAction(report.id, 'BAN_USER');
      await _repository.banUser(targetUserId);

      // Optimistically update status
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((r) {
            if (r.id == report.id) {
              return AdminReportItemDto(
                id: r.id,
                reporterId: r.reporterId,
                reporterUsername: r.reporterUsername,
                reporterDisplayName: r.reporterDisplayName,
                targetType: r.targetType,
                targetId: r.targetId,
                targetUserId: r.targetUserId,
                targetUser: r.targetUser != null
                    ? AdminReportTargetUser(
                        id: r.targetUser!.id,
                        username: r.targetUser!.username,
                        displayName: r.targetUser!.displayName,
                        avatarUrl: r.targetUser!.avatarUrl,
                        status: 'BANNED',
                      )
                    : null,
                reason: r.reason,
                comment: r.comment,
                status: 'RESOLVED',
                actionTaken: 'BAN_USER',
                createdAt: r.createdAt,
              );
            }
            return r;
          }).toList(),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deactivateTargetUser(AdminReportItemDto report) async {
    final targetUserId = report.targetUserId ?? (report.targetType == 'USER' ? report.targetId : null);
    if (targetUserId == null) return false;

    try {
      await _repository.performReportAction(report.id, 'DEACTIVATE_USER');
      await _repository.deactivateUser(targetUserId);

      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((r) {
            if (r.id == report.id) {
              return AdminReportItemDto(
                id: r.id,
                reporterId: r.reporterId,
                reporterUsername: r.reporterUsername,
                reporterDisplayName: r.reporterDisplayName,
                targetType: r.targetType,
                targetId: r.targetId,
                targetUserId: r.targetUserId,
                targetUser: r.targetUser != null
                    ? AdminReportTargetUser(
                        id: r.targetUser!.id,
                        username: r.targetUser!.username,
                        displayName: r.targetUser!.displayName,
                        avatarUrl: r.targetUser!.avatarUrl,
                        status: 'INACTIVE',
                      )
                    : null,
                reason: r.reason,
                comment: r.comment,
                status: 'RESOLVED',
                actionTaken: 'DEACTIVATE_USER',
                createdAt: r.createdAt,
              );
            }
            return r;
          }).toList(),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> dismissReport(String reportId) async {
    try {
      await _repository.performReportAction(reportId, 'DISMISS');

      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((r) {
            if (r.id == reportId) {
              return AdminReportItemDto(
                id: r.id,
                reporterId: r.reporterId,
                reporterUsername: r.reporterUsername,
                reporterDisplayName: r.reporterDisplayName,
                targetType: r.targetType,
                targetId: r.targetId,
                targetUserId: r.targetUserId,
                targetUser: r.targetUser,
                reason: r.reason,
                comment: r.comment,
                status: 'DISMISSED',
                actionTaken: 'DISMISS',
                createdAt: r.createdAt,
              );
            }
            return r;
          }).toList(),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resolveReport(String reportId) async {
    try {
      await _repository.performReportAction(reportId, 'RESOLVE');

      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((r) {
            if (r.id == reportId) {
              return AdminReportItemDto(
                id: r.id,
                reporterId: r.reporterId,
                reporterUsername: r.reporterUsername,
                reporterDisplayName: r.reporterDisplayName,
                targetType: r.targetType,
                targetId: r.targetId,
                targetUserId: r.targetUserId,
                targetUser: r.targetUser,
                reason: r.reason,
                comment: r.comment,
                status: 'RESOLVED',
                actionTaken: 'RESOLVED',
                createdAt: r.createdAt,
              );
            }
            return r;
          }).toList(),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
