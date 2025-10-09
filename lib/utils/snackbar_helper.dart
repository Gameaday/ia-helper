import 'package:flutter/material.dart';
import 'error_handler.dart';

/// Enhanced SnackBar utilities with MD3 styling and error handling
class SnackBarHelper {
  SnackBarHelper._();

  /// Show a standard informational SnackBar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: action,
      ),
    );
  }

  /// Show a success SnackBar with checkmark icon
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;

    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: colorScheme.inversePrimary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: action,
      ),
    );
  }

  /// Show a warning SnackBar
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: action,
      ),
    );
  }

  /// Show an error SnackBar with intelligent error parsing
  static void showError(
    BuildContext context,
    dynamic error, {
    Duration? duration,
    VoidCallback? onRetry,
  }) {
    if (!context.mounted) return;

    final errorInfo = ErrorHandler.parseError(error);
    final colorScheme = Theme.of(context).colorScheme;

    // Use longer duration for errors with suggestions
    final snackBarDuration = duration ??
        (errorInfo.suggestion != null
            ? const Duration(seconds: 6)
            : const Duration(seconds: 4));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getErrorIcon(errorInfo.type),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorInfo.message,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (errorInfo.suggestion != null) ...[
              const SizedBox(height: 8),
              Text(
                errorInfo.suggestion!,
                style: const TextStyle(fontSize: 12, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: snackBarDuration,
        action: errorInfo.canRetry && onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show a loading SnackBar (persistent until dismissed)
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      showLoading(
    BuildContext context,
    String message,
  ) {
    if (!context.mounted) {
      throw StateError('Context is not mounted');
    }

    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(days: 1), // Effectively persistent
      ),
    );
  }

  /// Dismiss any currently showing SnackBar
  static void dismiss(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Get appropriate icon for error type
  static IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.timeout:
        return Icons.access_time;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.rateLimit:
        return Icons.speed;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.forbidden:
        return Icons.lock;
      case ErrorType.badRequest:
        return Icons.error_outline;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }
}
