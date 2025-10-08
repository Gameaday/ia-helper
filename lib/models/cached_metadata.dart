import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/archive_metadata.dart';

/// Represents cached archive metadata with versioning and staleness tracking
@immutable
class CachedMetadata {
  /// Unique archive identifier
  final String identifier;

  /// Full archive metadata (serialized to JSON for storage)
  final ArchiveMetadata metadata;

  /// When this cache entry was created
  final DateTime cachedAt;

  /// When this cache entry was last accessed
  final DateTime lastAccessed;

  /// When metadata was last synced from Internet Archive (null = never synced)
  final DateTime? lastSynced;

  /// Cache entry version for migration handling
  final int version;

  /// Whether this archive is pinned (never auto-purge)
  final bool isPinned;

  /// Cached file count for quick access
  final int fileCount;

  /// Cached total size in bytes for quick access
  final int totalSize;

  /// ETag from last HTTP response (for cache validation)
  /// Used with If-None-Match header to check if resource changed
  final String? etag;

  const CachedMetadata({
    required this.identifier,
    required this.metadata,
    required this.cachedAt,
    required this.lastAccessed,
    this.lastSynced,
    this.version = 1,
    this.isPinned = false,
    required this.fileCount,
    required this.totalSize,
    this.etag,
  });

  /// Create from ArchiveMetadata
  factory CachedMetadata.fromMetadata(
    ArchiveMetadata metadata, {
    bool isPinned = false,
    String? etag,
  }) {
    final now = DateTime.now();

    // Calculate total size from files
    int totalSize = 0;
    for (final file in metadata.files) {
      totalSize += file.size ?? 0;
    }

    return CachedMetadata(
      identifier: metadata.identifier,
      metadata: metadata,
      cachedAt: now,
      lastAccessed: now,
      lastSynced: now,
      version: 1,
      isPinned: isPinned,
      fileCount: metadata.files.length,
      totalSize: totalSize,
      etag: etag,
    );
  }

  /// Create from database row
  factory CachedMetadata.fromMap(Map<String, dynamic> map) {
    return CachedMetadata(
      identifier: map['identifier'] as String,
      metadata: ArchiveMetadata.fromJson(
        jsonDecode(map['metadata_json'] as String),
      ),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(map['cached_at'] as int),
      lastAccessed: DateTime.fromMillisecondsSinceEpoch(
        map['last_accessed'] as int,
      ),
      lastSynced: map['last_synced'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_synced'] as int)
          : null,
      version: map['version'] as int,
      isPinned: (map['is_pinned'] as int) == 1,
      fileCount: map['file_count'] as int,
      totalSize: map['total_size'] as int,
      etag: map['etag'] as String?,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'identifier': identifier,
      'metadata_json': jsonEncode(metadata.toJson()),
      'cached_at': cachedAt.millisecondsSinceEpoch,
      'last_accessed': lastAccessed.millisecondsSinceEpoch,
      'last_synced': lastSynced?.millisecondsSinceEpoch,
      'version': version,
      'is_pinned': isPinned ? 1 : 0,
      'file_count': fileCount,
      'total_size': totalSize,
      'creator': metadata.creator,
      'title': metadata.title,
      'media_type': metadata
          .creator, // Using creator as fallback since mediatype doesn't exist
      'etag': etag,
    };
  }

  /// Copy with updated fields
  CachedMetadata copyWith({
    String? identifier,
    ArchiveMetadata? metadata,
    DateTime? cachedAt,
    DateTime? lastAccessed,
    DateTime? lastSynced,
    int? version,
    bool? isPinned,
    int? fileCount,
    int? totalSize,
    String? etag,
  }) {
    return CachedMetadata(
      identifier: identifier ?? this.identifier,
      metadata: metadata ?? this.metadata,
      cachedAt: cachedAt ?? this.cachedAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      lastSynced: lastSynced ?? this.lastSynced,
      version: version ?? this.version,
      isPinned: isPinned ?? this.isPinned,
      fileCount: fileCount ?? this.fileCount,
      totalSize: totalSize ?? this.totalSize,
      etag: etag ?? this.etag,
    );
  }

  /// Mark as accessed (updates last accessed time)
  CachedMetadata markAccessed() {
    return copyWith(lastAccessed: DateTime.now());
  }

  /// Mark as synced (updates last synced time)
  CachedMetadata markSynced() {
    return copyWith(lastSynced: DateTime.now());
  }

  /// Toggle pin status
  CachedMetadata togglePin() {
    return copyWith(isPinned: !isPinned);
  }

  /// Check if cache is stale (needs sync)
  /// Returns true if:
  /// - Never synced
  /// - Last sync was more than maxAge ago
  bool isStale(Duration maxAge) {
    if (lastSynced == null) return true;
    return DateTime.now().difference(lastSynced!) > maxAge;
  }

  /// Check if cache should be purged
  /// Returns true if:
  /// - Not pinned
  /// - Not accessed recently (older than maxAge)
  bool shouldPurge(Duration maxAge) {
    if (isPinned) return false;
    return DateTime.now().difference(lastAccessed) > maxAge;
  }

  /// Get human-readable cache age
  String get cacheAgeString {
    final age = DateTime.now().difference(cachedAt);
    if (age.inDays > 30) return '${age.inDays ~/ 30} month(s) ago';
    if (age.inDays > 0) return '${age.inDays} day(s) ago';
    if (age.inHours > 0) return '${age.inHours} hour(s) ago';
    if (age.inMinutes > 0) return '${age.inMinutes} minute(s) ago';
    return 'Just now';
  }

  /// Get human-readable sync status
  String get syncStatusString {
    if (lastSynced == null) return 'Never synced';
    final age = DateTime.now().difference(lastSynced!);
    if (age.inDays > 30) return 'Synced ${age.inDays ~/ 30} month(s) ago';
    if (age.inDays > 0) return 'Synced ${age.inDays} day(s) ago';
    if (age.inHours > 0) return 'Synced ${age.inHours} hour(s) ago';
    if (age.inMinutes > 0) return 'Synced ${age.inMinutes} minute(s) ago';
    return 'Just synced';
  }

  /// Get human-readable size
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedMetadata &&
          runtimeType == other.runtimeType &&
          identifier == other.identifier &&
          version == other.version;

  @override
  int get hashCode => identifier.hashCode ^ version.hashCode;

  @override
  String toString() {
    return 'CachedMetadata{identifier: $identifier, version: $version, '
        'pinned: $isPinned, files: $fileCount, size: $formattedSize, '
        'cached: $cacheAgeString, sync: $syncStatusString}';
  }
}
