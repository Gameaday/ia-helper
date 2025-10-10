import 'package:flutter/material.dart';

/// A Material Design 3 compliant empty state widget.
/// 
/// Displays a friendly message with an icon when there's no content to show.
/// Can be used across the app for consistent empty state UX.
/// 
/// Example:
/// ```dart
/// EmptyStateWidget(
///   icon: Icons.favorite_border,
///   title: 'No Favorites Yet',
///   message: 'Archives you favorite will appear here.',
///   actionLabel: 'Browse Archives',
///   onAction: () => _browseArchives(),
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  /// The icon to display
  final IconData icon;

  /// The empty state title
  final String title;

  /// Detailed message or suggestion
  final String message;

  /// Optional action button label
  final String? actionLabel;

  /// Optional action callback
  final VoidCallback? onAction;

  /// Icon size (defaults to 80)
  final double iconSize;

  /// Maximum width for content (defaults to 400)
  final double maxContentWidth;

  /// Optional illustration widget (replaces icon if provided)
  final Widget? illustration;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconSize = 80,
    this.maxContentWidth = 400,
    this.illustration,
  });

  /// Shortcut for "no results" empty state
  factory EmptyStateWidget.noResults({
    Key? key,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyStateWidget(
      key: key,
      icon: Icons.search_off,
      title: 'No Results Found',
      message: message ?? 'Try adjusting your search or filters.',
      actionLabel: actionLabel ?? 'Clear Filters',
      onAction: onAction,
    );
  }

  /// Shortcut for "no favorites" empty state
  factory EmptyStateWidget.noFavorites({
    Key? key,
    VoidCallback? onAction,
  }) {
    return EmptyStateWidget(
      key: key,
      icon: Icons.favorite_border,
      title: 'No Favorites Yet',
      message: 'Archives you favorite will appear here for quick access.',
      actionLabel: 'Browse Archives',
      onAction: onAction,
    );
  }

  /// Shortcut for "no downloads" empty state
  factory EmptyStateWidget.noDownloads({
    Key? key,
    VoidCallback? onAction,
  }) {
    return EmptyStateWidget(
      key: key,
      icon: Icons.download_outlined,
      title: 'No Downloads',
      message: 'Your downloaded files will appear here.',
      actionLabel: 'Browse Archives',
      onAction: onAction,
    );
  }

  /// Shortcut for "no history" empty state
  factory EmptyStateWidget.noHistory({
    Key? key,
    VoidCallback? onAction,
  }) {
    return EmptyStateWidget(
      key: key,
      icon: Icons.history,
      title: 'No History',
      message: 'Your browsing history will appear here.',
      actionLabel: 'Start Searching',
      onAction: onAction,
    );
  }

  /// Shortcut for "no collections" empty state
  factory EmptyStateWidget.noCollections({
    Key? key,
    VoidCallback? onAction,
  }) {
    return EmptyStateWidget(
      key: key,
      icon: Icons.collections_bookmark_outlined,
      title: 'No Collections',
      message: 'Create collections to organize your archives.',
      actionLabel: 'Create Collection',
      onAction: onAction,
    );
  }

  /// Shortcut for "offline" empty state
  factory EmptyStateWidget.offline({
    Key? key,
    String? message,
    VoidCallback? onRetry,
  }) {
    return EmptyStateWidget(
      key: key,
      icon: Icons.cloud_off_outlined,
      title: 'You\'re Offline',
      message: message ?? 'Connect to the internet to browse archives.',
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }

  /// Shortcut for "end of list" indicator
  factory EmptyStateWidget.endOfList({
    Key? key,
    String? title,
    String? message,
    int? totalCount,
  }) {
    final displayTitle = title ?? 'You\'ve reached the end!';
    final displayMessage = totalCount != null
        ? 'Showing all $totalCount results'
        : message ?? 'No more results to display';

    return EmptyStateWidget(
      key: key,
      icon: Icons.check_circle_outline,
      title: displayTitle,
      message: displayMessage,
      iconSize: 64,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon or illustration
              if (illustration != null)
                illustration!
              else
                Icon(
                  icon,
                  size: iconSize,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              const SizedBox(height: 24),

              // Title
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              // Action button
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 32),
                FilledButton.tonalIcon(
                  onPressed: onAction,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state with custom illustration card
class EmptyStateWithCard extends StatelessWidget {
  /// The icon to display
  final IconData icon;

  /// The empty state title
  final String title;

  /// List of suggestion items
  final List<EmptyStateSuggestion> suggestions;

  /// Optional action button label
  final String? actionLabel;

  /// Optional action callback
  final VoidCallback? onAction;

  const EmptyStateWithCard({
    super.key,
    required this.icon,
    required this.title,
    required this.suggestions,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(
                icon,
                size: 80,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Suggestions card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Suggestions',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...suggestions.map((suggestion) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                suggestion.icon,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  suggestion.text,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Action button
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: onAction,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Suggestion item for EmptyStateWithCard
class EmptyStateSuggestion {
  final IconData icon;
  final String text;

  const EmptyStateSuggestion({
    required this.icon,
    required this.text,
  });
}
