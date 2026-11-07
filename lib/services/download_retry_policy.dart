import 'dart:math';

/// Retry policy for archive downloads (#83).
///
/// Pure, unit-tested logic: the caller supplies the last error message and
/// the current attempt count; the policy answers whether another attempt
/// can help and how long to wait first. Kept free of I/O so the decision
/// table and the backoff curve are testable without a network.
class DownloadRetryPolicy {
  /// Error fragments that mean another attempt cannot possibly succeed:
  /// the file is missing, access is forbidden, or the device itself is
  /// out of space. Everything else (IA 5xx, throttling, timeouts, network
  /// flakiness, checksum mismatches) is bounded-retryable.
  static const List<String> fatalPatterns = [
    'HTTP 401',
    'HTTP 403',
    'HTTP 404',
    'HTTP 410',
    'Not found',
    'not found',
    'Permission denied',
    'Insufficient space',
  ];

  /// Base delay for the first retry; doubles on every further attempt.
  final Duration baseDelay;

  /// Upper bound for a single backoff window.
  final Duration maxDelay;

  /// Fraction of the base delay added as random jitter, so many devices
  /// hitting archive.org after an outage do not retry in lockstep.
  final double jitterFraction;

  final Random _random;

  DownloadRetryPolicy({
    this.baseDelay = const Duration(seconds: 10),
    this.maxDelay = const Duration(minutes: 5),
    this.jitterFraction = 0.25,
    Random? random,
  }) : _random = random ?? Random();

  /// Whether another attempt makes sense after [attempt] failed attempts
  /// ([attempt] counts already-failed tries; 0 = the first try just
  /// failed). Retries are additionally bounded by [maxAttempts].
  bool shouldRetry(
    String errorMessage, {
    required int attempt,
    required int maxAttempts,
  }) {
    if (attempt >= maxAttempts) {
      return false;
    }
    for (final pattern in fatalPatterns) {
      if (errorMessage.contains(pattern)) {
        return false;
      }
    }
    return true;
  }

  /// Exponential backoff with jitter: base * 2^attempt, capped at
  /// [maxDelay], plus up to [jitterFraction] of the base delay.
  Duration delayFor(int attempt) {
    final exponent = attempt.clamp(0, 10); // no overflow; cap applies anyway
    final exponentialMs = baseDelay.inMilliseconds * (1 << exponent);
    final cappedMs = exponentialMs > maxDelay.inMilliseconds
        ? maxDelay.inMilliseconds
        : exponentialMs;
    final jitterMs = (baseDelay.inMilliseconds * jitterFraction *
            _random.nextDouble())
        .round();
    return Duration(milliseconds: cappedMs + jitterMs);
  }
}
