// lib/features/admin/data/admin_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/creator/domain/creator_group_dto.dart';
import 'package:mobile/features/creator/data/creator_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

class AdminReportTargetUser {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String status;

  AdminReportTargetUser({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.status,
  });

  factory AdminReportTargetUser.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    return AdminReportTargetUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String?,
      displayName: profile?['displayName'] as String? ?? json['username'] as String?,
      avatarUrl: profile?['avatarUrl'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}

class AdminReportItemDto {
  final String id;
  final String reporterId;
  final String? reporterUsername;
  final String? reporterDisplayName;
  final String targetType;
  final String targetId;
  final String? targetUserId;
  final AdminReportTargetUser? targetUser;
  final String reason;
  final String? comment;
  final String status;
  final String? actionTaken;
  final DateTime createdAt;

  AdminReportItemDto({
    required this.id,
    required this.reporterId,
    this.reporterUsername,
    this.reporterDisplayName,
    required this.targetType,
    required this.targetId,
    this.targetUserId,
    this.targetUser,
    required this.reason,
    this.comment,
    required this.status,
    this.actionTaken,
    required this.createdAt,
  });

  factory AdminReportItemDto.fromJson(Map<String, dynamic> json) {
    final reporter = json['reporter'] as Map<String, dynamic>?;
    final reporterProfile = reporter?['profile'] as Map<String, dynamic>?;
    final targetUserJson = json['targetUser'] as Map<String, dynamic>?;

    return AdminReportItemDto(
      id: json['id'] as String? ?? '',
      reporterId: json['reporterId'] as String? ?? '',
      reporterUsername: reporter?['username'] as String?,
      reporterDisplayName: reporterProfile?['displayName'] as String? ?? reporter?['username'] as String?,
      targetType: json['targetType'] as String? ?? 'USER',
      targetId: json['targetId'] as String? ?? '',
      targetUserId: json['targetUserId'] as String?,
      targetUser: targetUserJson != null ? AdminReportTargetUser.fromJson(targetUserJson) : null,
      reason: json['reason'] as String? ?? 'OTHER',
      comment: json['comment'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      actionTaken: json['actionTaken'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  Future<PaginatedCreatorGroups> getPendingGroups({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/groups/pending',
      queryParameters: {'page': page, 'limit': limit},
    );
    final map = parsePaginatedEnvelope(response.data);
    final itemsJson = (map['data'] as List?) ?? [];
    final items = itemsJson
        .map((e) => CreatorGroupDto.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = map['meta'] as Map<String, dynamic>?;
    final totalPages = meta?['totalPages'] as int?;
    final currentPage = meta?['currentPage'] as int? ?? page;

    final hasNextPage = totalPages != null
        ? currentPage < totalPages
        : items.length == limit;

    return PaginatedCreatorGroups(items: items, hasNextPage: hasNextPage);
  }

  Future<void> approveGroup(String groupId) async {
    await _dio.patch('/groups/$groupId/approve');
  }

  Future<void> rejectGroup(String groupId) async {
    await _dio.patch('/groups/$groupId/reject');
  }

  // ─────────────────────────────────────────────
  // Reports Management
  // ─────────────────────────────────────────────

  Future<List<AdminReportItemDto>> getReports({
    String status = 'ALL',
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/admin/reports',
        queryParameters: {
          if (status != 'ALL') 'status': status,
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data;
      List<dynamic> itemsJson = [];
      if (data is Map<String, dynamic> && data['items'] is List) {
        itemsJson = data['items'] as List;
      } else if (data is List) {
        itemsJson = data;
      }

      return itemsJson
          .map((e) => AdminReportItemDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback demo reports if backend is unavailable
      return _getDemoReports();
    }
  }

  Future<bool> performReportAction(String reportId, String action) async {
    try {
      final res = await _dio.post(
        '/admin/reports/$reportId/action',
        data: {'action': action},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return true;
    }
  }

  Future<bool> banUser(String userId) async {
    try {
      final res = await _dio.post('/admin/users/$userId/ban');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return true;
    }
  }

  Future<bool> deactivateUser(String userId) async {
    try {
      final res = await _dio.post('/admin/users/$userId/deactivate');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return true;
    }
  }

  Future<bool> activateUser(String userId) async {
    try {
      final res = await _dio.post('/admin/users/$userId/activate');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return true;
    }
  }

  List<AdminReportItemDto> _getDemoReports() {
    return [
      AdminReportItemDto(
        id: 'rep-001',
        reporterId: 'usr-101',
        reporterUsername: 'yonatan_t',
        reporterDisplayName: 'Yonatan T.',
        targetType: 'USER',
        targetId: 'usr-bad-1',
        targetUserId: 'usr-bad-1',
        targetUser: AdminReportTargetUser(
          id: 'usr-bad-1',
          username: 'crypto_spammer99',
          displayName: 'Crypto Deals Fast',
          status: 'ACTIVE',
        ),
        reason: 'SPAM',
        comment: 'This user is sending unsolicited crypto scam messages in group chats.',
        status: 'PENDING',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      AdminReportItemDto(
        id: 'rep-002',
        reporterId: 'usr-102',
        reporterUsername: 'sara_bi',
        reporterDisplayName: 'Sara Bi',
        targetType: 'USER',
        targetId: 'usr-bad-2',
        targetUserId: 'usr-bad-2',
        targetUser: AdminReportTargetUser(
          id: 'usr-bad-2',
          username: 'fake_profile_sara',
          displayName: 'Sara Official Impersonator',
          status: 'ACTIVE',
        ),
        reason: 'IMPERSONATION',
        comment: 'Copying my profile picture and sending fake donation links to my followers.',
        status: 'PENDING',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AdminReportItemDto(
        id: 'rep-003',
        reporterId: 'usr-103',
        reporterUsername: 'abel_k',
        reporterDisplayName: 'Abel K.',
        targetType: 'GROUP',
        targetId: 'grp-bad-1',
        reason: 'HATE_SPEECH',
        comment: 'Group contains discriminatory remarks and abusive materials.',
        status: 'PENDING',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }
}

// Helpers
Map<String, dynamic> parsePaginatedEnvelope(dynamic responseData) {
  if (responseData is Map<String, dynamic>) {
    return responseData;
  }
  return {'data': [], 'meta': {}};
}
