import 'dart:typed_data';

/// Represents a cached file preview
class FilePreview {
  final String identifier;
  final String fileName;
  final PreviewType previewType;
  final String? textContent;
  final Uint8List? previewData;
  final DateTime cachedAt;
  final int? fileSize;

  const FilePreview({
    required this.identifier,
    required this.fileName,
    required this.previewType,
    this.textContent,
    this.previewData,
    required this.cachedAt,
    this.fileSize,
  });

  /// Create FilePreview from database map
  factory FilePreview.fromMap(Map<String, dynamic> map) {
    return FilePreview(
      identifier: map['identifier'] as String,
      fileName: map['file_name'] as String,
      previewType: _parsePreviewType(map['preview_type'] as String),
      textContent: map['text_content'] as String?,
      previewData: map['preview_data'] as Uint8List?,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(map['cached_at'] as int),
      fileSize: map['file_size'] as int?,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'identifier': identifier,
      'file_name': fileName,
      'preview_type': previewType.dbValue,
      'text_content': textContent,
      'preview_data': previewData,
      'cached_at': cachedAt.millisecondsSinceEpoch,
      'file_size': fileSize,
    };
  }

  /// Get human-readable cache age
  String get cacheAge {
    final now = DateTime.now();
    final difference = now.difference(cachedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    }
  }

  /// Get formatted file size
  String get formattedSize {
    if (fileSize == null) return 'Unknown size';

    final bytes = fileSize!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get the size of cached data
  int get cachedDataSize {
    int size = 0;
    if (textContent != null) {
      size += textContent!.length;
    }
    if (previewData != null) {
      size += previewData!.length;
    }
    return size;
  }

  /// Get formatted cached data size
  String get formattedCachedSize {
    final bytes = cachedDataSize;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() {
    return 'FilePreview{fileName: $fileName, type: ${previewType.displayName}, '
        'size: $formattedSize, cached: $cacheAge}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilePreview &&
        other.identifier == identifier &&
        other.fileName == fileName &&
        other.previewType == previewType;
  }

  @override
  int get hashCode {
    return identifier.hashCode ^ fileName.hashCode ^ previewType.hashCode;
  }

  static PreviewType _parsePreviewType(String type) {
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

/// Types of file previews supported
enum PreviewType {
  text('text', 'Text', '📄'),
  image('image', 'Image', '🖼️'),
  document('document', 'Document', '📑'),
  audio('audio', 'Audio', '🎵'),
  video('video', 'Video', '🎬'),
  archive('archive', 'Archive', '📦'),
  audioWaveform('audio_waveform', 'Audio Waveform', '🎵'),
  videoThumbnail('video_thumbnail', 'Video Thumbnail', '🎬'),
  unavailable('unavailable', 'N/A', '❌');

  final String dbValue;
  final String displayName;
  final String icon;

  const PreviewType(this.dbValue, this.displayName, this.icon);

  @override
  String toString() => displayName;
}
