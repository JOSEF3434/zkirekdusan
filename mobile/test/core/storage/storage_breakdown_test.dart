// test/core/storage/storage_breakdown_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/cache_manager.dart';

void main() {
  group('StorageBreakdown', () {
    test('formats byte sizes accurately', () {
      const breakdown = StorageBreakdown(
        videoBytes: 104857600, // 100 MB
        chatMediaBytes: 5242880, // 5 MB
        imageCacheBytes: 20971520, // 20 MB
        tempBytes: 1048576, // 1 MB
      );

      expect(breakdown.formattedVideo, '100.0 MB');
      expect(breakdown.formattedChat, '5.0 MB');
      expect(breakdown.formattedCache, '20.0 MB');
      expect(breakdown.formattedTemp, '1.0 MB');
      expect(breakdown.formattedTotal, '126.0 MB');
    });

    test('formats GB correctly', () {
      const breakdown = StorageBreakdown(
        videoBytes: 2147483648, // 2 GB
        chatMediaBytes: 0,
        imageCacheBytes: 0,
        tempBytes: 0,
      );

      expect(breakdown.formattedVideo, '2.00 GB');
      expect(breakdown.formattedTotal, '2.00 GB');
    });

    test('formats KB correctly', () {
      const breakdown = StorageBreakdown(
        videoBytes: 0,
        chatMediaBytes: 204800, // 200 KB
        imageCacheBytes: 0,
        tempBytes: 0,
      );

      expect(breakdown.formattedChat, '200.0 KB');
    });
  });
}
