import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:image/image.dart' as img;
import '../models/file_preview.dart';
import '../models/archive_metadata.dart';
import '../database/database_helper.dart';
import 'archive_url_service.dart';

/// Service for managing file previews with caching
///
/// Supports generating and caching previews for various file types:
/// - Text files (txt, md, json, xml, csv, log)
/// - Images (jpg, png, gif, webp, bmp)
/// - Audio (waveform visualization)
/// - Video (thumbnail generation)
class FilePreviewService {
  static final FilePreviewService _instance = FilePreviewService._internal();
  factory FilePreviewService() => _instance;
  FilePreviewService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final ArchiveUrlService _urlService = ArchiveUrlService();

  // File size thresholds for smart downloading
  static const int _cacheAlwaysThreshold = 1024 * 1024; // 1MB
  static const int _cacheWithConfirmationThreshold = 5 * 1024 * 1024; // 5MB

  // Supported file formats
  static const Set<String> _textFormats = {
    'txt',
    'md',
    'markdown',
    'json',
    'xml',
    'csv',
    'log',
    'html',
    'htm',
    'css',
    'js',
    'ts',
    'dart',
    'py',
    'java',
    'c',
    'cpp',
    'h',
    'hpp',
    'rs',
    'go',
    'sh',
    'bat',
    'yaml',
    'yml',
  };

  static const Set<String> _imageFormats = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'svg',
  };

  static const Set<String> _audioFormats = {
    'mp3',
    'wav',
    'ogg',
    'm4a',
    'flac',
    'aac',
  };

  static const Set<String> _videoFormats = {
    'mp4',
    'webm',
    'avi',
    'mov',
    'mkv',
    'flv',
  };

  static const Set<String> _documentFormats = {'pdf'};

  static const Set<String> _archiveFormats = {
    'zip',
    'tar',
    'gz',
    'gzip',
    'bz2',
    'bzip2',
    'xz',
    'tgz',
    'tar.gz',
    'tbz',
    'tbz2',
    'tar.bz2',
    'txz',
    'tar.xz',
    '7z',
    'rar',
    'cab',
    'arj',
    'lzh',
    'ace',
  };

  /// Check if a file format can be previewed
  bool canPreview(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();
    return _textFormats.contains(extension) ||
        _imageFormats.contains(extension) ||
        _audioFormats.contains(extension) ||
        _videoFormats.contains(extension) ||
        _documentFormats.contains(extension) ||
        _archiveFormats.contains(extension);
  }

  /// Determine the preview type based on file extension
  PreviewType getPreviewType(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();

    if (_textFormats.contains(extension)) return PreviewType.text;
    if (_imageFormats.contains(extension)) return PreviewType.image;
    if (_audioFormats.contains(extension)) return PreviewType.audio;
    if (_videoFormats.contains(extension)) return PreviewType.video;
    if (_documentFormats.contains(extension)) return PreviewType.document;
    if (_archiveFormats.contains(extension)) return PreviewType.archive;

    return PreviewType.unavailable;
  }

  /// Check if file should be downloaded before previewing
  ///
  /// Returns true if file is too large and should be downloaded first
  bool shouldDownloadFirst(int fileSize) {
    return fileSize > _cacheWithConfirmationThreshold;
  }

  /// Check if preview should be cached automatically
  ///
  /// Returns false if file is between 1-5MB (requires confirmation)
  bool shouldCacheAutomatically(int fileSize) {
    return fileSize <= _cacheAlwaysThreshold;
  }

  /// Check if a preview is cached
  Future<bool> isPreviewCached(String identifier, String fileName) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'preview_cache',
        where: 'identifier = ? AND file_name = ?',
        whereArgs: [identifier, fileName],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking cached preview: $e');
      return false;
    }
  }

  /// Get cached preview
  Future<FilePreview?> getCachedPreview(
    String identifier,
    String fileName,
  ) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'preview_cache',
        where: 'identifier = ? AND file_name = ?',
        whereArgs: [identifier, fileName],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return FilePreview.fromMap(result.first);
    } catch (e) {
      debugPrint('Error getting cached preview: $e');
      return null;
    }
  }

  /// Generate preview for a file
  ///
  /// This is the main method for creating previews.
  /// It will:
  /// 1. Check if preview is already cached
  /// 2. Determine preview type
  /// 3. Download necessary data
  /// 4. Generate preview
  /// 5. Cache the preview
  Future<FilePreview> generatePreview(
    String identifier,
    ArchiveFile file, {
    bool forceRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh) {
      final cached = await getCachedPreview(identifier, file.name);
      if (cached != null) {
        return cached;
      }
    }

    // Determine preview type
    final previewType = getPreviewType(file.name);

    if (previewType == PreviewType.unavailable) {
      throw UnsupportedError('Preview not available for ${file.name}');
    }

    // Check file size
    if (shouldDownloadFirst(file.size ?? 0)) {
      throw FileTooLargeException(
        'File too large (${_formatBytes(file.size ?? 0)}). '
        'Please download first.',
      );
    }

    // Generate preview based on type
    FilePreview preview;
    switch (previewType) {
      case PreviewType.text:
        preview = await _generateTextPreview(identifier, file);
        break;
      case PreviewType.image:
        preview = await _generateImagePreview(identifier, file);
        break;
      case PreviewType.document:
        preview = await _generateDocumentPreview(identifier, file);
        break;
      case PreviewType.audio:
        preview = await _generateAudioPreview(identifier, file);
        break;
      case PreviewType.video:
        preview = await _generateVideoPreview(identifier, file);
        break;
      case PreviewType.archive:
        preview = await _generateArchivePreview(identifier, file);
        break;
      case PreviewType.audioWaveform:
      case PreviewType.videoThumbnail:
      case PreviewType.unavailable:
        throw UnsupportedError('Preview not available');
    }

    // Cache the preview
    await cachePreview(preview);

    return preview;
  }

  /// Cache a preview
  Future<void> cachePreview(FilePreview preview) async {
    try {
      final db = await _db.database;
      await db.insert(
        'preview_cache',
        preview.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Cached preview: ${preview.fileName}');
    } catch (e) {
      debugPrint('Error caching preview: $e');
      rethrow;
    }
  }

  /// Delete a cached preview
  Future<void> deleteCachedPreview(String identifier, String fileName) async {
    try {
      final db = await _db.database;
      await db.delete(
        'preview_cache',
        where: 'identifier = ? AND file_name = ?',
        whereArgs: [identifier, fileName],
      );
      debugPrint('Deleted cached preview: $fileName');
    } catch (e) {
      debugPrint('Error deleting cached preview: $e');
    }
  }

  /// Clear all cached previews
  Future<int> clearAllPreviews() async {
    try {
      final db = await _db.database;
      final count = await db.delete('preview_cache');
      debugPrint('Cleared $count cached previews');
      return count;
    } catch (e) {
      debugPrint('Error clearing previews: $e');
      return 0;
    }
  }

  /// Clear previews for a specific archive
  Future<int> clearArchivePreviews(String identifier) async {
    try {
      final db = await _db.database;
      final count = await db.delete(
        'preview_cache',
        where: 'identifier = ?',
        whereArgs: [identifier],
      );
      debugPrint('Cleared $count previews for archive: $identifier');
      return count;
    } catch (e) {
      debugPrint('Error clearing archive previews: $e');
      return 0;
    }
  }

  /// Get preview cache statistics
  Future<PreviewCacheStats> getCacheStats() async {
    try {
      final db = await _db.database;

      // Count total previews
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM preview_cache',
      );
      final totalPreviews = countResult.first['count'] as int? ?? 0;

      // Count by type
      final typeResult = await db.rawQuery('''
        SELECT preview_type, COUNT(*) as count 
        FROM preview_cache 
        GROUP BY preview_type
      ''');

      final typeBreakdown = <PreviewType, int>{};
      for (final row in typeResult) {
        final type = _parsePreviewType(row['preview_type'] as String);
        typeBreakdown[type] = row['count'] as int? ?? 0;
      }

      // Calculate cache size (approximate)
      final sizeResult = await db.rawQuery('''
        SELECT 
          SUM(LENGTH(text_content)) as text_size,
          SUM(LENGTH(preview_data)) as blob_size
        FROM preview_cache
      ''');

      final textSize = sizeResult.first['text_size'] as int? ?? 0;
      final blobSize = sizeResult.first['blob_size'] as int? ?? 0;
      final totalSize = textSize + blobSize;

      return PreviewCacheStats(
        totalPreviews: totalPreviews,
        totalSize: totalSize,
        typeBreakdown: typeBreakdown,
      );
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return const PreviewCacheStats(
        totalPreviews: 0,
        totalSize: 0,
        typeBreakdown: {},
      );
    }
  }

  // Private helper methods

  /// Generate text preview for a file
  ///
  /// Downloads text content via HTTP and creates a preview.
  /// Truncates content if larger than 1MB to prevent memory issues.
  Future<FilePreview> _generateTextPreview(
    String identifier,
    ArchiveFile file,
  ) async {
    try {
      // Construct download URL using centralized service
      final url = Uri.parse(_urlService.getDownloadUrl(identifier, file.name));

      debugPrint('Downloading text preview: $url');

      // Download content with timeout
      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Preview download timed out');
            },
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download preview: HTTP ${response.statusCode}',
        );
      }

      // Get content as string
      String content;
      try {
        // Try UTF-8 decoding first
        content = utf8.decode(response.bodyBytes);
      } catch (e) {
        // Fallback to Latin-1 if UTF-8 fails
        content = latin1.decode(response.bodyBytes);
      }

      // Truncate if content is too large (>1MB of text)
      const maxTextSize = 1024 * 1024; // 1MB
      if (content.length > maxTextSize) {
        content = content.substring(0, maxTextSize);
        content += '\n\n... (Content truncated at 1MB)';
        debugPrint('Text content truncated at 1MB');
      }

      // Create preview
      return FilePreview(
        identifier: identifier,
        fileName: file.name,
        previewType: PreviewType.text,
        textContent: content,
        cachedAt: DateTime.now(),
        fileSize: file.size,
      );
    } catch (e) {
      debugPrint('Error generating text preview: $e');
      rethrow;
    }
  }

  /// Generate image preview for a file
  ///
  /// Downloads image via HTTP, resizes to max 800x800px, and compresses.
  /// Stores compressed image data as BLOB in database.
  Future<FilePreview> _generateImagePreview(
    String identifier,
    ArchiveFile file,
  ) async {
    try {
      // Construct download URL using centralized service
      final url = Uri.parse(_urlService.getDownloadUrl(identifier, file.name));

      debugPrint('Downloading image preview: $url');

      // Download image with timeout
      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw TimeoutException('Image preview download timed out');
            },
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download image: HTTP ${response.statusCode}',
        );
      }

      // Decode image
      img.Image? image = img.decodeImage(response.bodyBytes);
      if (image == null) {
        throw Exception('Failed to decode image: ${file.name}');
      }

      debugPrint('Original image size: ${image.width}x${image.height}');

      // Resize if larger than 800x800
      const maxDimension = 800;
      if (image.width > maxDimension || image.height > maxDimension) {
        // Calculate new dimensions maintaining aspect ratio
        int newWidth;
        int newHeight;

        if (image.width > image.height) {
          newWidth = maxDimension;
          newHeight = (image.height * maxDimension / image.width).round();
        } else {
          newHeight = maxDimension;
          newWidth = (image.width * maxDimension / image.height).round();
        }

        // Resize image
        image = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );

        debugPrint('Resized image to: ${image.width}x${image.height}');
      }

      // Compress to JPEG with quality 85
      final jpegBytes = Uint8List.fromList(img.encodeJpg(image, quality: 85));

      debugPrint('Compressed image size: ${_formatBytes(jpegBytes.length)}');

      // Create preview
      return FilePreview(
        identifier: identifier,
        fileName: file.name,
        previewType: PreviewType.image,
        previewData: jpegBytes,
        cachedAt: DateTime.now(),
        fileSize: file.size,
      );
    } catch (e) {
      debugPrint('Error generating image preview: $e');
      rethrow;
    }
  }

  /// Generate PDF document preview
  ///
  /// Downloads PDF file via HTTP and stores raw PDF data for rendering.
  /// PDF rendering is handled by the PdfPreviewWidget.
  Future<FilePreview> _generateDocumentPreview(
    String identifier,
    ArchiveFile file,
  ) async {
    try {
      // Construct download URL using centralized service
      final url = Uri.parse(_urlService.getDownloadUrl(identifier, file.name));

      debugPrint('Downloading PDF preview: $url');

      // Download PDF with timeout
      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 120),
            onTimeout: () {
              throw TimeoutException('PDF preview download timed out');
            },
          );

      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
      }

      final pdfBytes = response.bodyBytes;

      debugPrint('Downloaded PDF size: ${_formatBytes(pdfBytes.length)}');

      // Validate that it's actually a PDF (check magic bytes)
      if (pdfBytes.length < 4 ||
          pdfBytes[0] != 0x25 || // %
          pdfBytes[1] != 0x50 || // P
          pdfBytes[2] != 0x44 || // D
          pdfBytes[3] != 0x46) {
        // F
        throw Exception('Invalid PDF file format');
      }

      // Create preview with raw PDF data
      return FilePreview(
        identifier: identifier,
        fileName: file.name,
        previewType: PreviewType.document,
        previewData: pdfBytes,
        cachedAt: DateTime.now(),
        fileSize: file.size,
      );
    } catch (e) {
      debugPrint('Error generating PDF preview: $e');
      rethrow;
    }
  }

  Future<FilePreview> _generateAudioPreview(
    String identifier,
    ArchiveFile file,
  ) async {
    try {
      // Construct download URL
      final url = Uri.parse(_urlService.getDownloadUrl(identifier, file.name));

      debugPrint('Downloading audio preview: $url');

      // Download audio with timeout
      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 120),
            onTimeout: () {
              throw TimeoutException('Audio preview download timed out');
            },
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download audio: HTTP ${response.statusCode}',
        );
      }

      final audioBytes = response.bodyBytes;

      debugPrint('Downloaded audio size: ${_formatBytes(audioBytes.length)}');

      // Create preview with raw audio data
      return FilePreview(
        identifier: identifier,
        fileName: file.name,
        previewType: PreviewType.audio,
        previewData: audioBytes,
        cachedAt: DateTime.now(),
        fileSize: file.size,
      );
    } catch (e) {
      debugPrint('Error generating audio preview: $e');
      rethrow;
    }
  }

  /// Generate preview for video files
  ///
  /// Downloads video file from Internet Archive for playback.
  /// Uses longer timeout for potentially large video files.
  Future<FilePreview> _generateVideoPreview(
    String identifier,
    ArchiveFile file,
  ) async {
    try {
      debugPrint('Generating video preview for: ${file.name}');

      // Construct download URL using centralized service
      final url = Uri.parse(_urlService.getDownloadUrl(identifier, file.name));

      debugPrint('Downloading video preview: $url');

      // Download video with longer timeout for large files
      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 180), // 3 minutes for large videos
            onTimeout: () {
              throw TimeoutException('Video preview download timed out');
            },
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download video: HTTP ${response.statusCode}',
        );
      }

      final videoBytes = response.bodyBytes;

      debugPrint('Downloaded video size: ${_formatBytes(videoBytes.length)}');

      // Create preview with raw video data
      return FilePreview(
        identifier: identifier,
        fileName: file.name,
        previewType: PreviewType.video,
        previewData: videoBytes,
        cachedAt: DateTime.now(),
        fileSize: file.size,
      );
    } catch (e) {
      debugPrint('Error generating video preview: $e');
      rethrow;
    }
  }

  Future<FilePreview> _generateArchivePreview(
    String identifier,
    ArchiveFile file,
  ) async {
    try {
      debugPrint('Generating archive preview for: ${file.name}');

      // Construct download URL using centralized service
      final url = Uri.parse(_urlService.getDownloadUrl(identifier, file.name));

      debugPrint('Downloading archive preview: $url');

      // Download archive with longer timeout for large files
      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 180), // 3 minutes for large archives
            onTimeout: () {
              throw TimeoutException('Archive preview download timed out');
            },
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download archive: HTTP ${response.statusCode}',
        );
      }

      final archiveBytes = response.bodyBytes;

      debugPrint(
        'Downloaded archive size: ${_formatBytes(archiveBytes.length)}',
      );

      // Create preview with raw archive data
      return FilePreview(
        identifier: identifier,
        fileName: file.name,
        previewType: PreviewType.archive,
        previewData: archiveBytes,
        cachedAt: DateTime.now(),
        fileSize: file.size,
      );
    } catch (e) {
      debugPrint('Error generating archive preview: $e');
      rethrow;
    }
  }

  String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1 || lastDot == fileName.length - 1) {
      return '';
    }
    return fileName.substring(lastDot + 1);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  PreviewType _parsePreviewType(String type) {
    switch (type) {
      case 'text':
        return PreviewType.text;
      case 'image':
        return PreviewType.image;
      case 'audio_waveform':
        return PreviewType.audioWaveform;
      case 'video_thumbnail':
        return PreviewType.videoThumbnail;
      default:
        return PreviewType.unavailable;
    }
  }
}

/// Exception thrown when file is too large for preview
class FileTooLargeException implements Exception {
  final String message;
  FileTooLargeException(this.message);

  @override
  String toString() => message;
}

/// Preview cache statistics
class PreviewCacheStats {
  final int totalPreviews;
  final int totalSize;
  final Map<PreviewType, int> typeBreakdown;

  const PreviewCacheStats({
    required this.totalPreviews,
    required this.totalSize,
    required this.typeBreakdown,
  });

  String get formattedSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    }
    if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  int get textCount => typeBreakdown[PreviewType.text] ?? 0;
  int get imageCount => typeBreakdown[PreviewType.image] ?? 0;
  int get audioCount => typeBreakdown[PreviewType.audioWaveform] ?? 0;
  int get videoCount => typeBreakdown[PreviewType.videoThumbnail] ?? 0;

  @override
  String toString() {
    return 'PreviewCacheStats{total: $totalPreviews, '
        'size: $formattedSize, '
        'text: $textCount, images: $imageCount, '
        'audio: $audioCount, video: $videoCount}';
  }
}
