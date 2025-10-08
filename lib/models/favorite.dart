import 'dart:convert';

/// Represents a favorited Internet Archive item
/// 
/// Favorites allow users to quickly access archives they want to revisit.
/// Each favorite stores minimal metadata for quick display, with full metadata
/// available via the identifier.
class Favorite {
  final int? id;
  final String identifier;
  final String? title;
  final String? mediatype;
  final DateTime addedAt;
  final Map<String, dynamic>? metadataJson;

  const Favorite({
    this.id,
    required this.identifier,
    this.title,
    this.mediatype,
    required this.addedAt,
    this.metadataJson,
  });

  /// Create from database map
  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      id: map['id'] as int?,
      identifier: map['identifier'] as String,
      title: map['title'] as String?,
      mediatype: map['mediatype'] as String?,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
      metadataJson: map['metadata_json'] != null
          ? json.decode(map['metadata_json'] as String) as Map<String, dynamic>
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'identifier': identifier,
      'title': title,
      'mediatype': mediatype,
      'added_at': addedAt.millisecondsSinceEpoch,
      'metadata_json': metadataJson != null ? json.encode(metadataJson) : null,
    };
  }

  /// Create a copy with updated fields
  Favorite copyWith({
    int? id,
    String? identifier,
    String? title,
    String? mediatype,
    DateTime? addedAt,
    Map<String, dynamic>? metadataJson,
  }) {
    return Favorite(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      title: title ?? this.title,
      mediatype: mediatype ?? this.mediatype,
      addedAt: addedAt ?? this.addedAt,
      metadataJson: metadataJson ?? this.metadataJson,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Favorite &&
        other.id == id &&
        other.identifier == identifier &&
        other.title == title &&
        other.mediatype == mediatype &&
        other.addedAt == addedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      identifier,
      title,
      mediatype,
      addedAt,
    );
  }

  @override
  String toString() {
    return 'Favorite(id: $id, identifier: $identifier, title: $title, mediatype: $mediatype, addedAt: $addedAt)';
  }

  /// Get display title (with fallback to identifier)
  String get displayTitle => title ?? identifier;

  /// Get display mediatype (with fallback)
  String get displayMediatype => mediatype ?? 'unknown';

  /// Format added date as human-readable string
  String get formattedAddedDate {
    final now = DateTime.now();
    final difference = now.difference(addedAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Added ${difference.inMinutes}m ago';
      }
      return 'Added ${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Added yesterday';
    } else if (difference.inDays < 7) {
      return 'Added ${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Added ${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Added ${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Added ${years}y ago';
    }
  }
}
