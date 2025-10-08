/// Categorized download error information for enhanced error handling
///
/// Provides structured error data with:
/// - Error category for appropriate handling
/// - Retry recommendations
/// - User-friendly messages
/// - Recovery suggestions
library;

/// Error categories for download failures
enum DownloadErrorCategory {
  /// Network connectivity issues (no internet, timeout)
  network,

  /// Server errors (404, 500, 503)
  server,

  /// Rate limiting or quota exceeded
  rateLimited,

  /// Insufficient storage space
  storage,

  /// Permission denied (file system, network)
  permission,

  /// Corrupted download or checksum mismatch
  corruption,

  /// User cancelled the operation
  cancelled,

  /// Unknown or uncategorized error
  unknown,
}

/// Extension for error category properties
extension DownloadErrorCategoryExtension on DownloadErrorCategory {
  /// User-friendly category name
  String get displayName {
    switch (this) {
      case DownloadErrorCategory.network:
        return 'Network Error';
      case DownloadErrorCategory.server:
        return 'Server Error';
      case DownloadErrorCategory.rateLimited:
        return 'Rate Limited';
      case DownloadErrorCategory.storage:
        return 'Storage Error';
      case DownloadErrorCategory.permission:
        return 'Permission Error';
      case DownloadErrorCategory.corruption:
        return 'Data Corruption';
      case DownloadErrorCategory.cancelled:
        return 'Cancelled';
      case DownloadErrorCategory.unknown:
        return 'Unknown Error';
    }
  }

  /// Icon for visual representation
  String get icon {
    switch (this) {
      case DownloadErrorCategory.network:
        return '📡';
      case DownloadErrorCategory.server:
        return '🖥️';
      case DownloadErrorCategory.rateLimited:
        return '⏱️';
      case DownloadErrorCategory.storage:
        return '💾';
      case DownloadErrorCategory.permission:
        return '🔒';
      case DownloadErrorCategory.corruption:
        return '⚠️';
      case DownloadErrorCategory.cancelled:
        return '🚫';
      case DownloadErrorCategory.unknown:
        return '❓';
    }
  }

  /// Whether this error type is retryable
  bool get isRetryable {
    switch (this) {
      case DownloadErrorCategory.network:
      case DownloadErrorCategory.server:
      case DownloadErrorCategory.rateLimited:
        return true;
      case DownloadErrorCategory.storage:
      case DownloadErrorCategory.permission:
      case DownloadErrorCategory.corruption:
      case DownloadErrorCategory.cancelled:
      case DownloadErrorCategory.unknown:
        return false;
    }
  }

  /// Suggested retry delay in seconds
  int? get suggestedRetryDelay {
    switch (this) {
      case DownloadErrorCategory.network:
        return 5;
      case DownloadErrorCategory.server:
        return 10;
      case DownloadErrorCategory.rateLimited:
        return 60;
      default:
        return null;
    }
  }
}

/// Detailed error information for downloads
class DownloadError {
  final DownloadErrorCategory category;
  final String message;
  final String? technicalDetails;
  final int? statusCode;
  final DateTime timestamp;
  final int retryCount;
  final int? retryAfterSeconds;

  DownloadError({
    required this.category,
    required this.message,
    this.technicalDetails,
    this.statusCode,
    DateTime? timestamp,
    this.retryCount = 0,
    this.retryAfterSeconds,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create error from exception
  factory DownloadError.fromException(
    Exception exception, {
    int retryCount = 0,
  }) {
    final message = exception.toString();

    // Categorize based on message content
    if (message.contains('SocketException') ||
        message.contains('NetworkException') ||
        message.contains('timeout')) {
      return DownloadError(
        category: DownloadErrorCategory.network,
        message: 'Network connection failed',
        technicalDetails: message,
        retryCount: retryCount,
      );
    }

    if (message.contains('404')) {
      return DownloadError(
        category: DownloadErrorCategory.server,
        message: 'File not found on server',
        technicalDetails: message,
        statusCode: 404,
        retryCount: retryCount,
      );
    }

    if (message.contains('429') || message.contains('rate limit')) {
      return DownloadError(
        category: DownloadErrorCategory.rateLimited,
        message: 'Too many requests - please wait',
        technicalDetails: message,
        statusCode: 429,
        retryCount: retryCount,
      );
    }

    if (message.contains('503')) {
      return DownloadError(
        category: DownloadErrorCategory.server,
        message: 'Server temporarily unavailable',
        technicalDetails: message,
        statusCode: 503,
        retryCount: retryCount,
      );
    }

    if (message.contains('storage') || message.contains('disk')) {
      return DownloadError(
        category: DownloadErrorCategory.storage,
        message: 'Insufficient storage space',
        technicalDetails: message,
        retryCount: retryCount,
      );
    }

    if (message.contains('permission') || message.contains('denied')) {
      return DownloadError(
        category: DownloadErrorCategory.permission,
        message: 'Permission denied',
        technicalDetails: message,
        retryCount: retryCount,
      );
    }

    if (message.contains('checksum') || message.contains('corrupt')) {
      return DownloadError(
        category: DownloadErrorCategory.corruption,
        message: 'Downloaded file is corrupted',
        technicalDetails: message,
        retryCount: retryCount,
      );
    }

    if (message.contains('cancel')) {
      return DownloadError(
        category: DownloadErrorCategory.cancelled,
        message: 'Download cancelled by user',
        technicalDetails: message,
        retryCount: retryCount,
      );
    }

    return DownloadError(
      category: DownloadErrorCategory.unknown,
      message: 'An unexpected error occurred',
      technicalDetails: message,
      retryCount: retryCount,
    );
  }

  /// Get suggested action message
  String get suggestedAction {
    switch (category) {
      case DownloadErrorCategory.network:
        return 'Check your internet connection and try again';
      case DownloadErrorCategory.server:
        if (statusCode == 404) {
          return 'This file may no longer be available';
        }
        return 'The server is having issues - try again later';
      case DownloadErrorCategory.rateLimited:
        final delay = retryAfterSeconds ?? category.suggestedRetryDelay ?? 60;
        return 'Wait $delay seconds before retrying';
      case DownloadErrorCategory.storage:
        return 'Free up storage space and try again';
      case DownloadErrorCategory.permission:
        return 'Grant storage permissions in settings';
      case DownloadErrorCategory.corruption:
        return 'Try downloading the file again';
      case DownloadErrorCategory.cancelled:
        return 'Restart the download if needed';
      case DownloadErrorCategory.unknown:
        return 'Try again or contact support if the issue persists';
    }
  }

  /// Copy with new values
  DownloadError copyWith({
    DownloadErrorCategory? category,
    String? message,
    String? technicalDetails,
    int? statusCode,
    DateTime? timestamp,
    int? retryCount,
    int? retryAfterSeconds,
  }) {
    return DownloadError(
      category: category ?? this.category,
      message: message ?? this.message,
      technicalDetails: technicalDetails ?? this.technicalDetails,
      statusCode: statusCode ?? this.statusCode,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      retryAfterSeconds: retryAfterSeconds ?? this.retryAfterSeconds,
    );
  }
}
