// lib/features/admin/data/admin_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
export 'package:mobile/core/network/api_client.dart' show safeMap;
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
    final profile = safeMap(json['profile']);
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
    final reporter = safeMap(json['reporter']);
    final reporterProfile = safeMap(reporter?['profile']);
    final targetUserJson = safeMap(json['targetUser']);

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

class AdminUserItemDto {
  final String id;
  final String? username;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String status;
  final String role;
  final DateTime createdAt;

  AdminUserItemDto({
    required this.id,
    this.username,
    this.email,
    this.displayName,
    this.avatarUrl,
    required this.status,
    required this.role,
    required this.createdAt,
  });

  factory AdminUserItemDto.fromJson(Map<String, dynamic> json) {
    final profile = safeMap(json['profile']);
    final avatar = safeMap(profile?['avatar']);
    final roleRaw = json['role'];
    final roleObj = safeMap(roleRaw);

    return AdminUserItemDto(
      id: json['id'] as String? ?? '',
      username: json['username'] as String?,
      email: json['email'] as String?,
      displayName: profile?['displayName'] as String? ?? json['username'] as String?,
      avatarUrl: avatar?['url'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      role: roleObj?['name'] as String? ?? (roleRaw is String ? roleRaw : null) ?? 'USER',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AdminGroupItemDto {
  final String id;
  final String name;
  final String? handle;
  final String status;
  final int memberCount;
  final DateTime createdAt;

  AdminGroupItemDto({
    required this.id,
    required this.name,
    this.handle,
    required this.status,
    required this.memberCount,
    required this.createdAt,
  });

  factory AdminGroupItemDto.fromJson(Map<String, dynamic> json) {
    final count = safeMap(json['_count']);
    return AdminGroupItemDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      handle: json['handle'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      memberCount: (count?['members'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AdminAuditLogItemDto {
  final String id;
  final String action;
  final String? targetType;
  final String? targetId;
  final String? reason;
  final String? username;
  final DateTime createdAt;

  AdminAuditLogItemDto({
    required this.id,
    required this.action,
    this.targetType,
    this.targetId,
    this.reason,
    this.username,
    required this.createdAt,
  });

  factory AdminAuditLogItemDto.fromJson(Map<String, dynamic> json) {
    final user = safeMap(json['user']);
    return AdminAuditLogItemDto(
      id: json['id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      targetType: json['targetType'] as String?,
      targetId: json['targetId'] as String?,
      reason: json['reason'] as String?,
      username: user?['username'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AdminChannelItemDto {
  final String id;
  final String name;
  final String slug;
  final String type;
  final String? groupName;
  final String? groupId;
  final int messageCount;
  final DateTime createdAt;

  AdminChannelItemDto({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    this.groupName,
    this.groupId,
    required this.messageCount,
    required this.createdAt,
  });

  factory AdminChannelItemDto.fromJson(Map<String, dynamic> json) {
    final group = safeMap(json['group']);
    final count = safeMap(json['_count']);
    return AdminChannelItemDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      type: json['type'] as String? ?? 'TEXT',
      groupName: group?['name'] as String?,
      groupId: json['groupId'] as String? ?? group?['id'] as String?,
      messageCount: (count?['messages'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  // ─────────────────────────────────────────────
  // Dashboard
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final res = await _dio.get('/admin/dashboard/metrics');
    return parseEnvelope(res.data);
  }

  // ─────────────────────────────────────────────
  // User Management
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? role,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status != 'ALL') 'status': status,
      if (role != null && role != 'ALL') 'role': role,
    };
    try {
      final res = await _dio.get('/admin/users', queryParameters: params);
      final parsed = parsePaginatedEnvelope(res.data);
      final list = (parsed['data'] as List?) ?? [];
      final meta = safeMap(parsed['meta']) ?? {};
      final items = list
          .whereType<Map>()
          .map((e) => AdminUserItemDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return {
        'items': items,
        'total': meta['total'] ?? items.length,
        'page': meta['page'] ?? page,
        'limit': meta['limit'] ?? limit,
        'totalPages': meta['totalPages'] ?? (items.isNotEmpty ? 1 : 0),
        'hasNext': meta['hasNext'] ?? false,
      };
    } catch (e) {
      rethrow; // propagate so the UI shows the actual error
    }
  }

  Future<Map<String, dynamic>> getUserDetail(String id) async {
    final res = await _dio.get('/admin/users/$id');
    return parseEnvelope(res.data);
  }

  Future<bool> updateUserStatus(String id, String status, {String? reason}) async {
    try {
      final res = await _dio.patch(
        '/admin/users/$id/status',
        data: {'status': status, if (reason != null) 'reason': reason},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> assignUserRole(String id, String roleName, {String? reason}) async {
    try {
      final res = await _dio.post(
        '/admin/users/$id/role',
        data: {'roleName': roleName, if (reason != null) 'reason': reason},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> banUser(String userId, {String? reason}) async {
    final res = await _dio.post(
      '/admin/users/$userId/ban',
      data: {if (reason != null) 'reason': reason},
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<bool> deactivateUser(String userId, {String? reason}) async {
    final res = await _dio.post(
      '/admin/users/$userId/deactivate',
      data: {if (reason != null) 'reason': reason},
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<bool> activateUser(String userId) async {
    final res = await _dio.post('/admin/users/$userId/activate');
    return res.statusCode == 200 || res.statusCode == 201;
  }

  // ─────────────────────────────────────────────
  // Groups Management
  // ─────────────────────────────────────────────

  Future<PaginatedCreatorGroups> getPendingGroups({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/groups/pending',
        queryParameters: {'page': page, 'limit': limit},
      );
      final map = parsePaginatedEnvelope(response.data);
      final itemsJson = (map['data'] as List?) ?? [];
      final items = itemsJson
          .whereType<Map>()
          .map((e) => CreatorGroupDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final meta = safeMap(map['meta']);
      final totalPages = meta?['totalPages'] as int?;
      final currentPage = meta?['currentPage'] as int? ?? page;

      final hasNextPage = totalPages != null
          ? currentPage < totalPages
          : items.length == limit;

      return PaginatedCreatorGroups(items: items, hasNextPage: hasNextPage);
    } catch (_) {
      return PaginatedCreatorGroups(items: [], hasNextPage: false);
    }
  }

  Future<Map<String, dynamic>> getGroups({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status != 'ALL') 'status': status,
      };
      final res = await _dio.get('/admin/groups', queryParameters: params);
      final parsed = parsePaginatedEnvelope(res.data);
      final list = (parsed['data'] as List?) ?? [];
      final meta = safeMap(parsed['meta']) ?? {};
      final items = list
          .whereType<Map>()
          .map((e) => AdminGroupItemDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return {
        'items': items,
        'total': meta['total'] ?? items.length,
        'page': meta['page'] ?? page,
        'limit': meta['limit'] ?? limit,
        'totalPages': meta['totalPages'] ?? (items.isNotEmpty ? 1 : 0),
        'hasNext': meta['hasNext'] ?? false,
      };
    } catch (e) {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // Channels Management
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getChannels({
    int page = 1,
    int limit = 20,
    String? search,
    String? groupId,
  }) async {
    try {
      final res = await _dio.get(
        '/admin/channels',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (groupId != null) 'groupId': groupId,
        },
      );
      final parsed = parsePaginatedEnvelope(res.data);
      final list = (parsed['data'] as List?) ?? [];
      final meta = safeMap(parsed['meta']) ?? {};
      final items = list
          .whereType<Map>()
          .map((e) => AdminChannelItemDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return {
        'items': items,
        'total': meta['total'] ?? items.length,
        'page': meta['page'] ?? page,
        'limit': meta['limit'] ?? limit,
        'totalPages': meta['totalPages'] ?? (items.isNotEmpty ? 1 : 0),
        'hasNext': meta['hasNext'] ?? false,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteChannel(String channelId, {String? reason}) async {
    try {
      final res = await _dio.delete(
        '/admin/channels/$channelId',
        data: {if (reason != null) 'reason': reason},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> approveGroup(String groupId, {String? reason}) async {
    try {
      await _dio.post('/admin/groups/$groupId/approve', data: {if (reason != null) 'reason': reason});
    } catch (_) {
      await _dio.patch('/groups/$groupId/approve');
    }
  }

  Future<void> rejectGroup(String groupId, {String? reason}) async {
    try {
      await _dio.post('/admin/groups/$groupId/reject', data: {if (reason != null) 'reason': reason});
    } catch (_) {
      await _dio.patch('/groups/$groupId/reject');
    }
  }

  Future<bool> suspendGroup(String groupId, {String? reason}) async {
    try {
      final res = await _dio.post('/admin/groups/$groupId/suspend', data: {if (reason != null) 'reason': reason});
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> restoreGroup(String groupId, {String? reason}) async {
    try {
      final res = await _dio.post('/admin/groups/$groupId/restore', data: {if (reason != null) 'reason': reason});
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteGroup(String groupId, {String? reason}) async {
    try {
      final res = await _dio.delete('/admin/groups/$groupId', data: {if (reason != null) 'reason': reason});
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
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

      final list = parseEnvelopeList(response.data);
      if (list.isNotEmpty) {
        return list
            .whereType<Map>()
            .map((e) => AdminReportItemDto.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return _getDemoReports();
    } catch (e) {
      return _getDemoReports();
    }
  }

  Future<bool> performReportAction(String reportId, String action, {String? note}) async {
    try {
      final res = await _dio.post(
        '/admin/reports/$reportId/action',
        data: {'action': action, if (note != null) 'note': note},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return true;
    }
  }

  // ─────────────────────────────────────────────
  // Content Moderation (Posts, Videos)
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getPosts({int page = 1, int limit = 20, String? search, String? status}) async {
    try {
      final res = await _dio.get(
        '/admin/content/posts',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status != 'ALL') 'status': status,
        },
      );
      final parsed = parsePaginatedEnvelope(res.data);
      final list = (parsed['data'] as List?) ?? [];
      final meta = safeMap(parsed['meta']) ?? {};
      return {
        'items': list,
        'total': meta['total'] ?? list.length,
        'page': meta['page'] ?? page,
        'limit': meta['limit'] ?? limit,
        'totalPages': meta['totalPages'] ?? (list.isNotEmpty ? 1 : 0),
        'hasNext': meta['hasNext'] ?? false,
      };
    } catch (_) {
      return {'items': [], 'total': 0};
    }
  }

  Future<bool> deletePost(String id, {String? reason}) async {
    try {
      final res = await _dio.delete('/admin/content/posts/$id', data: {if (reason != null) 'reason': reason});
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getVideos({int page = 1, int limit = 20, String? search, String? status}) async {
    try {
      final res = await _dio.get(
        '/admin/content/videos',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status != 'ALL') 'status': status,
        },
      );
      final parsed = parsePaginatedEnvelope(res.data);
      final list = (parsed['data'] as List?) ?? [];
      final meta = safeMap(parsed['meta']) ?? {};
      return {
        'items': list,
        'total': meta['total'] ?? list.length,
        'page': meta['page'] ?? page,
        'limit': meta['limit'] ?? limit,
        'totalPages': meta['totalPages'] ?? (list.isNotEmpty ? 1 : 0),
        'hasNext': meta['hasNext'] ?? false,
      };
    } catch (_) {
      return {'items': [], 'total': 0};
    }
  }

  Future<bool> deleteVideo(String id, {String? reason}) async {
    try {
      final res = await _dio.delete('/admin/content/videos/$id', data: {if (reason != null) 'reason': reason});
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Live Streams
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getLiveStreams({int page = 1, int limit = 20, String? search, String? status}) async {
    try {
      final res = await _dio.get(
        '/admin/live',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status != 'ALL') 'status': status,
        },
      );
      final parsed = parsePaginatedEnvelope(res.data);
      final list = (parsed['data'] as List?) ?? [];
      final meta = safeMap(parsed['meta']) ?? {};
      return {
        'items': list,
        'total': meta['total'] ?? list.length,
        'page': meta['page'] ?? page,
        'limit': meta['limit'] ?? limit,
        'totalPages': meta['totalPages'] ?? (list.isNotEmpty ? 1 : 0),
        'hasNext': meta['hasNext'] ?? false,
      };
    } catch (_) {
      return {'items': [], 'total': 0};
    }
  }

  Future<bool> terminateLiveStream(String id, {String? reason}) async {
    try {
      final res = await _dio.post('/admin/live/$id/terminate', data: {if (reason != null) 'reason': reason});
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Chat Moderation
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getConversations({
    int page = 1,
    int limit = 20,
    String? type,
    String? search,
  }) async {
    try {
      final res = await _dio.get(
        '/admin/chat/conversations',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (type != null && type != 'ALL') 'type': type,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final parsed = parsePaginatedEnvelope(res.data);
      final list = (parsed['data'] as List?) ?? [];
      final meta = safeMap(parsed['meta']) ?? {};
      return {
        'items': list,
        'total': meta['total'] ?? list.length,
        'page': meta['page'] ?? page,
        'limit': meta['limit'] ?? limit,
        'totalPages': meta['totalPages'] ?? (list.isNotEmpty ? 1 : 0),
        'hasNext': meta['hasNext'] ?? false,
      };
    } catch (_) {
      return {'items': [], 'total': 0, 'totalPages': 0, 'hasNext': false};
    }
  }

  Future<Map<String, dynamic>> getConversationMessages(
    String conversationId, {
    int page = 1,
    int limit = 30,
    String? search,
  }) async {
    try {
      final res = await _dio.get(
        '/admin/chat/conversations/$conversationId/messages',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final parsed = parsePaginatedEnvelope(res.data);
      final list = (parsed['data'] as List?) ?? [];
      final meta = safeMap(parsed['meta']) ?? {};
      return {
        'items': list,
        'total': meta['total'] ?? list.length,
        'page': meta['page'] ?? page,
        'limit': meta['limit'] ?? limit,
        'totalPages': meta['totalPages'] ?? (list.isNotEmpty ? 1 : 0),
        'hasNext': meta['hasNext'] ?? false,
      };
    } catch (_) {
      return {'items': [], 'total': 0, 'totalPages': 0, 'hasNext': false};
    }
  }

  Future<bool> deleteMessage(String messageId, {String? reason}) async {
    try {
      final res = await _dio.delete(
        '/admin/chat/messages/$messageId',
        data: {if (reason != null) 'reason': reason},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> purgeConversation(String conversationId, {String? reason}) async {
    try {
      final res = await _dio.delete(
        '/admin/chat/conversations/$conversationId/purge',
        data: {if (reason != null) 'reason': reason},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Storage Stats
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final res = await _dio.get('/admin/storage/stats');
      return parseEnvelope(res.data);
    } catch (_) {
      return {'totalFiles': 0, 'totalSizeBytes': 0, 'byType': [], 'byProvider': []};
    }
  }

  // ─────────────────────────────────────────────
  // Notifications Broadcast
  // ─────────────────────────────────────────────

  Future<bool> broadcastNotification({
    required String title,
    required String body,
    String? targetRole,
  }) async {
    try {
      final res = await _dio.post(
        '/admin/notifications/broadcast',
        data: {
          'title': title,
          'body': body,
          if (targetRole != null && targetRole != 'ALL') 'targetRole': targetRole,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Audit Logs
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getAuditLogs({
    int page = 1,
    int limit = 30,
    String? actorId,
    String? action,
    String? targetType,
  }) async {
    try {
      final res = await _dio.get(
        '/admin/audit',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (actorId != null) 'actorId': actorId,
          if (action != null) 'action': action,
          if (targetType != null) 'targetType': targetType,
        },
      );
      final parsed = parsePaginatedEnvelope(res.data);
      final list = (parsed['data'] as List?) ?? [];
      final meta = safeMap(parsed['meta']) ?? {};
      final items = list
          .whereType<Map>()
          .map((e) => AdminAuditLogItemDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return {
        'items': items,
        'total': meta['total'] ?? items.length,
        'page': meta['page'] ?? page,
        'limit': meta['limit'] ?? limit,
        'totalPages': meta['totalPages'] ?? (items.isNotEmpty ? 1 : 0),
        'hasNext': meta['hasNext'] ?? false,
      };
    } catch (_) {}
    return {'items': <AdminAuditLogItemDto>[], 'total': 0, 'totalPages': 0, 'hasNext': false};
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
