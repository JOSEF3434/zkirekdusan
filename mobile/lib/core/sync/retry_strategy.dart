// lib/core/sync/retry_strategy.dart

class RetryStrategy {
  static const int maxRetries = 5;

  static const List<Duration> backoffDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 60),
  ];

  /// Returns the next retry timestamp based on the current retry count.
  /// If retryCount exceeds maxRetries, returns null (cannot retry automatically).
  static DateTime? getNextRetryTime(int retryCount) {
    if (retryCount >= maxRetries) {
      return null;
    }
    final delayIndex = retryCount.clamp(0, backoffDelays.length - 1);
    final delay = backoffDelays[delayIndex];
    return DateTime.now().add(delay);
  }

  static bool shouldRetry(int retryCount) {
    return retryCount < maxRetries;
  }
}
