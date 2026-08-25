import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/notifications/domain/notification_model.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(ref.read(apiClientProvider));
});

class NotificationsRepository {
  final Dio _dio;

  NotificationsRepository(this._dio);

  Future<List<NotificationResponseDto>> getAll() async {
    final response = await _dio.get('/notifications');
    final list = parseEnvelopeList(response.data);
    return list
        .map((e) => NotificationResponseDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<NotificationResponseDto>> getUnread() async {
    final response = await _dio.get('/notifications/unread');
    final list = parseEnvelopeList(response.data);
    return list
        .map((e) => NotificationResponseDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get('/notifications/unread/count');
    final data = parseEnvelope(response.data);
    return data['count'] as int;
  }

  Future<void> markAsRead(String id) async {
    final response = await _dio.patch('/notifications/$id/read');
    parseEnvelope(response.data);
  }

  Future<void> markAllAsRead() async {
    final response = await _dio.patch('/notifications/read-all');
    parseEnvelope(response.data);
  }

  Future<void> deleteNotification(String id) async {
    final response = await _dio.delete('/notifications/$id');
    parseEnvelope(response.data);
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    try {
      final body = <String, dynamic>{
        'token': token,
        'platform': platform,
      };
      if (deviceId != null) {
        body['deviceId'] = deviceId;
      }
      final response = await _dio.post('/device-tokens', data: body);
      parseEnvelope(response.data);
    } catch (_) {
      // Non-blocking
    }
  }

  Future<void> removeDeviceToken(String token) async {
    try {
      await _dio.delete('/device-tokens/$token');
    } catch (_) {
      // Non-blocking
    }
  }
}
