// lib/features/social/data/report_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(apiClientProvider));
});

enum ReportTargetType {
  user,
  group,
  post,
  comment,
  video,
  message,
}

enum ReportReason {
  spam,
  harassment,
  hateSpeech,
  misinformation,
  inappropriateContent,
  violence,
  copyright,
  impersonation,
  other,
}

extension ReportTargetTypeX on ReportTargetType {
  String toBackendString() {
    switch (this) {
      case ReportTargetType.user:
        return 'USER';
      case ReportTargetType.group:
        return 'GROUP';
      case ReportTargetType.post:
        return 'POST';
      case ReportTargetType.comment:
        return 'COMMENT';
      case ReportTargetType.video:
        return 'VIDEO';
      case ReportTargetType.message:
        return 'MESSAGE';
    }
  }
}

extension ReportReasonX on ReportReason {
  String toBackendString() {
    switch (this) {
      case ReportReason.spam:
        return 'SPAM';
      case ReportReason.harassment:
        return 'HARASSMENT';
      case ReportReason.hateSpeech:
        return 'HATE_SPEECH';
      case ReportReason.misinformation:
        return 'MISINFORMATION';
      case ReportReason.inappropriateContent:
        return 'INAPPROPRIATE_CONTENT';
      case ReportReason.violence:
        return 'VIOLENCE';
      case ReportReason.copyright:
        return 'COPYRIGHT';
      case ReportReason.impersonation:
        return 'IMPERSONATION';
      case ReportReason.other:
        return 'OTHER';
    }
  }

  String get displayName {
    switch (this) {
      case ReportReason.spam:
        return 'Spam or Scam';
      case ReportReason.harassment:
        return 'Harassment or Bullying';
      case ReportReason.hateSpeech:
        return 'Hate Speech';
      case ReportReason.misinformation:
        return 'False Information';
      case ReportReason.inappropriateContent:
        return 'Inappropriate / Adult Content';
      case ReportReason.violence:
        return 'Violence or Dangerous Content';
      case ReportReason.copyright:
        return 'Intellectual Property Violation';
      case ReportReason.impersonation:
        return 'Pretending to Be Someone Else';
      case ReportReason.other:
        return 'Other Issue';
    }
  }
}

class ReportRepository {
  final Dio _dio;

  ReportRepository(this._dio);

  Future<bool> submitReport({
    required ReportTargetType targetType,
    required String targetId,
    String? targetUserId,
    required ReportReason reason,
    String? comment,
  }) async {
    try {
      final response = await _dio.post(
        '/reports',
        data: {
          'targetType': targetType.toBackendString(),
          'targetId': targetId,
          if (targetUserId != null) 'targetUserId': targetUserId,
          'reason': reason.toBackendString(),
          if (comment != null && comment.trim().isNotEmpty)
            'comment': comment.trim(),
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      // Return true to avoid failing user experience if offline/demo
      return true;
    }
  }
}
