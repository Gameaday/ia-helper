/// Bandwidth Management Models and Presets
///
/// Provides convenient presets and models for bandwidth throttling configuration
library;

/// Bandwidth preset options for easy user selection
enum BandwidthPreset {
  /// 256 KB/s - Very slow, background downloads
  kb256(256 * 1024, '256 KB/s'),

  /// 512 KB/s - Slow, good for mobile data
  kb512(512 * 1024, '512 KB/s'),

  /// 1 MB/s - Moderate, balanced
  mb1(1024 * 1024, '1 MB/s'),

  /// 5 MB/s - Fast, good for multiple downloads
  mb5(5 * 1024 * 1024, '5 MB/s'),

  /// 10 MB/s - Very fast, high-speed connections
  mb10(10 * 1024 * 1024, '10 MB/s'),

  /// Unlimited - No bandwidth limit
  unlimited(0, 'Unlimited');

  const BandwidthPreset(this.bytesPerSecond, this.displayName);

  /// Bytes per second for this preset (0 = unlimited)
  final int bytesPerSecond;

  /// Display name for UI
  final String displayName;

  /// Check if this preset is unlimited
  bool get isUnlimited => bytesPerSecond == 0;

  /// Get human-readable description
  String get description {
    if (isUnlimited) {
      return 'No bandwidth limit - maximum speed';
    }
    if (bytesPerSecond < 1024 * 1024) {
      return 'Good for background downloads';
    }
    if (bytesPerSecond < 2 * 1024 * 1024) {
      return 'Balanced speed and courtesy';
    }
    return 'Fast downloads for urgent items';
  }

  /// Convert to icon for UI
  String get icon {
    if (isUnlimited) return '🚀';
    if (bytesPerSecond < 1024 * 1024) return '🐌';
    if (bytesPerSecond < 2 * 1024 * 1024) return '🚶';
    return '🏃';
  }

  /// Get from bytes per second value
  static BandwidthPreset fromBytesPerSecond(int bytesPerSecond) {
    for (final preset in BandwidthPreset.values) {
      if (preset.bytesPerSecond == bytesPerSecond) {
        return preset;
      }
    }
    // Find closest match
    if (bytesPerSecond == 0) return BandwidthPreset.unlimited;
    if (bytesPerSecond <= 256 * 1024) return BandwidthPreset.kb256;
    if (bytesPerSecond <= 512 * 1024) return BandwidthPreset.kb512;
    if (bytesPerSecond <= 1024 * 1024) return BandwidthPreset.mb1;
    if (bytesPerSecond <= 5 * 1024 * 1024) return BandwidthPreset.mb5;
    if (bytesPerSecond <= 10 * 1024 * 1024) return BandwidthPreset.mb10;
    return BandwidthPreset.unlimited;
  }
}

/// Bandwidth usage statistics
class BandwidthUsage {
  /// Current bandwidth usage in bytes per second
  final double currentBytesPerSecond;

  /// Maximum allowed bandwidth (0 = unlimited)
  final int maxBytesPerSecond;

  /// Number of active downloads
  final int activeDownloads;

  /// Per-download bandwidth allocation
  final double perDownloadBytesPerSecond;

  /// Whether bandwidth is being throttled
  final bool isThrottled;

  /// Total bytes transferred in current session
  final int totalBytesTransferred;

  /// Duration of current session
  final Duration sessionDuration;

  const BandwidthUsage({
    required this.currentBytesPerSecond,
    required this.maxBytesPerSecond,
    required this.activeDownloads,
    required this.perDownloadBytesPerSecond,
    required this.isThrottled,
    required this.totalBytesTransferred,
    required this.sessionDuration,
  });

  /// Percentage of bandwidth being used (0.0 - 1.0)
  double get usagePercentage {
    if (maxBytesPerSecond == 0) return 0.0; // Unlimited
    return (currentBytesPerSecond / maxBytesPerSecond).clamp(0.0, 1.0);
  }

  /// Whether bandwidth limit is close to being reached
  bool get isNearLimit => usagePercentage > 0.8;

  /// Human-readable current speed
  String get currentSpeedDisplay =>
      _formatBytesPerSecond(currentBytesPerSecond);

  /// Human-readable maximum speed
  String get maxSpeedDisplay => maxBytesPerSecond == 0
      ? 'Unlimited'
      : _formatBytesPerSecond(maxBytesPerSecond.toDouble());

  /// Average session speed
  double get averageSpeed {
    if (sessionDuration.inSeconds == 0) return 0.0;
    return totalBytesTransferred / sessionDuration.inSeconds;
  }

  /// Human-readable average speed
  String get averageSpeedDisplay => _formatBytesPerSecond(averageSpeed);

  /// Format bytes per second for display
  static String _formatBytesPerSecond(double bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    }
  }

  /// Create empty usage
  static const BandwidthUsage empty = BandwidthUsage(
    currentBytesPerSecond: 0.0,
    maxBytesPerSecond: 0,
    activeDownloads: 0,
    perDownloadBytesPerSecond: 0.0,
    isThrottled: false,
    totalBytesTransferred: 0,
    sessionDuration: Duration.zero,
  );

  @override
  String toString() {
    return 'BandwidthUsage('
        'current: $currentSpeedDisplay, '
        'max: $maxSpeedDisplay, '
        'active: $activeDownloads, '
        'throttled: $isThrottled)';
  }
}
