/// Download priority levels for Internet Archive downloads
library;

/// Download priority levels for Internet Archive downloads
///
/// Controls request priority header (X-Accept-Reduced-Priority)
/// and queue ordering for concurrent downloads.

enum DownloadPriority {
  /// Low priority - adds reduced priority header, queued last
  low,

  /// Normal priority - default behavior, no special headers
  normal,

  /// High priority - queued first, no reduced priority header
  high,
}

extension DownloadPriorityExtension on DownloadPriority {
  /// Get display name for UI
  String get displayName {
    switch (this) {
      case DownloadPriority.low:
        return 'Low';
      case DownloadPriority.normal:
        return 'Normal';
      case DownloadPriority.high:
        return 'High';
    }
  }

  /// Get icon for UI representation
  String get icon {
    switch (this) {
      case DownloadPriority.low:
        return '⬇️'; // Down arrow
      case DownloadPriority.normal:
        return '➡️'; // Right arrow
      case DownloadPriority.high:
        return '⬆️'; // Up arrow
    }
  }

  /// Get color for UI representation
  int get colorValue {
    switch (this) {
      case DownloadPriority.low:
        return 0xFF9E9E9E; // Grey
      case DownloadPriority.normal:
        return 0xFF2196F3; // Blue
      case DownloadPriority.high:
        return 0xFFFF9800; // Orange
    }
  }

  /// Whether to send X-Accept-Reduced-Priority header
  bool get useReducedPriorityHeader {
    return this == DownloadPriority.low;
  }

  /// Queue sort weight (higher = processed first)
  int get queueWeight {
    switch (this) {
      case DownloadPriority.low:
        return 1;
      case DownloadPriority.normal:
        return 2;
      case DownloadPriority.high:
        return 3;
    }
  }

  /// Get description for tooltip/help
  String get description {
    switch (this) {
      case DownloadPriority.low:
        return 'Lower priority, processed last. Helps reduce server load.';
      case DownloadPriority.normal:
        return 'Default priority, balanced processing.';
      case DownloadPriority.high:
        return 'Higher priority, processed first in queue.';
    }
  }
}
