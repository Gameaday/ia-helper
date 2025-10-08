/// Saved Search Model for Internet Archive
///
/// Represents a saved search query that users can access later.
/// Includes metadata for organization and usage tracking.
library;

import 'package:flutter/foundation.dart';
import 'search_query.dart';

/// A saved search with metadata
@immutable
class SavedSearch {
  /// Unique identifier (database ID)
  final int? id;

  /// User-provided name for the search
  final String name;

  /// Optional description
  final String? description;

  /// The actual search query
  final SearchQuery query;

  /// When this search was created
  final DateTime createdAt;

  /// When this search was last used
  final DateTime? lastUsedAt;

  /// How many times this search has been used
  final int useCount;

  /// Whether this search is pinned (shown at top)
  final bool isPinned;

  /// Optional tags for organization
  final List<String> tags;

  const SavedSearch({
    this.id,
    required this.name,
    this.description,
    required this.query,
    required this.createdAt,
    this.lastUsedAt,
    this.useCount = 0,
    this.isPinned = false,
    this.tags = const [],
  });

  /// Create a new saved search
  factory SavedSearch.create({
    required String name,
    String? description,
    required SearchQuery query,
    List<String>? tags,
  }) {
    return SavedSearch(
      name: name,
      description: description,
      query: query,
      createdAt: DateTime.now(),
      tags: tags ?? [],
    );
  }

  /// Get display name (falls back to query if name is empty)
  String get displayName {
    if (name.trim().isNotEmpty) {
      return name;
    }
    return query.query ?? 'Unnamed Search';
  }

  /// Get a short summary of the search
  String get summary {
    final parts = <String>[];

    if (query.query != null && query.query!.trim().isNotEmpty) {
      parts.add(query.query!);
    }

    if (query.mediatypes.isNotEmpty) {
      parts.add('Type: ${query.mediatypes.join(", ")}');
    }

    if (query.dateRange != null) {
      parts.add('Date: ${query.dateRange!.toDisplayString()}');
    }

    return parts.isEmpty ? 'Advanced search' : parts.join(' • ');
  }

  /// Format last used time for display
  String get lastUsedDisplay {
    if (lastUsedAt == null) {
      return 'Never used';
    }

    final now = DateTime.now();
    final difference = now.difference(lastUsedAt!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? "week" : "weeks"} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? "month" : "months"} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? "year" : "years"} ago';
    }
  }

  /// Format created time for display
  String get createdDisplay {
    return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
  }

  /// Create a copy with modified fields
  SavedSearch copyWith({
    int? id,
    String? name,
    String? description,
    SearchQuery? query,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? useCount,
    bool? isPinned,
    List<String>? tags,
  }) {
    return SavedSearch(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      query: query ?? this.query,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      useCount: useCount ?? this.useCount,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
    );
  }

  /// Create a copy with incremented use count and updated lastUsedAt
  SavedSearch markUsed() {
    return copyWith(useCount: useCount + 1, lastUsedAt: DateTime.now());
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'query_json': query.toJson(),
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_used_at': lastUsedAt?.millisecondsSinceEpoch,
      'use_count': useCount,
      'is_pinned': isPinned ? 1 : 0,
      'tags_json': tags,
    };
  }

  /// Create from database map
  factory SavedSearch.fromMap(Map<String, dynamic> map) {
    return SavedSearch(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      query: SearchQuery.fromJson(map['query_json'] as Map<String, dynamic>),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      lastUsedAt: map['last_used_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_used_at'] as int)
          : null,
      useCount: map['use_count'] as int? ?? 0,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      tags: List<String>.from(map['tags_json'] as List? ?? []),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'query': query.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'useCount': useCount,
      'isPinned': isPinned,
      'tags': tags,
    };
  }

  /// Create from JSON
  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      query: SearchQuery.fromJson(json['query'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      useCount: json['useCount'] as int? ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      tags: List<String>.from(json['tags'] as List? ?? []),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SavedSearch &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.query == query &&
        other.createdAt == createdAt &&
        other.lastUsedAt == lastUsedAt &&
        other.useCount == useCount &&
        other.isPinned == isPinned &&
        _listEquals(other.tags, tags);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      query,
      createdAt,
      lastUsedAt,
      useCount,
      isPinned,
      Object.hashAll(tags),
    );
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'SavedSearch(id: $id, name: $name, query: $query, '
        'useCount: $useCount, isPinned: $isPinned)';
  }
}
