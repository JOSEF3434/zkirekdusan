// test/core/sync/retry_strategy_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/sync/retry_strategy.dart';

void main() {
  group('RetryStrategy', () {
    test('backoff delays definition is sequential', () {
      expect(RetryStrategy.backoffDelays.length, 5);
      expect(RetryStrategy.backoffDelays[0], const Duration(seconds: 2));
      expect(RetryStrategy.backoffDelays[1], const Duration(seconds: 5));
      expect(RetryStrategy.backoffDelays[2], const Duration(seconds: 15));
      expect(RetryStrategy.backoffDelays[3], const Duration(seconds: 30));
      expect(RetryStrategy.backoffDelays[4], const Duration(seconds: 60));
    });

    test('getNextRetryTime adds appropriate delay', () {
      final now = DateTime.now();
      final nextTime = RetryStrategy.getNextRetryTime(0);
      expect(nextTime, isNotNull);
      // Diff should be ~2s
      expect(nextTime!.difference(now).inSeconds, closeTo(2, 1));
    });

    test('getNextRetryTime returns null when max retries exceeded', () {
      expect(RetryStrategy.getNextRetryTime(5), isNull);
      expect(RetryStrategy.getNextRetryTime(10), isNull);
    });

    test('shouldRetry enforces max retries', () {
      expect(RetryStrategy.shouldRetry(0), true);
      expect(RetryStrategy.shouldRetry(4), true);
      expect(RetryStrategy.shouldRetry(5), false);
      expect(RetryStrategy.shouldRetry(6), false);
    });
  });
}
