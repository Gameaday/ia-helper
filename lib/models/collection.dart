import 'dart:convert';
import 'package:flutter/material.dart';

/// Represents a collection of Internet Archive items
/// 
/// Collections allow users to organize their archives into named groups.
/// Collections can be regular (manually curated) or smart (auto-populated by rules).
class Collection {
  final int? id;
  final String name;
  final String? description;
  final String? icon;
  final Color? color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSmart;
  final Map<String, dynamic>? smartRulesJson;

  const Collection({
    this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    required this.createdAt,
    required this.updatedAt,
    this.isSmart = false,
    this.smartRulesJson,
  });

  /// Create from database map
  factory Collection.fromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      icon: map['icon'] as String?,
      color: map['color'] != null ? Color(map['color'] as int) : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      isSmart: (map['is_smart'] as int?) == 1,
      smartRulesJson: map['smart_rules_json'] != null
          ? json.decode(map['smart_rules_json'] as String) as Map<String, dynamic>
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color?.toARGB32(),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_smart': isSmart ? 1 : 0,
      'smart_rules_json': smartRulesJson != null ? json.encode(smartRulesJson) : null,
    };
  }

  /// Create a copy with updated fields
  Collection copyWith({
    int? id,
    String? name,
    String? description,
    String? icon,
    Color? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSmart,
    Map<String, dynamic>? smartRulesJson,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSmart: isSmart ?? this.isSmart,
      smartRulesJson: smartRulesJson ?? this.smartRulesJson,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Collection &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.icon == icon &&
        other.color == color &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isSmart == isSmart;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      icon,
      color,
      createdAt,
      updatedAt,
      isSmart,
    );
  }

  @override
  String toString() {
    return 'Collection(id: $id, name: $name, isSmart: $isSmart, createdAt: $createdAt)';
  }

  /// Get icon data for display
  IconData get iconData {
    if (icon == null) return Icons.folder;
    
    // Map icon name strings to IconData
    switch (icon) {
      case 'favorite':
        return Icons.favorite;
      case 'star':
        return Icons.star;
      case 'bookmark':
        return Icons.bookmark;
      case 'label':
        return Icons.label;
      case 'folder':
        return Icons.folder;
      case 'folder_special':
        return Icons.folder_special;
      case 'collections_bookmark':
        return Icons.collections_bookmark;
      case 'book':
        return Icons.book;
      case 'movie':
        return Icons.movie;
      case 'music_note':
        return Icons.music_note;
      case 'image':
        return Icons.image;
      case 'videogame_asset':
        return Icons.videogame_asset;
      default:
        return Icons.folder;
    }
  }

  /// Get display color (with fallback)
  Color get displayColor => color ?? Colors.blue;

  /// Format created date as human-readable string
  String get formattedCreatedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Created today';
    } else if (difference.inDays == 1) {
      return 'Created yesterday';
    } else if (difference.inDays < 7) {
      return 'Created ${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Created ${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Created ${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Created ${years}y ago';
    }
  }

  /// Format updated date as human-readable string
  String get formattedUpdatedDate {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Updated ${difference.inMinutes}m ago';
      }
      return 'Updated ${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Updated yesterday';
    } else if (difference.inDays < 7) {
      return 'Updated ${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Updated ${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Updated ${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Updated ${years}y ago';
    }
  }
}

/// Represents an item in a collection
class CollectionItem {
  final int collectionId;
  final String identifier;
  final DateTime addedAt;

  const CollectionItem({
    required this.collectionId,
    required this.identifier,
    required this.addedAt,
  });

  /// Create from database map
  factory CollectionItem.fromMap(Map<String, dynamic> map) {
    return CollectionItem(
      collectionId: map['collection_id'] as int,
      identifier: map['identifier'] as String,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'collection_id': collectionId,
      'identifier': identifier,
      'added_at': addedAt.millisecondsSinceEpoch,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CollectionItem &&
        other.collectionId == collectionId &&
        other.identifier == identifier &&
        other.addedAt == addedAt;
  }

  @override
  int get hashCode {
    return Object.hash(collectionId, identifier, addedAt);
  }

  @override
  String toString() {
    return 'CollectionItem(collectionId: $collectionId, identifier: $identifier, addedAt: $addedAt)';
  }
}
