import 'package:flutter/foundation.dart';
import 'archive_metadata.dart';

/// Represents a locally downloaded archive with persistent metadata
@immutable
class DownloadedArchive {
  /// Unique archive identifier
  final String identifier;

  /// Archive metadata (title, creator, description, etc.)
  final ArchiveMetadata metadata;

  /// When this archive was first downloaded
  final DateTime downloadedAt;

  /// Last time this archive was accessed/viewed
  final DateTime lastAccessedAt;

  /// Total number of files in the archive
  final int totalFiles;

  /// Number of files currently downloaded locally
  final int downloadedFiles;

  /// Total size of all files in bytes
  final int totalBytes;

  /// Size of downloaded files in bytes
  final int downloadedBytes;

  /// Local storage path for this archive
  final String localPath;

  /// Individual file download states (filename -> isDownloaded)
  final Map<String, bool> fileStates;

  /// Tags for organizing archives
  final List<String> tags;

  /// User notes about this archive
  final String? notes;

  const DownloadedArchive({
    required this.identifier,
    required this.metadata,
    required this.downloadedAt,
    required this.lastAccessedAt,
    required this.totalFiles,
    required this.downloadedFiles,
    required this.totalBytes,
    required this.downloadedBytes,
    required this.localPath,
    required this.fileStates,
    this.tags = const [],
    this.notes,
  });

  /// Create from JSON
  factory DownloadedArchive.fromJson(Map<String, dynamic> json) {
    return DownloadedArchive(
      identifier: json['identifier'] as String,
      metadata: ArchiveMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      lastAccessedAt: DateTime.parse(json['lastAccessedAt'] as String),
      totalFiles: json['totalFiles'] as int,
      downloadedFiles: json['downloadedFiles'] as int,
      totalBytes: json['totalBytes'] as int,
      downloadedBytes: json['downloadedBytes'] as int,
      localPath: json['localPath'] as String,
      fileStates: Map<String, bool>.from(json['fileStates'] as Map),
      tags: List<String>.from(json['tags'] as List? ?? []),
      notes: json['notes'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'metadata': metadata.toJson(),
      'downloadedAt': downloadedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'totalFiles': totalFiles,
      'downloadedFiles': downloadedFiles,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'localPath': localPath,
      'fileStates': fileStates,
      'tags': tags,
      'notes': notes,
    };
  }

  /// Create from metadata and download completion
  factory DownloadedArchive.fromMetadata({
    required ArchiveMetadata metadata,
    required String localPath,
    required List<String> downloadedFileNames,
  }) {
    final fileStates = <String, bool>{};
    int totalBytes = 0;
    int downloadedBytes = 0;

    for (final file in metadata.files) {
      final isDownloaded = downloadedFileNames.contains(file.name);
      fileStates[file.name] = isDownloaded;

      final fileSize = file.size ?? 0;
      totalBytes += fileSize;
      if (isDownloaded) {
        downloadedBytes += fileSize;
      }
    }

    final now = DateTime.now();
    return DownloadedArchive(
      identifier: metadata.identifier,
      metadata: metadata,
      downloadedAt: now,
      lastAccessedAt: now,
      totalFiles: metadata.files.length,
      downloadedFiles: downloadedFileNames.length,
      totalBytes: totalBytes,
      downloadedBytes: downloadedBytes,
      localPath: localPath,
      fileStates: fileStates,
      tags: const [],
      notes: null,
    );
  }

  /// Copy with updated fields
  DownloadedArchive copyWith({
    String? identifier,
    ArchiveMetadata? metadata,
    DateTime? downloadedAt,
    DateTime? lastAccessedAt,
    int? totalFiles,
    int? downloadedFiles,
    int? totalBytes,
    int? downloadedBytes,
    String? localPath,
    Map<String, bool>? fileStates,
    List<String>? tags,
    String? notes,
  }) {
    return DownloadedArchive(
      identifier: identifier ?? this.identifier,
      metadata: metadata ?? this.metadata,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      totalFiles: totalFiles ?? this.totalFiles,
      downloadedFiles: downloadedFiles ?? this.downloadedFiles,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      localPath: localPath ?? this.localPath,
      fileStates: fileStates ?? this.fileStates,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
    );
  }

  /// Update last accessed time
  DownloadedArchive markAccessed() {
    return copyWith(lastAccessedAt: DateTime.now());
  }

  /// Update file download state
  DownloadedArchive updateFileState(String filename, bool isDownloaded) {
    final newStates = Map<String, bool>.from(fileStates);
    final wasDownloaded = newStates[filename] ?? false;
    newStates[filename] = isDownloaded;

    // Recalculate stats
    int newDownloadedFiles = downloadedFiles;
    int newDownloadedBytes = downloadedBytes;

    if (isDownloaded && !wasDownloaded) {
      // File was downloaded
      newDownloadedFiles++;
      final file = metadata.files.firstWhere((f) => f.name == filename);
      newDownloadedBytes += file.size ?? 0;
    } else if (!isDownloaded && wasDownloaded) {
      // File was deleted
      newDownloadedFiles--;
      final file = metadata.files.firstWhere((f) => f.name == filename);
      newDownloadedBytes -= file.size ?? 0;
    }

    return copyWith(
      fileStates: newStates,
      downloadedFiles: newDownloadedFiles,
      downloadedBytes: newDownloadedBytes,
    );
  }

  /// Calculate download completion percentage
  double get completionPercentage {
    if (totalFiles == 0) return 0.0;
    return downloadedFiles / totalFiles;
  }

  /// Check if archive is fully downloaded
  bool get isComplete => downloadedFiles == totalFiles;

  /// Get human-readable size
  String get formattedTotalSize => _formatBytes(totalBytes);
  String get formattedDownloadedSize => _formatBytes(downloadedBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadedArchive &&
          runtimeType == other.runtimeType &&
          identifier == other.identifier;

  @override
  int get hashCode => identifier.hashCode;

  @override
  String toString() {
    return 'DownloadedArchive{identifier: $identifier, downloadedFiles: $downloadedFiles/$totalFiles, completionPercentage: ${(completionPercentage * 100).toStringAsFixed(1)}%}';
  }
}
