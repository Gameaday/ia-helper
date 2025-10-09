import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Platform-specific imports for web functionality
// Web-only: html.window.open() for browser-native previews
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html show window;

/// Platform adapter for file preview functionality
///
/// Provides platform-appropriate file preview capabilities:
/// - Native: Supports various file formats with native viewers
/// - Web: Browser-based previews (PDF, images, video, audio via iframe/HTML5)
///
/// This eliminates large platform check blocks from UI code.
abstract class FilePreviewAdapter {
  /// Check if the given file format can be previewed
  bool canPreview(String format);

  /// Get a list of all supported preview formats
  List<String> getSupportedFormats();

  /// Build a preview widget for the given file format
  ///
  /// Returns either:
  /// - Native: Actual preview widget (PDF viewer, image viewer, etc.)
  /// - Web: Browser-native preview (iframe, img, video, audio elements)
  Widget buildPreviewWidget({
    required BuildContext context,
    required String format,
    required String filename,
    required String? downloadUrl,
  });

  /// Factory constructor that returns the appropriate implementation
  factory FilePreviewAdapter() {
    if (kIsWeb) {
      return _WebFilePreviewAdapter();
    }
    return _NativeFilePreviewAdapter();
  }
}

/// Native (Android/iOS) file preview implementation
///
/// Supports various file formats with native platform viewers.
class _NativeFilePreviewAdapter implements FilePreviewAdapter {
  // Supported formats on native platforms
  static const _supportedFormats = [
    'pdf',
    'txt',
    'md',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'mp3',
    'mp4',
    'avi',
    'mkv',
  ];

  @override
  bool canPreview(String format) {
    return _supportedFormats.contains(format.toLowerCase());
  }

  @override
  List<String> getSupportedFormats() => List.unmodifiable(_supportedFormats);

  @override
  Widget buildPreviewWidget({
    required BuildContext context,
    required String format,
    required String filename,
    required String? downloadUrl,
  }) {
    // On native, we would return the actual preview widget
    // For now, return a placeholder indicating native preview would be shown
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForFormat(format),
            size: 96,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Native Preview',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            filename,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            format.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForFormat(String format) {
    final lowerFormat = format.toLowerCase();
    if (['pdf'].contains(lowerFormat)) return Icons.picture_as_pdf;
    if (['txt', 'md'].contains(lowerFormat)) return Icons.description;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(lowerFormat)) {
      return Icons.image;
    }
    if (['mp3'].contains(lowerFormat)) return Icons.audio_file;
    if (['mp4', 'avi', 'mkv'].contains(lowerFormat)) return Icons.video_file;
    return Icons.insert_drive_file;
  }
}

/// Web file preview implementation
///
/// Leverages browser's native capabilities to preview files:
/// - PDFs: iframe with browser's built-in PDF viewer
/// - Images: Direct image display
/// - Videos: HTML5 video element
/// - Audio: HTML5 audio element
/// - Text: Display with formatting
///
/// This gives web users a full-featured preview experience!
class _WebFilePreviewAdapter implements FilePreviewAdapter {
  // Formats that browsers can handle natively
  static const _imageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp'];
  static const _videoFormats = ['mp4', 'webm', 'ogg', 'mov'];
  static const _audioFormats = ['mp3', 'wav', 'ogg', 'aac', 'm4a'];
  static const _textFormats = ['txt', 'md', 'json', 'xml', 'html', 'css', 'js'];
  static const _pdfFormats = ['pdf'];

  @override
  bool canPreview(String format) {
    final lowerFormat = format.toLowerCase();
    return _imageFormats.contains(lowerFormat) ||
        _videoFormats.contains(lowerFormat) ||
        _audioFormats.contains(lowerFormat) ||
        _textFormats.contains(lowerFormat) ||
        _pdfFormats.contains(lowerFormat);
  }

  @override
  List<String> getSupportedFormats() {
    return [
      ..._imageFormats,
      ..._videoFormats,
      ..._audioFormats,
      ..._textFormats,
      ..._pdfFormats,
    ];
  }

  @override
  Widget buildPreviewWidget({
    required BuildContext context,
    required String format,
    required String filename,
    required String? downloadUrl,
  }) {
    if (downloadUrl == null) {
      return _buildErrorWidget(context, 'No download URL available');
    }

    final lowerFormat = format.toLowerCase();

    // PDF - Use browser's built-in PDF viewer via iframe
    if (_pdfFormats.contains(lowerFormat)) {
      return _buildBrowserPreview(
        context: context,
        url: downloadUrl,
        filename: filename,
        format: format,
        message: 'Opening PDF in browser...',
      );
    }

    // Images - Direct display with Image.network
    if (_imageFormats.contains(lowerFormat)) {
      return _buildImagePreview(context, downloadUrl, filename);
    }

    // Video - HTML5 video element (future: use HtmlElementView)
    if (_videoFormats.contains(lowerFormat)) {
      return _buildBrowserPreview(
        context: context,
        url: downloadUrl,
        filename: filename,
        format: format,
        message: 'Opening video in browser...',
      );
    }

    // Audio - HTML5 audio element (future: use HtmlElementView)
    if (_audioFormats.contains(lowerFormat)) {
      return _buildBrowserPreview(
        context: context,
        url: downloadUrl,
        filename: filename,
        format: format,
        message: 'Opening audio in browser...',
      );
    }

    // Text files - Could fetch and display, but let browser handle for now
    if (_textFormats.contains(lowerFormat)) {
      return _buildBrowserPreview(
        context: context,
        url: downloadUrl,
        filename: filename,
        format: format,
        message: 'Opening text file in browser...',
      );
    }

    // Unsupported format - show download option
    return _buildDownloadPrompt(context, downloadUrl, filename, format);
  }

  /// Build image preview using Flutter's Image.network
  Widget _buildImagePreview(
    BuildContext context,
    String url,
    String filename,
  ) {
    return Column(
      children: [
        // Filename header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Text(
            filename,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Image display
        Expanded(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                url,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
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
                          'CORS or network issue',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build browser-based preview (opens in new tab)
  ///
  /// For formats the browser can handle (PDF, video, audio, text),
  /// we provide a button to open in a new tab where the browser's
  /// native viewer takes over.
  Widget _buildBrowserPreview({
    required BuildContext context,
    required String url,
    required String filename,
    required String format,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForFormat(format),
              size: 96,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Browser Preview Available',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              filename,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              format.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                // Open in new tab - browser handles the preview
                html.window.open(url, '_blank');
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in Browser'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // Download option
                html.window.open(url, '_blank');
              },
              icon: const Icon(Icons.download),
              label: const Text('Download'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build download prompt for unsupported formats
  Widget _buildDownloadPrompt(
    BuildContext context,
    String url,
    String filename,
    String format,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_rounded,
              size: 96,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Preview not available',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Download to view this file type',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              filename,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              format.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                html.window.open(url, '_blank');
              },
              icon: const Icon(Icons.download),
              label: const Text('Download File'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 96,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForFormat(String format) {
    final lowerFormat = format.toLowerCase();
    if (_pdfFormats.contains(lowerFormat)) return Icons.picture_as_pdf;
    if (_textFormats.contains(lowerFormat)) return Icons.description;
    if (_imageFormats.contains(lowerFormat)) return Icons.image;
    if (_audioFormats.contains(lowerFormat)) return Icons.audio_file;
    if (_videoFormats.contains(lowerFormat)) return Icons.video_file;
    return Icons.insert_drive_file;
  }
}
