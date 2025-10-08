/// Per-download progress tracking for enhanced UI feedback
library;

/// Real-time progress information for a single download
class DownloadProgressInfo {
  /// Current download speed in bytes per second (smoothed)
  final double currentSpeed;

  /// Average download speed in bytes per second since start
  final double averageSpeed;

  /// Estimated time remaining in seconds (null if unknown)
  final int? etaSeconds;

  /// Total bytes downloaded so far
  final int bytesDownloaded;

  /// Total bytes to download
  final int totalBytes;

  /// Overall progress percentage (0-100)
  final double progressPercentage;

  /// Number of files completed
  final int filesCompleted;

  /// Total number of files
  final int totalFiles;

  /// Time elapsed since download started
  final Duration elapsed;

  /// Whether download is currently throttled by bandwidth limiter
  final bool isThrottled;

  const DownloadProgressInfo({
    required this.currentSpeed,
    required this.averageSpeed,
    this.etaSeconds,
    required this.bytesDownloaded,
    required this.totalBytes,
    required this.progressPercentage,
    required this.filesCompleted,
    required this.totalFiles,
    required this.elapsed,
    this.isThrottled = false,
  });

  /// Create empty/initial progress info
  factory DownloadProgressInfo.initial() {
    return const DownloadProgressInfo(
      currentSpeed: 0,
      averageSpeed: 0,
      etaSeconds: null,
      bytesDownloaded: 0,
      totalBytes: 0,
      progressPercentage: 0,
      filesCompleted: 0,
      totalFiles: 0,
      elapsed: Duration.zero,
      isThrottled: false,
    );
  }

  /// Calculate progress info from download state
  factory DownloadProgressInfo.calculate({
    required int bytesDownloaded,
    required int totalBytes,
    required int filesCompleted,
    required int totalFiles,
    required DateTime startTime,
    double? currentSpeed,
    bool isThrottled = false,
  }) {
    final elapsed = DateTime.now().difference(startTime);
    final elapsedSeconds = elapsed.inSeconds;

    // Calculate average speed
    final averageSpeed = elapsedSeconds > 0
        ? bytesDownloaded / elapsedSeconds
        : 0.0;

    // Calculate ETA based on average speed (more stable than current speed)
    final remainingBytes = totalBytes - bytesDownloaded;
    final etaSeconds = averageSpeed > 0
        ? (remainingBytes / averageSpeed).round()
        : null;

    // Calculate progress percentage
    final progressPercentage = totalBytes > 0
        ? (bytesDownloaded / totalBytes * 100)
        : 0.0;

    return DownloadProgressInfo(
      currentSpeed: currentSpeed ?? averageSpeed,
      averageSpeed: averageSpeed,
      etaSeconds: etaSeconds,
      bytesDownloaded: bytesDownloaded,
      totalBytes: totalBytes,
      progressPercentage: progressPercentage.clamp(0.0, 100.0),
      filesCompleted: filesCompleted,
      totalFiles: totalFiles,
      elapsed: elapsed,
      isThrottled: isThrottled,
    );
  }

  /// Format speed for display (e.g., "1.5 MB/s")
  String get formattedCurrentSpeed => _formatSpeed(currentSpeed);

  /// Format average speed for display
  String get formattedAverageSpeed => _formatSpeed(averageSpeed);

  /// Format ETA for display (e.g., "2m 30s", "1h 5m", "30s")
  String get formattedEta {
    if (etaSeconds == null || etaSeconds! <= 0) {
      return 'Calculating...';
    }

    final seconds = etaSeconds!;

    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return remainingSeconds > 0
          ? '${minutes}m ${remainingSeconds}s'
          : '${minutes}m';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  /// Format elapsed time for display
  String get formattedElapsed {
    final seconds = elapsed.inSeconds;

    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '$hours:${minutes.toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    }
  }

  /// Format file progress for display (e.g., "3/10 files")
  String get formattedFileProgress => '$filesCompleted/$totalFiles files';

  /// Whether download has meaningful speed data
  bool get hasSpeedData => averageSpeed > 0;

  /// Whether download has ETA data
  bool get hasEta => etaSeconds != null && etaSeconds! > 0;

  /// Format speed in human-readable format
  static String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else if (bytesPerSecond < 1024 * 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB/s';
    }
  }

  @override
  String toString() {
    return 'DownloadProgressInfo('
        'speed: $formattedCurrentSpeed, '
        'progress: ${progressPercentage.toStringAsFixed(1)}%, '
        'eta: $formattedEta, '
        'files: $formattedFileProgress'
        ')';
  }
}
