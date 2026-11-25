// lib/features/admin/data/system_report_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/admin/domain/system_report_model.dart';
import 'package:mobile/features/settings/domain/public_system_report_model.dart';

final systemReportRepositoryProvider = Provider<SystemReportRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return SystemReportRepository(dio);
});

class SystemReportRepository {
  final Dio _dio;

  SystemReportRepository(this._dio);

  // ─────────────────────────────────────────────
  // Admin Endpoints
  // ─────────────────────────────────────────────

  /// Retrieves the active system report with all admin fields and visibility states
  Future<SystemReportAdminModel> getActiveAdminReport() async {
    final response = await _dio.get('/admin/system-report/active');
    final data = parseEnvelope(response.data);
    return SystemReportAdminModel.fromJson(data);
  }

  /// Retrieves live platform-wide overview statistics
  Future<PlatformOverviewModel> getPlatformOverview() async {
    final response = await _dio.get('/admin/system-report/overview');
    final data = parseEnvelope(response.data);
    return PlatformOverviewModel.fromJson(data);
  }

  /// Updates report general information and field values
  Future<SystemReportAdminModel> updateReport(
    String id,
    Map<String, dynamic> updateData,
  ) async {
    final response = await _dio.put(
      '/admin/system-report/$id',
      data: updateData,
    );
    final data = parseEnvelope(response.data);
    return SystemReportAdminModel.fromJson(data);
  }

  /// Updates visibility switches (global and per-field/category)
  Future<SystemReportAdminModel> updateVisibility(
    String id,
    Map<String, dynamic> visibilityData,
  ) async {
    final response = await _dio.patch(
      '/admin/system-report/$id/visibility',
      data: visibilityData,
    );
    final data = parseEnvelope(response.data);
    return SystemReportAdminModel.fromJson(data);
  }

  /// Publishes the report with revision increment
  Future<SystemReportAdminModel> publishReport(
    String id, {
    String? displayMode,
  }) async {
    final response = await _dio.post(
      '/admin/system-report/$id/publish',
      data: {
        'displayMode': ?displayMode,
      },
    );
    final data = parseEnvelope(response.data);
    return SystemReportAdminModel.fromJson(data);
  }

  /// Unpublishes the report
  Future<SystemReportAdminModel> unpublishReport(String id) async {
    final response = await _dio.post('/admin/system-report/$id/unpublish');
    final data = parseEnvelope(response.data);
    return SystemReportAdminModel.fromJson(data);
  }

  /// Previews the exact user-facing filtered output before publishing
  Future<PublicSystemReportModel> previewPublicReport(String id) async {
    final response = await _dio.get('/admin/system-report/$id/preview');
    final data = parseEnvelope(response.data);
    return PublicSystemReportModel.fromJson(data);
  }

  /// Adds a new service cost record
  Future<SystemServiceCostModel> addCostItem(
    String reportId,
    Map<String, dynamic> costData,
  ) async {
    final response = await _dio.post(
      '/admin/system-report/$reportId/costs',
      data: costData,
    );
    final data = parseEnvelope(response.data);
    return SystemServiceCostModel.fromJson(data);
  }

  /// Updates an existing service cost record
  Future<SystemServiceCostModel> updateCostItem(
    String costId,
    Map<String, dynamic> costData,
  ) async {
    final response = await _dio.put(
      '/admin/system-report/costs/$costId',
      data: costData,
    );
    final data = parseEnvelope(response.data);
    return SystemServiceCostModel.fromJson(data);
  }

  /// Deletes a service cost record
  Future<void> deleteCostItem(String costId) async {
    await _dio.delete('/admin/system-report/costs/$costId');
  }

  // ─────────────────────────────────────────────
  // Public User Endpoints
  // ─────────────────────────────────────────────

  /// Retrieves the active public report for ordinary users
  Future<PublicSystemReportModel?> getActivePublicReport() async {
    try {
      final response = await _dio.get('/system-report/active');
      final data = parseEnvelope(response.data);
      final isAvailable = data['available'] as bool? ?? false;
      if (!isAvailable || data['report'] == null) {
        return null;
      }
      return PublicSystemReportModel.fromJson(data['report'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Records user dismissal for the given report revision
  Future<void> dismissReport(String reportId, int revision) async {
    try {
      await _dio.post(
        '/system-report/$reportId/dismiss',
        data: {'revision': revision},
      );
    } catch (_) {
      // Non-critical background call
    }
  }
}
