import 'package:flutter/material.dart';
import '../models/search_result.dart';
import 'favorite_button.dart';

/// Display layout for archive result cards
enum ArchiveResultCardLayout {
  /// Grid layout - thumbnail on top, metadata below
  grid,

  /// List layout - thumbnail on left, metadata on right
  list,
}

/// Archive result card widget matching Internet Archive design
///
/// Displays search results with thumbnail, title, creator, and metadata.
/// Supports both grid and list layouts with adaptive aspect ratios.
/// Follows Material Design 3 guidelines for elevation, spacing, and colors.
class ArchiveResultCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;
  final ArchiveResultCardLayout layout;
  final bool showThumbnail;

  const ArchiveResultCard({
    super.key,
    required this.result,
    required this.onTap,
    this.layout = ArchiveResultCardLayout.grid,
    this.showThumbnail = true,
  });

  @override
  Widget build(BuildContext context) {
    return layout == ArchiveResultCardLayout.grid
        ? _buildGridCard(context)
        : _buildListCard(context);
  }

  /// Build grid layout card (thumbnail on top)
  Widget _buildGridCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail section with Hero animation
            Hero(
              tag: 'archive-thumbnail-${result.identifier}',
              child: AspectRatio(
                aspectRatio: _getAspectRatio(),
                child: _buildThumbnail(context),
              ),
            ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    result.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Creator (if available)
                  if (result.creator != null && result.creator!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      result.creator!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Metadata chips
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (result.mediaType != null)
                        _buildMetadataChip(
                          context,
                          _formatMediaType(result.mediaType!),
                          Icons.category_outlined,
                        ),
                      if (result.downloads != null && result.downloads! > 0)
                        _buildMetadataChip(
                          context,
                          _formatDownloads(result.downloads!),
                          Icons.download_outlined,
                        ),
                      if (result.date != null)
                        _buildMetadataChip(
                          context,
                          _formatDate(result.date!),
                          Icons.calendar_today_outlined,
                        ),
                    ],
                  ),

                  // Favorite button
                  Align(
                    alignment: Alignment.centerRight,
                    child: FavoriteIconButton(
                      identifier: result.identifier,
                      iconSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build list layout card (thumbnail on left)
  Widget _buildListCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail section with Hero animation
            Hero(
              tag: 'archive-thumbnail-${result.identifier}',
              child: SizedBox(
                  width: 120, height: 120, child: _buildThumbnail(context)),
            ),

            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      result.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Creator (if available)
                    if (result.creator != null &&
                        result.creator!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        result.creator!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Description (if available)
                    if (result.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        result.description,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Metadata chips
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (result.mediaType != null)
                          _buildMetadataChip(
                            context,
                            _formatMediaType(result.mediaType!),
                            Icons.category_outlined,
                          ),
                        if (result.downloads != null && result.downloads! > 0)
                          _buildMetadataChip(
                            context,
                            _formatDownloads(result.downloads!),
                            Icons.download_outlined,
                          ),
                        if (result.date != null)
                          _buildMetadataChip(
                            context,
                            _formatDate(result.date!),
                            Icons.calendar_today_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Favorite button
            Padding(
              padding: const EdgeInsets.all(8),
              child: FavoriteIconButton(
                identifier: result.identifier,
                iconSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build thumbnail with loading and error states
  Widget _buildThumbnail(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // If thumbnails are disabled, show placeholder
    if (!showThumbnail || result.thumbnailUrl == null) {
      return _buildPlaceholder(context);
    }

    return Image.network(
      result.thumbnailUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        // Show loading indicator
        return Container(
          color: colorScheme.surfaceContainerHighest,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Show error placeholder
        return _buildPlaceholder(context, isError: true);
      },
    );
  }

  /// Build placeholder for missing/disabled thumbnails
  Widget _buildPlaceholder(BuildContext context, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    switch (result.mediaType?.toLowerCase()) {
      case 'texts':
        icon = Icons.book_outlined;
        break;
      case 'movies':
      case 'video':
        icon = Icons.movie_outlined;
        break;
      case 'audio':
      case 'etree':
        icon = Icons.audiotrack_outlined;
        break;
      case 'software':
        icon = Icons.apps_outlined;
        break;
      case 'image':
        icon = Icons.image_outlined;
        break;
      default:
        icon = Icons.archive_outlined;
    }

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          icon,
          size: 48,
          color: isError
              ? colorScheme.error.withValues(alpha: 0.5)
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  /// Build metadata chip
  Widget _buildMetadataChip(BuildContext context, String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 3),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Get aspect ratio based on media type
  double _getAspectRatio() {
    switch (result.mediaType?.toLowerCase()) {
      case 'movies':
      case 'video':
        return 16 / 9; // Widescreen for videos
      case 'texts':
      case 'book':
        return 3 / 4; // Portrait for books
      case 'audio':
      case 'etree':
        return 1 / 1; // Square for audio
      default:
        return 4 / 3; // Default landscape
    }
  }

  /// Format media type for display
  String _formatMediaType(String mediaType) {
    switch (mediaType.toLowerCase()) {
      case 'texts':
        return 'Book';
      case 'movies':
        return 'Video';
      case 'audio':
        return 'Audio';
      case 'etree':
        return 'Music';
      case 'software':
        return 'Software';
      case 'image':
        return 'Image';
      default:
        return mediaType;
    }
  }

  /// Format downloads for display
  String _formatDownloads(int downloads) {
    if (downloads >= 1000000) {
      return '${(downloads / 1000000).toStringAsFixed(1)}M';
    } else if (downloads >= 1000) {
      return '${(downloads / 1000).toStringAsFixed(1)}K';
    } else {
      return downloads.toString();
    }
  }

  /// Format date for display
  String _formatDate(String date) {
    // Try to parse and format the date
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.year}';
    } catch (e) {
      // If parsing fails, return the first 4 characters (year)
      if (date.length >= 4) {
        return date.substring(0, 4);
      }
      return date;
    }
  }
}
