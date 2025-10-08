import 'dart:async';

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
    // Wait for minimum delay if configured
    if (minDelay != null && _lastReleaseTime != null) {
      final timeSinceLastRelease = DateTime.now().difference(_lastReleaseTime!);
      if (timeSinceLastRelease < minDelay!) {
        final remainingDelay = minDelay! - timeSinceLastRelease;
        await Future.delayed(remainingDelay);
      }
    }

    // If at capacity, queue this request
    if (_active >= maxConcurrent) {
      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
    }

    _active++;
  }

  /// Releases a permit, allowing the next queued request to proceed.
  ///
  /// Must be called after [acquire], typically in a finally block.
  void release() {
    assert(_active > 0, 'Cannot release when no active permits');
    
    _active--;
    _lastReleaseTime = DateTime.now();

    // Process next queued request if any
    if (_queue.isNotEmpty) {
      final completer = _queue.removeAt(0);
      completer.complete();
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
