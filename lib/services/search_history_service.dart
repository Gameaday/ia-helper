/// Search History Service for Internet Archive
///
/// Manages search history persistence and retrieval for autocomplete suggestions.
/// Stores recent searches with timestamps and result counts.
library;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/search_history_entry.dart';

/// Service for managing search history
///
/// Features:
/// - Persists search history to SQLite
/// - Provides autocomplete suggestions
/// - Limits history size (default: 100 entries)
/// - Auto-cleanup of old entries
/// - Prevents duplicate entries
class SearchHistoryService extends ChangeNotifier {
  static const String _tableName = 'search_history';
  static const int _maxHistorySize = 100;
  static const int _maxAgeDays = 90; // Auto-delete entries older than 90 days

  final DatabaseHelper _dbHelper;
  List<SearchHistoryEntry> _history = [];
  bool _isLoaded = false;

  /// Singleton instance
  static SearchHistoryService? _instance;
  static SearchHistoryService get instance {
    _instance ??= SearchHistoryService._internal(DatabaseHelper.instance);
    return _instance!;
  }

  SearchHistoryService._internal(this._dbHelper);

  /// Create service with custom database helper (for testing)
  @visibleForTesting
  factory SearchHistoryService.test(DatabaseHelper dbHelper) {
    return SearchHistoryService._internal(dbHelper);
  }

  /// Get all search history entries (most recent first)
  Future<List<SearchHistoryEntry>> getHistory() async {
    if (_isLoaded) {
      return List.unmodifiable(_history);
    }

    final db = await _dbHelper.database;
    final maps = await db.query(
      _tableName,
      orderBy: 'timestamp DESC',
      limit: _maxHistorySize,
    );

    _history = maps.map((map) => SearchHistoryEntry.fromMap(map)).toList();
    _isLoaded = true;

    return List.unmodifiable(_history);
  }

  /// Get search suggestions based on query prefix
  ///
  /// Returns entries where the query starts with [prefix] (case-insensitive)
  Future<List<SearchHistoryEntry>> getSuggestions(String prefix) async {
    if (prefix.trim().isEmpty) {
      return [];
    }

    await getHistory(); // Ensure history is loaded

    final lowerPrefix = prefix.toLowerCase();
    return _history
        .where((entry) => entry.query.toLowerCase().startsWith(lowerPrefix))
        .take(10)
        .toList();
  }

  /// Search history entries by query text
  ///
  /// Returns entries where the query contains [searchText] (case-insensitive)
  Future<List<SearchHistoryEntry>> searchHistory(String searchText) async {
    if (searchText.trim().isEmpty) {
      return getHistory();
    }

    await getHistory(); // Ensure history is loaded

    final lowerSearch = searchText.toLowerCase();
    return _history
        .where((entry) => entry.query.toLowerCase().contains(lowerSearch))
        .toList();
  }

  /// Add a new search history entry
  ///
  /// If the query already exists, updates the timestamp instead of creating a duplicate
  Future<void> addEntry(SearchHistoryEntry entry) async {
    final db = await _dbHelper.database;

    // Check if entry with same query already exists
    final existing = await db.query(
      _tableName,
      where: 'query = ?',
      whereArgs: [entry.query],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Update existing entry
      await db.update(
        _tableName,
        {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'result_count': entry.resultCount,
          'mediatype': entry.mediatype,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );

      // Update in-memory list
      final index = _history.indexWhere(
        (e) => e.query == entry.query,
      );
      if (index >= 0) {
        _history[index] = SearchHistoryEntry(
          id: existing.first['id'] as int,
          query: entry.query,
          timestamp: DateTime.now(),
          resultCount: entry.resultCount,
          mediatype: entry.mediatype,
        );
        // Move to front
        final updated = _history.removeAt(index);
        _history.insert(0, updated);
      }
    } else {
      // Insert new entry
      final id = await db.insert(_tableName, entry.toMap());

      // Add to in-memory list at front
      _history.insert(
        0,
        SearchHistoryEntry(
          id: id,
          query: entry.query,
          timestamp: entry.timestamp,
          resultCount: entry.resultCount,
          mediatype: entry.mediatype,
        ),
      );

      // Maintain max size
      if (_history.length > _maxHistorySize) {
        final toRemove = _history.removeLast();
        if (toRemove.id != null) {
          await db.delete(
            _tableName,
            where: 'id = ?',
            whereArgs: [toRemove.id],
          );
        }
      }
    }

    notifyListeners();
  }

  /// Remove a specific history entry
  Future<void> removeEntry(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    _history.removeWhere((entry) => entry.id == id);
    notifyListeners();
  }

  /// Remove all history entries matching a query
  Future<void> removeByQuery(String query) async {
    final db = await _dbHelper.database;
    await db.delete(
      _tableName,
      where: 'query = ?',
      whereArgs: [query],
    );

    _history.removeWhere((entry) => entry.query == query);
    notifyListeners();
  }

  /// Clear all history
  Future<void> clearHistory() async {
    final db = await _dbHelper.database;
    await db.delete(_tableName);

    _history.clear();
    notifyListeners();
  }

  /// Clean up old history entries
  ///
  /// Removes entries older than [_maxAgeDays] days
  Future<int> cleanupOldEntries() async {
    final db = await _dbHelper.database;
    final cutoffDate = DateTime.now().subtract(const Duration(days: _maxAgeDays));
    final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;

    final count = await db.delete(
      _tableName,
      where: 'timestamp < ?',
      whereArgs: [cutoffTimestamp],
    );

    if (count > 0) {
      // Reload history
      _isLoaded = false;
      await getHistory();
      notifyListeners();
    }

    return count;
  }

  /// Get total count of history entries
  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get most popular searches (by frequency)
  ///
  /// Groups identical queries and returns those that appear most often
  Future<List<SearchHistoryEntry>> getPopularSearches({int limit = 10}) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT 
        query,
        MAX(timestamp) as latest_timestamp,
        MAX(result_count) as result_count,
        mediatype,
        COUNT(*) as frequency
      FROM $_tableName
      GROUP BY query
      ORDER BY frequency DESC, latest_timestamp DESC
      LIMIT ?
    ''', [limit]);

    return result.map((map) {
      return SearchHistoryEntry(
        query: map['query'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['latest_timestamp'] as int),
        resultCount: map['result_count'] as int?,
        mediatype: map['mediatype'] as String?,
      );
    }).toList();
  }

  /// Get recent searches with a specific mediatype
  Future<List<SearchHistoryEntry>> getHistoryByMediatype(String mediatype) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'mediatype = ?',
      whereArgs: [mediatype],
      orderBy: 'timestamp DESC',
      limit: 20,
    );

    return maps.map((map) => SearchHistoryEntry.fromMap(map)).toList();
  }

  /// Dispose service and clear memory
  @override
  void dispose() {
    _history.clear();
    _isLoaded = false;
    super.dispose();
  }
}
