import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../models/file_preview.dart';

/// Widget for displaying image previews with zoom and pan
///
/// Features:
/// - Pinch to zoom using photo_view package
/// - Pan gesture support
/// - Double-tap to reset zoom
/// - Loading and error states
/// - Image info overlay
class ImagePreviewWidget extends StatelessWidget {
  final FilePreview preview;

  const ImagePreviewWidget({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    if (preview.previewData == null || preview.previewData!.isEmpty) {
      return const Center(child: Text('No image preview available'));
    }

    return Stack(
      children: [
        // Image viewer with zoom/pan
        PhotoView(
          imageProvider: MemoryImage(preview.previewData!),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3.0,
          initialScale: PhotoViewComputedScale.contained,
          heroAttributes: PhotoViewHeroAttributes(tag: preview.fileName),
          loadingBuilder: (context, event) => Center(
            child: CircularProgressIndicator(
              value: event == null
                  ? null
                  : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
            ),
          ),
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),

        // Info overlay at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildInfoOverlay(context),
        ),
      ],
    );
  }

  /// Build info overlay with image details
  Widget _buildInfoOverlay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            colorScheme.surface.withValues(alpha: 0.9),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            preview.fileName,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                preview.formattedSize,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Cached ${preview.cacheAge}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.gesture,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Pinch to zoom',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
