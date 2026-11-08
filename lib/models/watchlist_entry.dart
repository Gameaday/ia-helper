import 'dart:convert';

/// A watched Internet Archive item (#91).
///
/// The watchlist tracks archive.org identifiers for new uploads, strictly
/// locally. Each entry keeps a snapshot of the item's file count so a
/// later check can surface how many files were added since the user last
/// looked — no account, no server component, no alerts bill.
class WatchlistEntry {
  final int? id;
  final String identifier;

  /// Display title; falls back to [identifier] when unknown.
  final String? title;
  final String? mediatype;
  final DateTime addedAt;

  /// File-count snapshot from the last check. `-1` means "not checked
  /// yet": the first check establishes the baseline without flagging.
  final int knownFileCount;

  /// Files added since the user last opened the item. Reset on open.
  final int newFileCount;
  final DateTime? lastCheckedAt;
  final DateTime? lastChangedAt;
  final Map<String, dynamic>? metadataJson;

  const WatchlistEntry({
    this.id,
    required this.identifier,
    this.title,
    this.mediatype,
    required this.addedAt,
    this.knownFileCount = -1,
    this.newFileCount = 0,
    this.lastCheckedAt,
    this.lastChangedAt,
    this.metadataJson,
  });

  /// Create from a database row.
  factory WatchlistEntry.fromMap(Map<String, dynamic> map) {
    return WatchlistEntry(
      id: map['id'] as int?,
      identifier: map['identifier'] as String,
      title: map['title'] as String?,
      mediatype: map['mediatype'] as String?,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
      knownFileCount: (map['known_file_count'] as int?) ?? -1,
      newFileCount: (map['new_file_count'] as int?) ?? 0,
      lastCheckedAt: map['last_checked_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_checked_at'] as int)
          : null,
      lastChangedAt: map['last_changed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_changed_at'] as int)
          : null,
      metadataJson: map['metadata_json'] != null
          ? jsonDecode(map['metadata_json'] as String)
              as Map<String, dynamic>
          : null,
    );
  }

  /// Convert to a database row.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'identifier': identifier,
      'title': title,
      'mediatype': mediatype,
      'added_at': addedAt.millisecondsSinceEpoch,
      'known_file_count': knownFileCount,
      'new_file_count': newFileCount,
      'last_checked_at': lastCheckedAt?.millisecondsSinceEpoch,
      'last_changed_at': lastChangedAt?.millisecondsSinceEpoch,
      'metadata_json': metadataJson != null ? jsonEncode(metadataJson) : null,
    };
  }

  /// Create a copy with updated fields.
  WatchlistEntry copyWith({
    int? id,
    String? identifier,
    String? title,
    String? mediatype,
    DateTime? addedAt,
    int? knownFileCount,
    int? newFileCount,
    DateTime? lastCheckedAt,
    DateTime? lastChangedAt,
    Map<String, dynamic>? metadataJson,
  }) {
    return WatchlistEntry(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      title: title ?? this.title,
      mediatype: mediatype ?? this.mediatype,
      addedAt: addedAt ?? this.addedAt,
      knownFileCount: knownFileCount ?? this.knownFileCount,
      newFileCount: newFileCount ?? this.newFileCount,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      lastChangedAt: lastChangedAt ?? this.lastChangedAt,
      metadataJson: metadataJson ?? this.metadataJson,
    );
  }

  /// Title for display, with identifier fallback.
  String get displayTitle => title ?? identifier;

  /// Whether the item has unacknowledged new files.
  bool get hasNewFiles => newFileCount > 0;

  /// Whether a check has ever established the file-count baseline.
  bool get hasBaseline => knownFileCount >= 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WatchlistEntry &&
        other.id == id &&
        other.identifier == identifier &&
        other.title == title &&
        other.mediatype == mediatype &&
        other.addedAt == addedAt &&
        other.knownFileCount == knownFileCount &&
        other.newFileCount == newFileCount;
  }

  @override
  int get hashCode => Object.hash(
    id,
    identifier,
    title,
    mediatype,
    addedAt,
    knownFileCount,
    newFileCount,
  );

  @override
  String toString() {
    return 'WatchlistEntry(id: $id, identifier: $identifier, title: $title, '
        'knownFileCount: $knownFileCount, newFileCount: $newFileCount, '
        'addedAt: $addedAt)';
  }
}
