import 'package:flutter/material.dart';

/// A Material Design 3 compliant error state widget.
/// 
/// Displays an error message with an icon, description, and action buttons.
/// Can be used across the app for consistent error handling UX.
/// 
/// Example:
/// ```dart
/// ErrorStateWidget(
///   icon: Icons.cloud_off,
///   title: 'No Internet Connection',
///   message: 'Check your network settings and try again.',
///   primaryAction: ErrorAction(
///     label: 'Retry',
///     onPressed: () => _retryOperation(),
///   ),
///   secondaryAction: ErrorAction(
///     label: 'Go Offline',
///     onPressed: () => _goOffline(),
///   ),
/// )
/// ```
class ErrorStateWidget extends StatelessWidget {
  /// The icon to display (defaults to error_outline)
  final IconData icon;

  /// The error title (short, descriptive)
  final String title;

  /// Detailed error message or suggestion
  final String message;

  /// Primary action (filled button)
  final ErrorAction? primaryAction;

  /// Secondary action (text button)
  final ErrorAction? secondaryAction;

  /// Icon size (defaults to 64)
  final double iconSize;

  /// Maximum width for text content (defaults to 400)
  final double maxContentWidth;

  const ErrorStateWidget({
    super.key,
    this.icon = Icons.error_outline,
    required this.title,
    required this.message,
    this.primaryAction,
    this.secondaryAction,
    this.iconSize = 64,
    this.maxContentWidth = 400,
  });

  /// Shortcut constructor for network errors
  factory ErrorStateWidget.network({
    Key? key,
    String? message,
    required VoidCallback onRetry,
    VoidCallback? onGoBack,
  }) {
    return ErrorStateWidget(
      key: key,
      icon: Icons.cloud_off,
      title: 'No Internet Connection',
      message: message ?? 'Check your network settings and try again.',
      primaryAction: ErrorAction(
        label: 'Retry',
        icon: Icons.refresh,
        onPressed: onRetry,
      ),
      secondaryAction: onGoBack != null
          ? ErrorAction(
              label: 'Go Back',
              onPressed: onGoBack,
            )
          : null,
    );
  }

  /// Shortcut constructor for not found errors
  factory ErrorStateWidget.notFound({
    Key? key,
    required String itemType,
    VoidCallback? onGoBack,
  }) {
    return ErrorStateWidget(
      key: key,
      icon: Icons.search_off,
      title: '$itemType Not Found',
      message: 'The $itemType you\'re looking for doesn\'t exist or has been removed.',
      primaryAction: onGoBack != null
          ? ErrorAction(
              label: 'Go Back',
              icon: Icons.arrow_back,
              onPressed: onGoBack,
            )
          : null,
    );
  }

  /// Shortcut constructor for server errors
  factory ErrorStateWidget.server({
    Key? key,
    String? message,
    required VoidCallback onRetry,
    VoidCallback? onGoBack,
  }) {
    return ErrorStateWidget(
      key: key,
      icon: Icons.warning_amber,
      title: 'Server Error',
      message: message ?? 'Something went wrong on our end. Please try again.',
      primaryAction: ErrorAction(
        label: 'Retry',
        icon: Icons.refresh,
        onPressed: onRetry,
      ),
      secondaryAction: onGoBack != null
          ? ErrorAction(
              label: 'Go Back',
              onPressed: onGoBack,
            )
          : null,
    );
  }

  /// Shortcut constructor for permission errors
  factory ErrorStateWidget.permission({
    Key? key,
    required String permission,
    VoidCallback? onOpenSettings,
    VoidCallback? onGoBack,
  }) {
    return ErrorStateWidget(
      key: key,
      icon: Icons.lock_outline,
      title: 'Permission Required',
      message: 'This app needs $permission permission to continue.',
      primaryAction: onOpenSettings != null
          ? ErrorAction(
              label: 'Open Settings',
              icon: Icons.settings,
              onPressed: onOpenSettings,
            )
          : null,
      secondaryAction: onGoBack != null
          ? ErrorAction(
              label: 'Go Back',
              onPressed: onGoBack,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon
              Icon(
                icon,
                size: iconSize,
                color: colorScheme.error,
              ),
              const SizedBox(height: 24),

              // Error title
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Error message
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Action buttons
              if (primaryAction != null || secondaryAction != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Primary action (filled button)
                    if (primaryAction != null)
                      FilledButton.icon(
                        onPressed: primaryAction!.onPressed,
                        icon: primaryAction!.icon != null
                            ? Icon(primaryAction!.icon)
                            : const SizedBox.shrink(),
                        label: Text(primaryAction!.label),
                      ),
                    if (primaryAction != null && secondaryAction != null)
                      const SizedBox(height: 12),

                    // Secondary action (text button)
                    if (secondaryAction != null)
                      TextButton.icon(
                        onPressed: secondaryAction!.onPressed,
                        icon: secondaryAction!.icon != null
                            ? Icon(secondaryAction!.icon)
                            : const SizedBox.shrink(),
                        label: Text(secondaryAction!.label),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Action button configuration for ErrorStateWidget
class ErrorAction {
  /// Button label text
  final String label;

  /// Optional icon
  final IconData? icon;

  /// Callback when button is pressed
  final VoidCallback onPressed;

  const ErrorAction({
    required this.label,
    this.icon,
    required this.onPressed,
  });
}
