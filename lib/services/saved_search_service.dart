/// Saved Search Service for Internet Archive
///
/// Manages saved search queries with metadata, usage tracking, and organization.
/// Users can save complex searches for quick access later.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/saved_search.dart';

/// Service for managing saved searches
///
/// Features:
/// - Persists saved searches to SQLite
/// - Usage tracking (count, last used)
/// - Pinning important searches
/// - Tagging for organization
/// - Automatic lastUsedAt updates
class SavedSearchService extends ChangeNotifier {
  static const String _tableName = 'saved_searches';

  final DatabaseHelper _dbHelper;
  List<SavedSearch> _savedSearches = [];
  bool _isLoaded = false;

  /// Singleton instance
  static SavedSearchService? _instance;
  static SavedSearchService get instance {
    _instance ??= SavedSearchService._internal(DatabaseHelper.instance);
    return _instance!;
  }

  SavedSearchService._internal(this._dbHelper);

  /// Create service with custom database helper (for testing)
  @visibleForTesting
  factory SavedSearchService.test(DatabaseHelper dbHelper) {
    return SavedSearchService._internal(dbHelper);
  }

  /// Get all saved searches
  ///
  /// Returns pinned searches first, then sorted by last used
  Future<List<SavedSearch>> getAllSavedSearches() async {
    if (_isLoaded) {
      return List.unmodifiable(_savedSearches);
    }

    final db = await _dbHelper.database;
    final maps = await db.query(
      _tableName,
      orderBy: 'is_pinned DESC, last_used_at DESC NULLS LAST, created_at DESC',
    );

    _savedSearches = maps.map((map) => _fromMap(map)).toList();
    _isLoaded = true;

    return List.unmodifiable(_savedSearches);
  }

  /// Get a saved search by ID
  Future<SavedSearch?> getSavedSearch(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return _fromMap(maps.first);
  }

  /// Get a saved search by name
  Future<SavedSearch?> getSavedSearchByName(String name) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return _fromMap(maps.first);
  }

  /// Get pinned saved searches
  Future<List<SavedSearch>> getPinnedSearches() async {
    await getAllSavedSearches(); // Ensure loaded

    return _savedSearches.where((search) => search.isPinned).toList();
  }

  /// Get saved searches with a specific tag
  Future<List<SavedSearch>> getSearchesByTag(String tag) async {
    await getAllSavedSearches(); // Ensure loaded

    return _savedSearches
        .where((search) => search.tags.contains(tag))
        .toList();
  }

  /// Get all unique tags used in saved searches
  Future<List<String>> getAllTags() async {
    await getAllSavedSearches(); // Ensure loaded

    final tagSet = <String>{};
    for (final search in _savedSearches) {
      tagSet.addAll(search.tags);
    }

    final tags = tagSet.toList();
    tags.sort();
    return tags;
  }

  /// Create a new saved search
  Future<SavedSearch> createSavedSearch(SavedSearch search) async {
    final db = await _dbHelper.database;

    // Check for duplicate name
    final existing = await getSavedSearchByName(search.name);
    if (existing != null) {
      throw Exception('A saved search with the name "${search.name}" already exists');
    }

    final id = await db.insert(_tableName, _toMap(search));

    final created = search.copyWith(id: id);
    _savedSearches.insert(0, created);
    notifyListeners();

    return created;
  }

  /// Update an existing saved search
  Future<void> updateSavedSearch(SavedSearch search) async {
    if (search.id == null) {
      throw ArgumentError('Cannot update saved search without ID');
    }

    final db = await _dbHelper.database;

    // Check for duplicate name (excluding current search)
    final existing = await getSavedSearchByName(search.name);
    if (existing != null && existing.id != search.id) {
      throw Exception('A saved search with the name "${search.name}" already exists');
    }

    await db.update(
      _tableName,
      _toMap(search),
      where: 'id = ?',
      whereArgs: [search.id],
    );

    // Update in-memory list
    final index = _savedSearches.indexWhere((s) => s.id == search.id);
    if (index >= 0) {
      _savedSearches[index] = search;
      notifyListeners();
    }
  }

  /// Delete a saved search
  Future<void> deleteSavedSearch(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    _savedSearches.removeWhere((search) => search.id == id);
    notifyListeners();
  }

  /// Mark a saved search as used
  ///
  /// Increments use count and updates lastUsedAt timestamp
  Future<void> markSearchUsed(int id) async {
    final search = _savedSearches.firstWhere(
      (s) => s.id == id,
      orElse: () => throw ArgumentError('Saved search not found'),
    );

    final updated = search.markUsed();
    await updateSavedSearch(updated);
  }

  /// Toggle pin status of a saved search
  Future<void> togglePin(int id) async {
    final search = _savedSearches.firstWhere(
      (s) => s.id == id,
      orElse: () => throw ArgumentError('Saved search not found'),
    );

    final updated = search.copyWith(isPinned: !search.isPinned);
    await updateSavedSearch(updated);
  }

  /// Add a tag to a saved search
  Future<void> addTag(int id, String tag) async {
    final search = _savedSearches.firstWhere(
      (s) => s.id == id,
      orElse: () => throw ArgumentError('Saved search not found'),
    );

    if (search.tags.contains(tag)) {
      return; // Tag already exists
    }

    final tags = List<String>.from(search.tags)..add(tag);
    final updated = search.copyWith(tags: tags);
    await updateSavedSearch(updated);
  }

  /// Remove a tag from a saved search
  Future<void> removeTag(int id, String tag) async {
    final search = _savedSearches.firstWhere(
      (s) => s.id == id,
      orElse: () => throw ArgumentError('Saved search not found'),
    );

    final tags = List<String>.from(search.tags)..remove(tag);
    final updated = search.copyWith(tags: tags);
    await updateSavedSearch(updated);
  }

  /// Search saved searches by name or description
  Future<List<SavedSearch>> searchSavedSearches(String query) async {
    await getAllSavedSearches(); // Ensure loaded

    if (query.trim().isEmpty) {
      return List.unmodifiable(_savedSearches);
    }

    final lowerQuery = query.toLowerCase();
    return _savedSearches.where((search) {
      return search.name.toLowerCase().contains(lowerQuery) ||
          (search.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Get most frequently used saved searches
  Future<List<SavedSearch>> getFrequentlyUsedSearches({int limit = 10}) async {
    await getAllSavedSearches(); // Ensure loaded

    final sorted = List<SavedSearch>.from(_savedSearches)
      ..sort((a, b) => b.useCount.compareTo(a.useCount));

    return sorted.take(limit).toList();
  }

  /// Get recently used saved searches
  Future<List<SavedSearch>> getRecentlyUsedSearches({int limit = 10}) async {
    await getAllSavedSearches(); // Ensure loaded

    final withLastUsed = _savedSearches.where((s) => s.lastUsedAt != null).toList()
      ..sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));

    return withLastUsed.take(limit).toList();
  }

  /// Get total count of saved searches
  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Clear all saved searches
  Future<void> clearAllSavedSearches() async {
    final db = await _dbHelper.database;
    await db.delete(_tableName);

    _savedSearches.clear();
    notifyListeners();
  }

  /// Convert SavedSearch to database map
  Map<String, dynamic> _toMap(SavedSearch search) {
    return {
      'id': search.id,
      'name': search.name,
      'description': search.description,
      'query_json': jsonEncode(search.query.toJson()),
      'created_at': search.createdAt.millisecondsSinceEpoch,
      'last_used_at': search.lastUsedAt?.millisecondsSinceEpoch,
      'use_count': search.useCount,
      'is_pinned': search.isPinned ? 1 : 0,
      'tags_json': jsonEncode(search.tags),
    };
  }

  /// Convert database map to SavedSearch
  SavedSearch _fromMap(Map<String, dynamic> map) {
    return SavedSearch(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      query: _parseQuery(map['query_json'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      lastUsedAt: map['last_used_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_used_at'] as int)
          : null,
      useCount: map['use_count'] as int,
      isPinned: (map['is_pinned'] as int) == 1,
      tags: _parseTags(map['tags_json'] as String?),
    );
  }

  /// Parse query JSON
  dynamic _parseQuery(String json) {
    try {
      return jsonDecode(json);
    } catch (e) {
      debugPrint('Error parsing query JSON: $e');
      return {};
    }
  }

  /// Parse tags JSON
  List<String> _parseTags(String? json) {
    if (json == null || json.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return List<String>.from(decoded);
      }
      return [];
    } catch (e) {
      debugPrint('Error parsing tags JSON: $e');
      return [];
    }
  }

  /// Dispose service and clear memory
  @override
  void dispose() {
    _savedSearches.clear();
    _isLoaded = false;
    super.dispose();
  }
}
