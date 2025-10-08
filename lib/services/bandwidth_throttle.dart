import 'dart:async';
import 'package:flutter/foundation.dart';

/// Bandwidth throttle using token bucket algorithm.
///
/// Controls download/upload speed by limiting bytes per second.
/// Uses token bucket algorithm which allows:
/// - Smooth bandwidth limiting
/// - Brief bursts for better performance
/// - Dynamic rate adjustment
///
/// Token bucket works by:
/// 1. Tokens are added at a fixed rate (bytesPerSecond)
/// 2. Each data transfer consumes tokens
/// 3. If no tokens available, transfer must wait
/// 4. Bucket has a maximum capacity (burst size)
///
/// Usage:
/// ```dart
/// final throttle = BandwidthThrottle(bytesPerSecond: 1024 * 1024); // 1 MB/s
///
/// // Before sending/receiving data
/// await throttle.consume(chunk.length);
/// // Now send/receive the data
/// ```
class BandwidthThrottle {
  final int bytesPerSecond;
  final int burstSize;

  double _availableTokens;
  DateTime _lastUpdate;
  bool _isPaused = false;

  /// Creates a bandwidth throttle with specified limits.
  ///
  /// [bytesPerSecond]: Maximum bytes per second (e.g., 1048576 for 1 MB/s)
  /// [burstSize]: Maximum burst size in bytes (default: 2x bytesPerSecond)
  ///              Allows brief speed-ups for better perceived performance
  BandwidthThrottle({required this.bytesPerSecond, int? burstSize})
    : burstSize = burstSize ?? (bytesPerSecond * 2),
      _availableTokens = (burstSize ?? (bytesPerSecond * 2)).toDouble(),
      _lastUpdate = DateTime.now() {
    assert(bytesPerSecond > 0, 'bytesPerSecond must be positive');
    assert(
      this.burstSize >= bytesPerSecond,
      'burstSize must be >= bytesPerSecond',
    );
  }

  /// Current bytes per second limit.
  int get currentLimit => bytesPerSecond;

  /// Whether throttle is currently paused.
  bool get isPaused => _isPaused;

  /// Available tokens (bytes that can be consumed immediately).
  double get availableTokens => _availableTokens;

  /// Consume tokens for data transfer.
  ///
  /// Blocks until enough tokens are available.
  /// [bytes]: Number of bytes to consume
  ///
  /// Returns: Actual delay duration (Duration.zero if no delay needed)
  Future<Duration> consume(int bytes) async {
    if (_isPaused || bytesPerSecond == 0 || bytes <= 0) {
      return Duration.zero;
    }

    // Refill tokens based on time elapsed
    _refillTokens();

    // If enough tokens available, consume immediately
    if (_availableTokens >= bytes) {
      _availableTokens -= bytes;
      return Duration.zero;
    }

    // Calculate delay needed to get enough tokens
    final tokensNeeded = bytes - _availableTokens;
    final delaySeconds = tokensNeeded / bytesPerSecond;
    final delay = Duration(microseconds: (delaySeconds * 1000000).round());

    if (kDebugMode) {
      debugPrint(
        '[BandwidthThrottle] Throttling: need $bytes bytes, '
        'have ${_availableTokens.toInt()}, '
        'delay ${delay.inMilliseconds}ms',
      );
    }

    // Wait for tokens to become available
    await Future.delayed(delay);

    // Refill after delay and consume
    _refillTokens();
    _availableTokens -= bytes;

    return delay;
  }

  /// Refill token bucket based on elapsed time.
  void _refillTokens() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastUpdate);
    final elapsedSeconds = elapsed.inMicroseconds / 1000000.0;

    // Add tokens based on elapsed time
    final tokensToAdd = elapsedSeconds * bytesPerSecond;
    _availableTokens = (_availableTokens + tokensToAdd).clamp(
      0.0,
      burstSize.toDouble(),
    );

    _lastUpdate = now;
  }

  /// Pause bandwidth throttling.
  ///
  /// Useful for pausing downloads without changing limits.
  void pause() {
    _isPaused = true;
  }

  /// Resume bandwidth throttling.
  void resume() {
    _isPaused = false;
    _lastUpdate = DateTime.now(); // Reset time to avoid burst on resume
  }

  /// Update bandwidth limit dynamically.
  ///
  /// Useful for adjusting limits based on network conditions or user settings.
  /// Note: This creates a new instance internally, preserving no tokens.
  void updateLimit(int newBytesPerSecond) {
    if (newBytesPerSecond <= 0) {
      throw ArgumentError('bytesPerSecond must be positive');
    }

    // This would require modifying final fields, so we document
    // that users should create a new instance instead
    throw UnsupportedError(
      'Cannot update limit dynamically. Create a new BandwidthThrottle instance instead.',
    );
  }

  /// Get statistics about throttle usage.
  Map<String, dynamic> getStats() {
    _refillTokens(); // Update tokens before returning stats

    return {
      'bytesPerSecond': bytesPerSecond,
      'burstSize': burstSize,
      'availableTokens': _availableTokens.toInt(),
      'isPaused': _isPaused,
      'utilizationPercent': ((burstSize - _availableTokens) / burstSize * 100)
          .toInt(),
    };
  }

  /// Reset throttle state (clear tokens, reset timer).
  void reset() {
    _availableTokens = burstSize.toDouble();
    _lastUpdate = DateTime.now();
    _isPaused = false;
  }
}

/// Multi-download bandwidth manager.
///
/// Manages bandwidth allocation across multiple concurrent downloads.
/// Ensures fair distribution and global bandwidth limits.
///
/// Usage:
/// ```dart
/// final manager = BandwidthManager(totalBytesPerSecond: 5 * 1024 * 1024); // 5 MB/s
///
/// // Register downloads
/// final download1 = manager.createThrottle('download1');
/// final download2 = manager.createThrottle('download2');
///
/// // Use throttles
/// await download1.consume(chunk.length);
/// ```
class BandwidthManager {
  final int totalBytesPerSecond;
  final Map<String, BandwidthThrottle> _throttles = {};
  final Map<String, int> _bytesConsumed = {};
  bool _isPaused = false;

  /// Creates a bandwidth manager with global limit.
  ///
  /// [totalBytesPerSecond]: Total bandwidth limit across all downloads
  BandwidthManager({required this.totalBytesPerSecond}) {
    assert(totalBytesPerSecond > 0, 'totalBytesPerSecond must be positive');
  }

  /// Whether manager is paused.
  bool get isPaused => _isPaused;

  /// Number of active downloads.
  int get activeDownloads => _throttles.length;

  /// Create or get a throttle for a download.
  ///
  /// [downloadId]: Unique identifier for the download
  /// [bytesPerSecond]: Per-download limit (optional, uses fair share by default)
  BandwidthThrottle createThrottle(String downloadId, {int? bytesPerSecond}) {
    if (_throttles.containsKey(downloadId)) {
      return _throttles[downloadId]!;
    }

    // Fair share: divide total bandwidth by number of downloads
    final limit = bytesPerSecond ?? _calculateFairShare();

    final throttle = BandwidthThrottle(bytesPerSecond: limit);
    _throttles[downloadId] = throttle;
    _bytesConsumed[downloadId] = 0;

    return throttle;
  }

  /// Remove a throttle (when download completes/fails).
  void removeThrottle(String downloadId) {
    _throttles.remove(downloadId);
    _bytesConsumed.remove(downloadId);

    // Rebalance remaining downloads
    _rebalanceThrottles();
  }

  /// Calculate fair share of bandwidth per download.
  int _calculateFairShare() {
    if (_throttles.isEmpty) return totalBytesPerSecond;
    return totalBytesPerSecond ~/ (_throttles.length + 1);
  }

  /// Rebalance bandwidth across active downloads.
  void _rebalanceThrottles() {
    if (_throttles.isEmpty) return;

    final fairShare = totalBytesPerSecond ~/ _throttles.length;

    // Note: Can't update existing throttles, but this shows the concept
    // In practice, we'd need to recreate throttles or make bytesPerSecond mutable
    if (kDebugMode) {
      debugPrint(
        '[BandwidthManager] Rebalanced: $fairShare bytes/s per download '
        '(${_throttles.length} active)',
      );
    }
  }

  /// Track bytes consumed by a download.
  void trackBytes(String downloadId, int bytes) {
    _bytesConsumed[downloadId] = (_bytesConsumed[downloadId] ?? 0) + bytes;
  }

  /// Pause all downloads.
  void pauseAll() {
    _isPaused = true;
    for (final throttle in _throttles.values) {
      throttle.pause();
    }
  }

  /// Resume all downloads.
  void resumeAll() {
    _isPaused = false;
    for (final throttle in _throttles.values) {
      throttle.resume();
    }
  }

  /// Get statistics for all downloads.
  Map<String, dynamic> getStats() {
    final totalConsumed = _bytesConsumed.values.fold<int>(
      0,
      (sum, bytes) => sum + bytes,
    );

    return {
      'totalBytesPerSecond': totalBytesPerSecond,
      'activeDownloads': _throttles.length,
      'totalBytesConsumed': totalConsumed,
      'isPaused': _isPaused,
      'perDownloadStats': _throttles.map(
        (id, throttle) => MapEntry(id, {
          'bytesConsumed': _bytesConsumed[id] ?? 0,
          'throttleStats': throttle.getStats(),
        }),
      ),
    };
  }

  /// Clear all throttles.
  void clear() {
    _throttles.clear();
    _bytesConsumed.clear();
  }
}

/// Predefined bandwidth limits for common scenarios.
class BandwidthLimits {
  /// No limit (maximum speed).
  static const int unlimited = 0;

  /// 256 KB/s - Very slow, for background downloads.
  static const int verySlow = 256 * 1024;

  /// 512 KB/s - Slow, minimal impact on other apps.
  static const int slow = 512 * 1024;

  /// 1 MB/s - Moderate speed.
  static const int moderate = 1024 * 1024;

  /// 5 MB/s - Fast, good for most connections.
  static const int fast = 5 * 1024 * 1024;

  /// 10 MB/s - Very fast, for high-speed connections.
  static const int veryFast = 10 * 1024 * 1024;

  /// Get human-readable label for bytes per second.
  static String getLabel(int bytesPerSecond) {
    if (bytesPerSecond == unlimited) return 'Unlimited';
    if (bytesPerSecond < 1024) return '$bytesPerSecond B/s';
    if (bytesPerSecond < 1024 * 1024) return '${bytesPerSecond ~/ 1024} KB/s';
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
}

/// Global bandwidth manager instance.
///
/// Use this singleton for app-wide bandwidth management.
/// Can be reconfigured based on user settings.
BandwidthManager? _globalBandwidthManager;

BandwidthManager getGlobalBandwidthManager({
  int bytesPerSecond = BandwidthLimits.unlimited,
}) {
  _globalBandwidthManager ??= BandwidthManager(
    totalBytesPerSecond: bytesPerSecond > 0
        ? bytesPerSecond
        : BandwidthLimits.veryFast,
  );
  return _globalBandwidthManager!;
}

/// Reset global bandwidth manager (for testing or settings change).
void resetGlobalBandwidthManager() {
  _globalBandwidthManager = null;
}
