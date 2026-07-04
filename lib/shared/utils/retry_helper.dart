import 'dart:async';

class RetryConfig {
  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
    this.delayFactor = 2.0,
  });

  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double delayFactor;
}

class RetryException implements Exception {
  RetryException(this.message, this.lastError);

  final String message;
  final Object lastError;

  @override
  String toString() => 'RetryException: $message\nLast error: $lastError';
}

Future<T> retryWithBackoff<T>(
  Future<T> Function() operation, {
  RetryConfig config = const RetryConfig(),
  bool Function(Object error)? retryIf,
}) async {
  var attempt = 0;
  var delay = config.initialDelay;
  Object? lastError;

  while (attempt < config.maxAttempts) {
    attempt++;

    try {
      return await operation();
    } catch (e) {
      lastError = e;

      if (retryIf != null && !retryIf(e)) {
        rethrow;
      }

      if (attempt >= config.maxAttempts) {
        throw RetryException(
          'Operation gagal setelah ${config.maxAttempts} percobaan',
          e,
        );
      }

      await Future.delayed(delay);

      delay = Duration(
        milliseconds: (delay.inMilliseconds * config.delayFactor).round(),
      );

      if (delay > config.maxDelay) {
        delay = config.maxDelay;
      }
    }
  }

  throw RetryException(
    'Operation gagal setelah ${config.maxAttempts} percobaan',
    lastError ?? 'Unknown error',
  );
}
