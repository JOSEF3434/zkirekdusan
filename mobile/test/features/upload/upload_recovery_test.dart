import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/home/domain/video_model.dart';

void main() {
  group('Upload Parsing & Fallback Resilience Tests', () {
    test('VideoResponseDto _parseStatus does not fall back to failed for unknown or transitional states', () {
      final jsonReady = {
        'id': 'vid-1',
        'title': 'Test Video',
        'status': 'READY',
        'visibility': 'PUBLIC',
        'author': {
          'id': 'u1',
          'username': 'testuser',
          'fullName': 'Test User',
        },
        'createdAt': '2026-11-17T12:00:00Z',
        'updatedAt': '2026-11-17T12:00:00Z',
      };
      final videoReady = VideoResponseDto.fromJson(jsonReady);
      expect(videoReady.status, VideoStatus.ready);

      // Unknown or transitional status from backend should fallback to processing, NOT failed
      final jsonTransitional = {
        'id': 'vid-2',
        'title': 'Transitional Video',
        'status': 'TRANSCODING_AUDIO',
        'visibility': 'PUBLIC',
        'author': {
          'id': 'u1',
          'username': 'testuser',
          'fullName': 'Test User',
        },
        'createdAt': '2026-11-17T12:00:00Z',
        'updatedAt': '2026-11-17T12:00:00Z',
      };
      final videoTransitional = VideoResponseDto.fromJson(jsonTransitional);
      expect(videoTransitional.status, VideoStatus.processing);

      // Explicit failed status still maps to failed
      final jsonFailed = {
        'id': 'vid-3',
        'title': 'Failed Video',
        'status': 'FAILED',
        'visibility': 'PUBLIC',
        'author': {
          'id': 'u1',
          'username': 'testuser',
          'fullName': 'Test User',
        },
        'createdAt': '2026-11-17T12:00:00Z',
        'updatedAt': '2026-11-17T12:00:00Z',
      };
      final videoFailed = VideoResponseDto.fromJson(jsonFailed);
      expect(videoFailed.status, VideoStatus.failed);
    });

    test('All upload and live localization keys exist in all locales', () {
      final file = File('assets/lang/language_togle.json');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      final Map<String, dynamic> data = json.decode(content);

      final requiredKeys = [
        'upload.uploading',
        'upload.cancel_upload',
        'upload.processing',
        'upload.completed',
        'upload.optimizing_mobile',
        'upload.transcoding_desc',
        'calendar.notification.group_title',
        'calendar.notification.setting_title',
        'calendar.notification.setting_desc',
        'calendar.notification.permission_title',
      ];

      for (final lang in ['en', 'am', 'gez']) {
        final langMap = data[lang] as Map<String, dynamic>;
        for (final key in requiredKeys) {
          expect(
            langMap.containsKey(key),
            isTrue,
            reason: 'Missing key "$key" in locale "$lang"',
          );
          expect(
            (langMap[key] as String).isNotEmpty,
            isTrue,
            reason: 'Empty translation for key "$key" in locale "$lang"',
          );
        }
      }
    });
  });
}
