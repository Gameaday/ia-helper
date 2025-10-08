import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/file_preview.dart';
import '../services/file_preview_service.dart';
import '../models/archive_metadata.dart';
import 'text_preview_widget.dart';
import 'image_preview_widget.dart';
import 'pdf_preview_widget.dart';
import 'audio_preview_widget.dart';
import 'video_preview_widget.dart';
import 'archive_preview_widget.dart';

/// Helper class to hold error information for enhanced error displays
class _ErrorInfo {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? technicalDetails;
  final List<String> tips;

  _ErrorInfo({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.technicalDetails,
    required this.tips,
  });
}

/// Full-screen dialog for displaying file previews with swipe navigation
/// 
/// Automatically chooses the correct preview widget based on file type,
/// provides loading, error, and retry functionality, and allows swiping
/// between multiple files.
class PreviewDialog extends StatefulWidget {
  final String identifier;
  final List<ArchiveFile> files;
  final int initialIndex;

  const PreviewDialog({
    super.key,
    required this.identifier,
    required this.files,
    this.initialIndex = 0,
  });

  /// Show preview dialog with swipe navigation
  static Future<void> show(
    BuildContext context,
    String identifier,
    List<ArchiveFile> files,
    int initialIndex,
  ) {
    return showDialog(
      context: context,
      builder: (context) => PreviewDialog(
        identifier: identifier,
        files: files,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  State<PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<PreviewDialog> {
  final FilePreviewService _previewService = FilePreviewService();
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, Future<FilePreview>> _previewCache = {};
  final Map<int, bool> _forceRefreshMap = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Preload current, previous, and next previews
    _loadPreview(_currentIndex);
    if (_currentIndex > 0) {
      _loadPreview(_currentIndex - 1);
    }
    if (_currentIndex < widget.files.length - 1) {
      _loadPreview(_currentIndex + 1);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<FilePreview> _loadPreview(int index) {
    if (_previewCache.containsKey(index) && !(_forceRefreshMap[index] ?? false)) {
      return _previewCache[index]!;
    }

    final file = widget.files[index];
    final future = _previewService.generatePreview(
      widget.identifier,
      file,
      forceRefresh: _forceRefreshMap[index] ?? false,
    );
    
    _previewCache[index] = future;
    _forceRefreshMap[index] = false;
    
    return future;
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Preload adjacent pages
    if (index > 0 && !_previewCache.containsKey(index - 1)) {
      _loadPreview(index - 1);
    }
    if (index < widget.files.length - 1 && !_previewCache.containsKey(index + 1)) {
      _loadPreview(index + 1);
    }
  }

  void _retry() {
    setState(() {
      _forceRefreshMap[_currentIndex] = true;
      _previewCache.remove(_currentIndex);
    });
  }

  /// Share the current preview
  Future<void> _sharePreview() async {
    try {
      final preview = await _loadPreview(_currentIndex);
      
      switch (preview.previewType) {
        case PreviewType.text:
          await _shareText(preview);
          break;
        case PreviewType.image:
          await _shareImage(preview);
          break;
        case PreviewType.document:
          _showShareError('PDF sharing coming soon');
          break;
        case PreviewType.audio:
          _showShareError('Audio sharing coming soon');
          break;
        case PreviewType.video:
          _showShareError('Video sharing coming soon');
          break;
        case PreviewType.archive:
          _showShareError('Archive sharing coming soon');
          break;
        default:
          _showShareError('Sharing not available for this file type');
      }
    } catch (e) {
      _showShareError('Failed to share: $e');
    }
  }

  /// Share text content
  Future<void> _shareText(FilePreview preview) async {
    if (preview.textContent == null || preview.textContent!.isEmpty) {
      _showShareError('No text content to share');
      return;
    }

    // share_plus v12+ uses ShareParams
    await SharePlus.instance.share(ShareParams(
      text: preview.textContent!,
    ));
  }

  /// Share image content
  Future<void> _shareImage(FilePreview preview) async {
    if (preview.previewData == null || preview.previewData!.isEmpty) {
      _showShareError('No image data to share');
      return;
    }

    // Create XFile from bytes
    final xFile = XFile.fromData(
      preview.previewData!,
      name: preview.fileName,
      mimeType: 'image/jpeg',
    );

    // share_plus v12+ uses ShareParams with files
    await SharePlus.instance.share(ShareParams(
      files: [xFile],
    ));
  }

  /// Show share error message
  void _showShareError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  ArchiveFile get _currentFile => widget.files[_currentIndex];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentFile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
              if (widget.files.length > 1)
                Text(
                  '${_currentIndex + 1} of ${widget.files.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.7),
                      ),
                ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close preview',
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            // Share button
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share preview',
              onPressed: _sharePreview,
            ),
            // Refresh button
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh preview',
              onPressed: _retry,
            ),
          ],
        ),
        body: widget.files.length == 1
            ? _buildSinglePreview(isDarkMode)
            : PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: widget.files.length,
                itemBuilder: (context, index) {
                  return _buildPreviewPage(index, isDarkMode);
                },
              ),
      ),
    );
  }

  /// Build single file preview (no swipe)
  Widget _buildSinglePreview(bool isDarkMode) {
    return FutureBuilder<FilePreview>(
      future: _loadPreview(0),
      builder: (context, snapshot) {
        return _buildPreviewState(snapshot, isDarkMode);
      },
    );
  }

  /// Build preview page for PageView
  Widget _buildPreviewPage(int index, bool isDarkMode) {
    return FutureBuilder<FilePreview>(
      future: _loadPreview(index),
      builder: (context, snapshot) {
        return _buildPreviewState(snapshot, isDarkMode);
      },
    );
  }

  /// Build preview state (loading, error, or content)
  Widget _buildPreviewState(
      AsyncSnapshot<FilePreview> snapshot, bool isDarkMode) {
    // Loading state
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingState();
    }

    // Error state
    if (snapshot.hasError) {
      return _buildErrorState(snapshot.error!);
    }

    // Success state
    if (snapshot.hasData) {
      return _buildPreviewContent(snapshot.data!, isDarkMode);
    }

    // Empty state
    return const Center(
      child: Text('No preview available'),
    );
  }

  /// Build loading state with enhanced animations
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading indicator
          SpinKitFadingCircle(
            color: Theme.of(context).primaryColor,
            size: 60.0,
          ),
          const SizedBox(height: 24),
          
          // Loading message
          Text(
            'Generating preview...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          
          // File name with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _currentFile.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'This may take a moment for large files',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state with enhanced messaging
  Widget _buildErrorState(Object error) {
    // Check if this is a FileTooLargeException
    if (error is FileTooLargeException) {
      return _buildLargeFilePrompt(error);
    }

    // Determine error type and message
    final errorInfo = _analyzeError(error);

    // Enhanced error display
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon with color based on severity
            Icon(
              errorInfo.icon,
              size: 72,
              color: errorInfo.color,
            ),
            const SizedBox(height: 20),
            
            // Error title
            Text(
              errorInfo.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Error message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: errorInfo.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: errorInfo.color.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    errorInfo.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (errorInfo.technicalDetails != null) ...[
                    const SizedBox(height: 12),
                    ExpansionTile(
                      title: Text(
                        'Technical Details',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            errorInfo.technicalDetails!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            Column(
              children: [
                // Primary action - Retry
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Secondary actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Close'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _reportIssue,
                        icon: const Icon(Icons.bug_report, size: 18),
                        label: const Text('Report'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Helpful tips
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Troubleshooting Tips',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...errorInfo.tips.map((tip) => Padding(
                        padding: const EdgeInsets.only(left: 24, top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                tip,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Analyze error and provide helpful information
  _ErrorInfo _analyzeError(Object error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('failed host lookup') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return _ErrorInfo(
        icon: Icons.wifi_off,
        color: Theme.of(context).colorScheme.error,
        title: 'Connection Error',
        message: 'Unable to download file for preview. Please check your internet connection.',
        technicalDetails: error.toString(),
        tips: [
          'Check your WiFi or mobile data connection',
          'Try again in a moment',
          'Some files may require a stable connection',
        ],
      );
    }

    // Timeout errors
    if (errorString.contains('timeout')) {
      return _ErrorInfo(
        icon: Icons.access_time,
        color: Theme.of(context).colorScheme.error,
        title: 'Request Timeout',
        message: 'The preview is taking too long to generate. The file might be very large or the server is slow.',
        technicalDetails: error.toString(),
        tips: [
          'Try again with a better connection',
          'Consider downloading the file instead',
          'Large files may need more time',
        ],
      );
    }

    // Format/parsing errors
    if (errorString.contains('format') ||
        errorString.contains('parse') ||
        errorString.contains('decode')) {
      return _ErrorInfo(
        icon: Icons.broken_image,
        color: Theme.of(context).colorScheme.error,
        title: 'Invalid File Format',
        message: 'This file format is not supported for preview or the file is corrupted.',
        technicalDetails: error.toString(),
        tips: [
          'Try downloading the file to view it',
          'The file might be corrupted',
          'Some formats are not yet supported',
        ],
      );
    }

    // Unsupported errors
    if (errorString.contains('unsupported')) {
      return _ErrorInfo(
        icon: Icons.visibility_off,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        title: 'Preview Not Available',
        message: 'Preview is not available for this file type.',
        technicalDetails: error.toString(),
        tips: [
          'Download the file to view it',
          'Preview support varies by file type',
          'More formats coming in future updates',
        ],
      );
    }

    // Generic error
    return _ErrorInfo(
      icon: Icons.error_outline,
      color: Theme.of(context).colorScheme.error,
      title: 'Preview Failed',
      message: 'An unexpected error occurred while generating the preview.',
      technicalDetails: error.toString(),
      tips: [
        'Try refreshing the preview',
        'Check your internet connection',
        'Report this if it persists',
      ],
    );
  }

  /// Report issue to user (placeholder)
  void _reportIssue() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Issue reporting coming soon! Please contact support.'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Build large file prompt
  Widget _buildLargeFilePrompt(FileTooLargeException exception) {
    final file = _currentFile;
    final fileSize = _formatBytes(file.size ?? 0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Warning icon
            Icon(
              Icons.warning_amber_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Large File',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // File info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        size: 20,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          file.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fileSize,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Description
            Text(
              'This file is too large to preview directly.\n'
              'Please download it first to view its contents.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Action buttons
            Column(
              children: [
                // Download button (primary action)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _triggerFileDownload(file);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download File'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
            
            // Tip
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Files larger than 5MB require downloading before preview',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
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

  /// Trigger file download using snackbar
  /// 
  /// This shows a message to the user that the file download has been initiated.
  /// The actual download is handled by the file list widget's download functionality.
  void _triggerFileDownload(ArchiveFile file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please use the download button in the file list to download ${file.name}'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Build preview content based on type
  Widget _buildPreviewContent(FilePreview preview, bool isDarkMode) {
    switch (preview.previewType) {
      case PreviewType.text:
        return TextPreviewWidget(
          preview: preview,
          isDarkMode: isDarkMode,
        );

      case PreviewType.image:
        return ImagePreviewWidget(
          preview: preview,
        );

      case PreviewType.document:
        if (preview.previewData != null && preview.previewData!.isNotEmpty) {
          return PdfPreviewWidget(
            pdfBytes: preview.previewData!,
            fileName: preview.fileName,
          );
        }
        return _buildUnsupportedPreview('PDF data not available');

      case PreviewType.audio:
        if (preview.previewData != null && preview.previewData!.isNotEmpty) {
          return AudioPreviewWidget(
            audioBytes: preview.previewData!,
            fileName: preview.fileName,
          );
        }
        return _buildUnsupportedPreview('Audio data not available');

      case PreviewType.video:
        if (preview.previewData != null && preview.previewData!.isNotEmpty) {
          return VideoPreviewWidget(
            videoBytes: preview.previewData!,
            fileName: preview.fileName,
          );
        }
        return _buildUnsupportedPreview('Video data not available');

      case PreviewType.archive:
        if (preview.previewData != null && preview.previewData!.isNotEmpty) {
          return ArchivePreviewWidget(
            archiveBytes: preview.previewData!,
            fileName: preview.fileName,
            fileSize: preview.fileSize,
          );
        }
        return _buildUnsupportedPreview('Archive data not available');

      case PreviewType.audioWaveform:
        return _buildUnsupportedPreview('Audio waveform coming soon');

      case PreviewType.videoThumbnail:
        return _buildUnsupportedPreview('Video thumbnail preview');

      case PreviewType.unavailable:
        return _buildUnsupportedPreview('Preview not available for this file type');
    }
  }

  /// Build unsupported preview type message
  Widget _buildUnsupportedPreview(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
