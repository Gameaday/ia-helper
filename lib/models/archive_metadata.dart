import '../services/archive_url_service.dart';

/// Archive metadata model
class ArchiveMetadata {
  final String identifier;
  final String? title;
  final String? description;
  final String? creator;
  final String? date;
  final int totalFiles;
  final int totalSize;
  final int? filesCount;
  final int? itemLastUpdated;
  final List<ArchiveFile> files;
  final String? thumbnailUrl;
  final String? coverImageUrl;
  final String? mediaType;
  final int? downloads;
  final double? rating;
  final List<String> archiveOrgCollections; // Archive.org collections this item belongs to

  ArchiveMetadata({
    required this.identifier,
    this.title,
    this.description,
    this.creator,
    this.date,
    required this.totalFiles,
    required this.totalSize,
    this.filesCount,
    this.itemLastUpdated,
    required this.files,
    this.thumbnailUrl,
    this.coverImageUrl,
    this.mediaType,
    this.downloads,
    this.rating,
    this.archiveOrgCollections = const [],
  });

  factory ArchiveMetadata.fromJson(Map<String, dynamic> json) {
    // Archive.org returns empty {} for non-existent items
    // Detect this early and throw a meaningful exception
    if (json.isEmpty || 
        (!json.containsKey('metadata') && !json.containsKey('files') && !json.containsKey('created'))) {
      throw const FormatException('Archive item not found or empty response');
    }

    final filesList = json['files'] as List<dynamic>? ?? [];
    final server = json['server'] as String? ?? json['d1'] as String? ?? '';
    final dir = json['dir'] as String? ?? '';

    final files = filesList.map((file) {
      final fileMap = file as Map<String, dynamic>;
      // Generate download URL from server and directory if not present
      if (fileMap['download_url'] == null &&
          server.isNotEmpty &&
          dir.isNotEmpty) {
        final fileName = fileMap['name'] as String? ?? '';
        fileMap['download_url'] = 'https://$server$dir/$fileName';
      }
      return ArchiveFile.fromJson(fileMap);
    }).toList();

    // Try multiple strategies to extract identifier
    String identifier = 'unknown';

    // Strategy 1: Check metadata.identifier
    if (json['metadata'] != null && json['metadata']['identifier'] != null) {
      identifier = json['metadata']['identifier'];
    }
    // Strategy 2: Check top-level identifier
    else if (json['identifier'] != null) {
      identifier = json['identifier'];
    }
    // Strategy 3: Extract from directory path (e.g., /21/items/commute_test -> commute_test)
    else if (dir.isNotEmpty) {
      final parts = dir.split('/').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        // Directory format is usually /digits/items/identifier
        identifier = parts.last;
      }
    }

    // Singleton URL service instance
    final urlService = ArchiveUrlService();

    // Extract thumbnail URLs
    String? thumbnailUrl;
    String? coverImageUrl;

    // Use URL service to get thumbnail
    // Note: /services/img/ redirects to CDN which lacks CORS headers
    // Web browsers may block these thumbnails (platform limitation)
    // Native platforms work fine
    thumbnailUrl = urlService.getThumbnailUrl(identifier);
    
    // Cover image is the full-size version (remove _thumb suffix)
    coverImageUrl = thumbnailUrl.replaceAll('__ia_thumb.jpg', '.jpg');

    // Extract rating (can be in reviews or metadata)
    // Handle both numeric and string formats gracefully
    double? rating;
    try {
      if (json['reviews']?['avg_rating'] != null) {
        final avgRating = json['reviews']['avg_rating'];
        if (avgRating is num) {
          rating = avgRating.toDouble();
        } else if (avgRating is String) {
          rating = double.tryParse(avgRating);
        }
      } else if (json['metadata']?['avg_rating'] != null) {
        final avgRating = json['metadata']['avg_rating'];
        if (avgRating is num) {
          rating = avgRating.toDouble();
        } else if (avgRating is String) {
          rating = double.tryParse(avgRating);
        }
      }
    } catch (e) {
      // Silently handle rating parsing errors
      // Some items may have invalid rating data
      rating = null;
    }

    // Extract Archive.org collections (can be string or list)
    List<String> archiveOrgCollections = [];
    try {
      final collectionData = json['metadata']?['collection'];
      if (collectionData != null) {
        if (collectionData is List) {
          archiveOrgCollections = collectionData
              .map((c) => c.toString())
              .where((c) => c.isNotEmpty)
              .toList();
        } else if (collectionData is String && collectionData.isNotEmpty) {
          archiveOrgCollections = [collectionData];
        }
      }
    } catch (e) {
      // Silently handle collection parsing errors
      archiveOrgCollections = [];
    }

    return ArchiveMetadata(
      identifier: identifier,
      title: json['metadata']?['title'],
      description: json['metadata']?['description'],
      creator: json['metadata']?['creator'],
      date: json['metadata']?['date'],
      totalFiles: files.length,
      totalSize: _parseIntField(json['item_size']) ?? 0,
      filesCount: _parseIntField(json['files_count']),
      itemLastUpdated: _parseIntField(json['item_last_updated']),
      files: files,
      thumbnailUrl: thumbnailUrl,
      coverImageUrl: coverImageUrl,
      mediaType: json['metadata']?['mediatype'] as String?,
      downloads: json['downloads'] as int?,
      rating: rating,
      archiveOrgCollections: archiveOrgCollections,
    );
  }

  /// Parse a field that could be either a String or an int
  static int? _parseIntField(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      return int.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'metadata': {
        'identifier': identifier,
        'title': title,
        'description': description,
        'creator': creator,
        'date': date,
        'mediatype': mediaType,
        'avg_rating': rating,
      },
      'item_size': totalSize,
      'files_count': filesCount,
      'item_last_updated': itemLastUpdated,
      'downloads': downloads,
      'misc': {if (thumbnailUrl != null) 'image': thumbnailUrl},
      'files': files.map((f) => f.toJson()).toList(),
    };
  }
}

/// Individual file in an archive
class ArchiveFile {
  final String name;
  final int? size;
  final String? format;
  final String? source;
  final String? downloadUrl;
  final String? md5;
  final String? sha1;
  final String? crc32;
  final String? btih;
  final String? summation;
  final int? mtime;
  final int? rotation;
  final String? original;
  bool selected;

  ArchiveFile({
    required this.name,
    this.size,
    this.format,
    this.source,
    this.downloadUrl,
    this.md5,
    this.sha1,
    this.crc32,
    this.btih,
    this.summation,
    this.mtime,
    this.rotation,
    this.original,
    this.selected = false,
  });

  /// Get the directory path of this file (everything before the last /)
  String get directory {
    final lastSlash = name.lastIndexOf('/');
    if (lastSlash == -1) return '';
    return name.substring(0, lastSlash);
  }

  /// Get just the filename (after the last /)
  String get filename {
    final lastSlash = name.lastIndexOf('/');
    if (lastSlash == -1) return name;
    return name.substring(lastSlash + 1);
  }

  /// Check if file is in a specific subfolder (supports wildcards)
  bool isInSubfolder(String pattern) {
    if (pattern.isEmpty) return true;

    final dir = directory;
    final patternLower = pattern.toLowerCase();
    final dirLower = dir.toLowerCase();

    // Exact match
    if (dirLower == patternLower) return true;

    // Starts with pattern (subfolder matching)
    if (dirLower.startsWith(patternLower)) return true;

    // Wildcard pattern matching
    if (patternLower.contains('*')) {
      final regexPattern = patternLower
          .replaceAll('\\', '\\\\')
          .replaceAll('.', '\\.')
          .replaceAll('*', '.*')
          .replaceAll('?', '.');
      try {
        final regex = RegExp('^$regexPattern\$');
        return regex.hasMatch(dirLower);
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  factory ArchiveFile.fromJson(Map<String, dynamic> json) {
    return ArchiveFile(
      name: json['name'] ?? '',
      size: _parseIntField(json['size']),
      format: json['format'],
      source: json['source'],
      downloadUrl: json['download_url'],
      md5: json['md5'],
      sha1: json['sha1'],
      crc32: json['crc32'],
      btih: json['btih'],
      summation: json['summation'],
      mtime: _parseIntField(json['mtime']),
      rotation: _parseIntField(json['rotation']),
      original: json['original'],
      selected: json['selected'] ?? false,
    );
  }

  /// Parse a field that could be either a String or an int
  static int? _parseIntField(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      return int.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
      'format': format,
      'source': source,
      'download_url': downloadUrl,
      'md5': md5,
      'sha1': sha1,
      'crc32': crc32,
      'btih': btih,
      'summation': summation,
      'mtime': mtime,
      'rotation': rotation,
      'original': original,
      'selected': selected,
    };
  }

  String get sizeFormatted {
    if (size == null) return 'Unknown size';

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double bytes = size!.toDouble();
    int unitIndex = 0;

    while (bytes >= 1024 && unitIndex < units.length - 1) {
      bytes /= 1024;
      unitIndex++;
    }

    return '${bytes.toStringAsFixed(bytes >= 100 ? 0 : 1)} ${units[unitIndex]}';
  }

  String get displayName {
    // Remove common prefixes and clean up the name
    String cleanName = name;
    if (cleanName.contains('/')) {
      cleanName = cleanName.split('/').last;
    }
    return cleanName;
  }

  /// Check if this is an original file
  bool get isOriginal => source?.toLowerCase() == 'original';

  /// Check if this is a derivative file
  bool get isDerivative => source?.toLowerCase() == 'derivative';

  /// Check if this is a metadata file
  bool get isMetadata => source?.toLowerCase() == 'metadata';

  /// Get a user-friendly source type name
  String get sourceTypeName {
    if (isOriginal) return 'Original';
    if (isDerivative) return 'Derivative';
    if (isMetadata) return 'Metadata';
    return 'Unknown';
  }
}
