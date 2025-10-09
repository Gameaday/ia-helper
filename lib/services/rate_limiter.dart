import 'dart:async';
import 'package:flutter/foundation.dart';

/// Metrics for tracking rate limiter operations
class RateLimiterMetrics {
  int acquires = 0;
  int releases = 0;
  int delays = 0;
  int queueWaits = 0;

  @override
  String toString() {
    return 'RateLimiterMetrics('
        'acquires: $acquires, '
        'releases: $releases, '
        'delays: $delays, '
        'queueWaits: $queueWaits'
        ')';
  }
}

/// Rate limiter for Archive.org API compliance.
///
/// Implements semaphore-based concurrency control to ensure we don't
/// overwhelm the Archive.org servers. Maximum 3-5 concurrent requests
/// as recommended by Archive.org's best practices.
///
/// Usage:
/// ```dart
/// final limiter = RateLimiter(maxConcurrent: 3);
/// await limiter.acquire();
/// try {
///   // Make API request
///   final result = await http.get(url);
/// } finally {
///   limiter.release();
/// }
/// ```
class RateLimiter {
  final int maxConcurrent;
  final Duration? minDelay;

  int _active = 0;
  final List<Completer<void>> _queue = [];
  DateTime? _lastReleaseTime;

  // Metrics tracking
  final RateLimiterMetrics metrics = RateLimiterMetrics();

  /// Creates a rate limiter with the specified configuration.
  ///
  /// [maxConcurrent]: Maximum number of concurrent operations (default: 3)
  /// [minDelay]: Minimum delay between requests (default: 150ms for API compliance)
  RateLimiter({
    this.maxConcurrent = 3,
    this.minDelay = const Duration(milliseconds: 150),
  }) {
    assert(maxConcurrent > 0, 'maxConcurrent must be positive');
  }

  /// Current number of active (in-flight) requests.
  int get activeCount => _active;

  /// Number of requests waiting in queue.
  int get queueLength => _queue.length;

  /// Whether the rate limiter is at capacity.
  bool get isAtCapacity => _active >= maxConcurrent;

  /// Acquires a permit to make a request.
  ///
  /// Blocks until a permit is available. Always pair with [release] in a finally block.
  Future<void> acquire() async {
    metrics.acquires++;

    // Wait for minimum delay if configured
    if (minDelay != null && _lastReleaseTime != null) {
      final timeSinceLastRelease = DateTime.now().difference(_lastReleaseTime!);
      if (timeSinceLastRelease < minDelay!) {
        metrics.delays++;
        final remainingDelay = minDelay! - timeSinceLastRelease;

        if (kDebugMode) {
          debugPrint(
            '[RateLimiter] Delaying ${remainingDelay.inMilliseconds}ms for min delay',
          );
        }

        await Future.delayed(remainingDelay);
      }
    }

    // If at capacity, queue this request
    if (_active >= maxConcurrent) {
      metrics.queueWaits++;

      if (kDebugMode) {
        debugPrint(
          '[RateLimiter] At capacity ($maxConcurrent), queueing request (queue: ${_queue.length + 1})',
        );
      }

      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
    }

    _active++;

    if (kDebugMode) {
      debugPrint(
        '[RateLimiter] Acquired permit (active: $_active/$maxConcurrent, queued: ${_queue.length})',
      );
    }
  }

  /// Releases a permit, allowing the next queued request to proceed.
  ///
  /// Must be called after [acquire], typically in a finally block.
  void release() {
    assert(_active > 0, 'Cannot release when no active permits');

    metrics.releases++;
    _active--;
    _lastReleaseTime = DateTime.now();

    if (kDebugMode) {
      debugPrint(
        '[RateLimiter] Released permit (active: $_active/$maxConcurrent, queued: ${_queue.length})',
      );
    }

    // Process next queued request if any
    if (_queue.isNotEmpty) {
      final completer = _queue.removeAt(0);
      completer.complete();

      if (kDebugMode) {
        debugPrint('[RateLimiter] Processed queued request (remaining: ${_queue.length})');
      }
    }
  }

  /// Executes an operation with automatic acquire/release.
  ///
  /// Convenience method that handles permit acquisition and release automatically.
  /// Recommended for most use cases.
  ///
  /// Example:
  /// ```dart
  /// final result = await limiter.execute(() async {
  ///   return await http.get(url);
  /// });
  /// ```
  Future<T> execute<T>(Future<T> Function() operation) async {
    await acquire();
    try {
      return await operation();
    } finally {
      release();
    }
  }

  /// Resets the rate limiter state.
  ///
  /// WARNING: Only use for testing or emergency situations.
  /// Cancels all queued requests.
  void reset() {
    _active = 0;
    _lastReleaseTime = null;

    // Cancel all queued requests
    for (final completer in _queue) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('Rate limiter was reset while waiting'),
        );
      }
    }
    _queue.clear();
  }

  /// Gets statistics about the rate limiter.
  Map<String, dynamic> getStats() {
    return {
      'active': _active,
      'queued': _queue.length,
      'maxConcurrent': maxConcurrent,
      'isAtCapacity': isAtCapacity,
      'minDelayMs': minDelay?.inMilliseconds,
      'lastReleaseTime': _lastReleaseTime?.toIso8601String(),
    };
  }

  /// Get current metrics
  RateLimiterMetrics getMetrics() => metrics;

  /// Reset metrics to zero
  void resetMetrics() {
    metrics.acquires = 0;
    metrics.releases = 0;
    metrics.delays = 0;
    metrics.queueWaits = 0;
    if (kDebugMode) {
      debugPrint('[RateLimiter] Metrics reset');
    }
  }

  /// Get formatted statistics for monitoring
  Map<String, dynamic> getFormattedStatistics() {
    final totalOperations = metrics.acquires;
    final delayRate = totalOperations > 0
        ? (metrics.delays / totalOperations * 100).toStringAsFixed(1)
        : '0.0';
    
    final queueRate = totalOperations > 0
        ? (metrics.queueWaits / totalOperations * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'totalAcquires': metrics.acquires,
      'totalReleases': metrics.releases,
      'delaysApplied': metrics.delays,
      'delayRate': '$delayRate%',
      'queueWaits': metrics.queueWaits,
      'queueRate': '$queueRate%',
      'currentActive': _active,
      'currentQueued': _queue.length,
      'maxConcurrent': maxConcurrent,
      'isAtCapacity': isAtCapacity,
      'minDelayMs': minDelay?.inMilliseconds ?? 0,
    };
  }
}

/// Staggered start helper for batch operations.
///
/// Use this when starting multiple downloads/operations to avoid
/// a thundering herd problem. Staggers start times by the specified delay.
///
/// Example:
/// ```dart
/// final stagger = StaggeredStarter(delayBetweenStarts: Duration(milliseconds: 500));
/// for (final url in urls) {
///   await stagger.waitForNextStart();
///   downloadFile(url); // Start download
/// }
/// ```
class StaggeredStarter {
  final Duration delayBetweenStarts;
  DateTime? _lastStartTime;

  /// Creates a staggered starter with the specified delay.
  ///
  /// [delayBetweenStarts]: Time to wait between each start (default: 500ms)
  StaggeredStarter({
    this.delayBetweenStarts = const Duration(milliseconds: 500),
  });

  /// Waits for the appropriate time to start the next operation.
  Future<void> waitForNextStart() async {
    if (_lastStartTime != null) {
      final timeSinceLastStart = DateTime.now().difference(_lastStartTime!);
      if (timeSinceLastStart < delayBetweenStarts) {
        final remainingDelay = delayBetweenStarts - timeSinceLastStart;
        await Future.delayed(remainingDelay);
      }
    }
    _lastStartTime = DateTime.now();
  }

  /// Resets the stagger timer.
  void reset() {
    _lastStartTime = null;
  }
}

/// Global rate limiter instance for Archive.org API.
///
/// Use this singleton for all Archive.org API requests to ensure
/// proper rate limiting across the entire app.
final archiveRateLimiter = RateLimiter(
  maxConcurrent: 3,
  minDelay: const Duration(milliseconds: 150),
);

/// Global staggered starter for batch operations.
///
/// Use this when starting multiple downloads to avoid overwhelming
/// the Archive.org servers.
final archiveStaggeredStarter = StaggeredStarter(
  delayBetweenStarts: const Duration(milliseconds: 500),
);
