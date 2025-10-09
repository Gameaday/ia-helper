import 'package:flutter/material.dart';
import '../utils/error_handler.dart';

/// Reusable error display card with MD3 styling and retry functionality
///
/// Displays user-friendly error messages with:
/// - Error type icon
/// - Error message
/// - Actionable suggestion
/// - Retry button (if retryable)
/// - Secondary action button (optional)
class ErrorCard extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;
  final bool showRetryButton;

  const ErrorCard({
    super.key,
    required this.error,
    this.onRetry,
    this.onSecondaryAction,
    this.secondaryActionLabel,
    this.showRetryButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final errorInfo = ErrorHandler.parseError(error);

    return Semantics(
      label:
          '${errorInfo.message}. ${errorInfo.suggestion ?? ''}${errorInfo.canRetry && showRetryButton ? ' Tap retry button to try again.' : ''}',
      liveRegion: true,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 0,
            color: colorScheme.errorContainer.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.error.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Error icon
                  ExcludeSemantics(
                    child: Icon(
                      _getErrorIcon(errorInfo.type),
                      size: 64,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error message
                  Text(
                    errorInfo.message,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Suggestion (if available)
                  if (errorInfo.suggestion != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorInfo.suggestion!,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      // Retry button (if error is retryable)
                      if (errorInfo.canRetry &&
                          showRetryButton &&
                          onRetry != null)
                        FilledButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),

                      // Secondary action (if provided)
                      if (onSecondaryAction != null)
                        FilledButton.tonal(
                          onPressed: onSecondaryAction,
                          child: Text(secondaryActionLabel ?? 'Go Back'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get appropriate icon for error type
  IconData _getErrorIcon(ErrorType type) {
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

/// Lightweight error banner for inline error display
class ErrorBanner extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorBanner({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final errorInfo = ErrorHandler.parseError(error);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  errorInfo.message,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                if (errorInfo.suggestion != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    errorInfo.suggestion!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (errorInfo.canRetry && onRetry != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRetry,
              tooltip: 'Retry',
              color: colorScheme.error,
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onDismiss,
              tooltip: 'Dismiss',
              color: colorScheme.error,
              iconSize: 20,
            ),
          ],
        ],
      ),
    );
  }
}
