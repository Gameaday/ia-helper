/// Rate limiter status information for UI display
library;

/// Status of the rate limiter at a point in time
class RateLimitStatus {
  /// Number of active concurrent requests
  final int activeRequests;
  
  /// Number of requests waiting in queue
  final int queuedRequests;
  
  /// Maximum concurrent requests allowed
  final int maxConcurrent;
  
  /// Whether rate limiter is at capacity
  final bool isAtCapacity;
  
  /// Retry-After delay in seconds (if server requested a delay)
  final int? retryAfterSeconds;
  
  /// Time when retry-after expires (if applicable)
  final DateTime? retryAfterExpiry;

  const RateLimitStatus({
    required this.activeRequests,
    required this.queuedRequests,
    required this.maxConcurrent,
    required this.isAtCapacity,
    this.retryAfterSeconds,
    this.retryAfterExpiry,
  });

  /// Create empty/initial status
  factory RateLimitStatus.initial() {
    return const RateLimitStatus(
      activeRequests: 0,
      queuedRequests: 0,
      maxConcurrent: 3,
      isAtCapacity: false,
      retryAfterSeconds: null,
      retryAfterExpiry: null,
    );
  }

  /// Create from RateLimiter instance
  factory RateLimitStatus.fromRateLimiter({
    required int activeCount,
    required int queueLength,
    required int maxConcurrent,
    int? retryAfterSeconds,
    DateTime? retryAfterExpiry,
  }) {
    return RateLimitStatus(
      activeRequests: activeCount,
      queuedRequests: queueLength,
      maxConcurrent: maxConcurrent,
      isAtCapacity: activeCount >= maxConcurrent,
      retryAfterSeconds: retryAfterSeconds,
      retryAfterExpiry: retryAfterExpiry,
    );
  }

  /// Whether rate limiting is currently active (queue has items)
  bool get isRateLimiting => queuedRequests > 0 || isAtCapacity;

  /// Whether server requested a retry delay
  bool get hasRetryAfter => retryAfterSeconds != null && retryAfterSeconds! > 0;

  /// Remaining seconds until retry-after expires
  int? get retryAfterRemaining {
    if (retryAfterExpiry == null) return null;
    final remaining = retryAfterExpiry!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Utilization percentage (0-100)
  double get utilizationPercentage {
    if (maxConcurrent == 0) return 0;
    return (activeRequests / maxConcurrent * 100).clamp(0, 100);
  }

  /// Status level for color coding
  RateLimitLevel get level {
    if (hasRetryAfter) return RateLimitLevel.serverDelay;
    if (queuedRequests > 5) return RateLimitLevel.heavy;
    if (queuedRequests > 0) return RateLimitLevel.moderate;
    if (isAtCapacity) return RateLimitLevel.atCapacity;
    return RateLimitLevel.normal;
  }

  /// Status message for display
  String get message {
    if (hasRetryAfter) {
      return 'Server delay: ${retryAfterRemaining}s';
    }
    if (queuedRequests > 0) {
      return '$queuedRequests waiting';
    }
    if (isAtCapacity) {
      return 'At capacity';
    }
    return '$activeRequests/$maxConcurrent active';
  }
}

/// Rate limit severity level
enum RateLimitLevel {
  /// Normal operation
  normal,
  
  /// At capacity but no queue
  atCapacity,
  
  /// Moderate queue (1-5 requests)
  moderate,
  
  /// Heavy queue (6+ requests)
  heavy,
  
  /// Server requested delay (429/503 with Retry-After)
  serverDelay,
}

extension RateLimitLevelExtension on RateLimitLevel {
  /// Color for this level
  int get colorValue {
    switch (this) {
      case RateLimitLevel.normal:
        return 0xFF4CAF50; // Green
      case RateLimitLevel.atCapacity:
        return 0xFF2196F3; // Blue
      case RateLimitLevel.moderate:
        return 0xFFFF9800; // Orange
      case RateLimitLevel.heavy:
        return 0xFFF44336; // Red
      case RateLimitLevel.serverDelay:
        return 0xFF9C27B0; // Purple
    }
  }

  /// Icon for this level
  String get icon {
    switch (this) {
      case RateLimitLevel.normal:
        return '✓'; // Check
      case RateLimitLevel.atCapacity:
        return '⏸'; // Pause
      case RateLimitLevel.moderate:
        return '⚠'; // Warning
      case RateLimitLevel.heavy:
        return '🔴'; // Red circle
      case RateLimitLevel.serverDelay:
        return '⏰'; // Alarm clock
    }
  }
}
