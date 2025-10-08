import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/favorite.dart';

/// Service for managing favorites (starred archives)
///
/// Provides CRUD operations for favoriting Internet Archive items.
/// Uses SQLite for persistent storage with efficient queries.
///
/// Features:
/// - Add/remove favorites
/// - Check if item is favorited
/// - Get all favorites with sorting and filtering
/// - Count favorites by mediatype
/// - Stream-based updates for reactive UI
class FavoritesService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Singleton pattern
  FavoritesService._privateConstructor();
  static final FavoritesService instance =
      FavoritesService._privateConstructor();

  // Cache for quick favorite status checks
  final Set<String> _favoritesCache = {};
  bool _cacheInitialized = false;

  /// Initialize favorites cache for faster lookups
  Future<void> _initializeCache() async {
    if (_cacheInitialized) return;

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableFavorites,
        columns: ['identifier'],
      );

      _favoritesCache.clear();
      for (final map in maps) {
        _favoritesCache.add(map['identifier'] as String);
      }

      _cacheInitialized = true;
      debugPrint(
        'Favorites cache initialized with ${_favoritesCache.length} items',
      );
    } catch (e) {
      debugPrint('Error initializing favorites cache: $e');
    }
  }

  /// Add an archive to favorites
  ///
  /// Returns true if added successfully, false if already favorited
  Future<bool> addFavorite(Favorite favorite) async {
    try {
      final db = await _dbHelper.database;

      // Check if already favorited
      if (await isFavorited(favorite.identifier)) {
        debugPrint('Archive ${favorite.identifier} is already favorited');
        return false;
      }

      await db.insert(
        DatabaseHelper.tableFavorites,
        favorite.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Update cache
      _favoritesCache.add(favorite.identifier);

      debugPrint('Added favorite: ${favorite.identifier}');
      return true;
    } catch (e) {
      debugPrint('Error adding favorite: $e');
      return false;
    }
  }

  /// Remove an archive from favorites
  ///
  /// Returns true if removed successfully, false if not found
  Future<bool> removeFavorite(String identifier) async {
    try {
      final db = await _dbHelper.database;

      final count = await db.delete(
        DatabaseHelper.tableFavorites,
        where: 'identifier = ?',
        whereArgs: [identifier],
      );

      // Update cache
      _favoritesCache.remove(identifier);

      debugPrint('Removed favorite: $identifier (rows affected: $count)');
      return count > 0;
    } catch (e) {
      debugPrint('Error removing favorite: $e');
      return false;
    }
  }

  /// Toggle favorite status (add if not favorited, remove if favorited)
  ///
  /// Returns the new favorite status (true = favorited, false = not favorited)
  Future<bool> toggleFavorite(Favorite favorite) async {
    if (await isFavorited(favorite.identifier)) {
      await removeFavorite(favorite.identifier);
      return false;
    } else {
      await addFavorite(favorite);
      return true;
    }
  }

  /// Check if an archive is favorited
  ///
  /// Uses cache for fast lookups after initialization
  Future<bool> isFavorited(String identifier) async {
    await _initializeCache();
    return _favoritesCache.contains(identifier);
  }

  /// Get a favorite by identifier
  Future<Favorite?> getFavorite(String identifier) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableFavorites,
        where: 'identifier = ?',
        whereArgs: [identifier],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      return Favorite.fromMap(maps.first);
    } catch (e) {
      debugPrint('Error getting favorite: $e');
      return null;
    }
  }

  /// Get all favorites
  ///
  /// [orderBy] - Sort order: 'added_at DESC' (default), 'added_at ASC', 'title ASC', 'title DESC'
  /// [limit] - Maximum number of favorites to return (null = no limit)
  /// [offset] - Number of favorites to skip (for pagination)
  Future<List<Favorite>> getAllFavorites({
    String orderBy = 'added_at DESC',
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableFavorites,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => Favorite.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting all favorites: $e');
      return [];
    }
  }

  /// Get favorites by mediatype
  ///
  /// [mediatype] - Filter by mediatype (e.g., 'texts', 'movies', 'audio')
  /// [orderBy] - Sort order (default: 'added_at DESC')
  Future<List<Favorite>> getFavoritesByMediatype({
    required String mediatype,
    String orderBy = 'added_at DESC',
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableFavorites,
        where: 'mediatype = ?',
        whereArgs: [mediatype],
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => Favorite.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting favorites by mediatype: $e');
      return [];
    }
  }

  /// Get favorites added in the last N days
  Future<List<Favorite>> getRecentFavorites({int days = 7, int? limit}) async {
    try {
      final db = await _dbHelper.database;
      final cutoffTime = DateTime.now()
          .subtract(Duration(days: days))
          .millisecondsSinceEpoch;

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableFavorites,
        where: 'added_at >= ?',
        whereArgs: [cutoffTime],
        orderBy: 'added_at DESC',
        limit: limit,
      );

      return maps.map((map) => Favorite.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting recent favorites: $e');
      return [];
    }
  }

  /// Count all favorites
  Future<int> getFavoritesCount() async {
    try {
      final db = await _dbHelper.database;

      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.tableFavorites}',
        ),
      );

      return count ?? 0;
    } catch (e) {
      debugPrint('Error counting favorites: $e');
      return 0;
    }
  }

  /// Count favorites by mediatype
  ///
  /// Returns a map of mediatype -> count
  Future<Map<String, int>> getFavoritesCountByMediatype() async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT mediatype, COUNT(*) as count 
        FROM ${DatabaseHelper.tableFavorites} 
        WHERE mediatype IS NOT NULL
        GROUP BY mediatype
        ORDER BY count DESC
      ''');

      final Map<String, int> counts = {};
      for (final row in result) {
        final mediatype = row['mediatype'] as String?;
        final count = row['count'] as int;
        if (mediatype != null) {
          counts[mediatype] = count;
        }
      }

      return counts;
    } catch (e) {
      debugPrint('Error counting favorites by mediatype: $e');
      return {};
    }
  }

  /// Search favorites by title
  ///
  /// Performs case-insensitive search on title and identifier
  Future<List<Favorite>> searchFavorites({
    required String query,
    String orderBy = 'added_at DESC',
    int? limit,
  }) async {
    try {
      final db = await _dbHelper.database;
      final searchQuery = '%${query.toLowerCase()}%';

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableFavorites,
        where: 'LOWER(title) LIKE ? OR LOWER(identifier) LIKE ?',
        whereArgs: [searchQuery, searchQuery],
        orderBy: orderBy,
        limit: limit,
      );

      return maps.map((map) => Favorite.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error searching favorites: $e');
      return [];
    }
  }

  /// Clear all favorites
  ///
  /// Use with caution! This will delete all favorited items.
  /// Returns the number of favorites deleted.
  Future<int> clearAllFavorites() async {
    try {
      final db = await _dbHelper.database;

      final count = await db.delete(DatabaseHelper.tableFavorites);

      // Clear cache
      _favoritesCache.clear();

      debugPrint('Cleared all favorites (deleted $count items)');
      return count;
    } catch (e) {
      debugPrint('Error clearing favorites: $e');
      return 0;
    }
  }

  /// Delete favorites older than N days
  ///
  /// Useful for cleaning up old favorites automatically
  /// Returns the number of favorites deleted
  Future<int> deleteOldFavorites({required int days}) async {
    try {
      final db = await _dbHelper.database;
      final cutoffTime = DateTime.now()
          .subtract(Duration(days: days))
          .millisecondsSinceEpoch;

      final count = await db.delete(
        DatabaseHelper.tableFavorites,
        where: 'added_at < ?',
        whereArgs: [cutoffTime],
      );

      // Reinitialize cache to reflect deletions
      _cacheInitialized = false;
      await _initializeCache();

      debugPrint('Deleted $count favorites older than $days days');
      return count;
    } catch (e) {
      debugPrint('Error deleting old favorites: $e');
      return 0;
    }
  }

  /// Export favorites as JSON
  ///
  /// Useful for backup or sharing favorites
  Future<List<Map<String, dynamic>>> exportFavorites() async {
    try {
      final favorites = await getAllFavorites();
      return favorites.map((f) => f.toMap()).toList();
    } catch (e) {
      debugPrint('Error exporting favorites: $e');
      return [];
    }
  }

  /// Import favorites from JSON
  ///
  /// [favorites] - List of favorite maps to import
  /// [replaceExisting] - If true, existing favorites will be replaced
  /// Returns the number of favorites imported
  Future<int> importFavorites({
    required List<Map<String, dynamic>> favorites,
    bool replaceExisting = false,
  }) async {
    try {
      final db = await _dbHelper.database;
      int importedCount = 0;

      for (final map in favorites) {
        final favorite = Favorite.fromMap(map);

        final exists = await isFavorited(favorite.identifier);
        if (!exists || replaceExisting) {
          await db.insert(
            DatabaseHelper.tableFavorites,
            favorite.toMap(),
            conflictAlgorithm: replaceExisting
                ? ConflictAlgorithm.replace
                : ConflictAlgorithm.ignore,
          );
          importedCount++;
        }
      }

      // Reinitialize cache
      _cacheInitialized = false;
      await _initializeCache();

      debugPrint('Imported $importedCount favorites');
      return importedCount;
    } catch (e) {
      debugPrint('Error importing favorites: $e');
      return 0;
    }
  }

  /// Get statistics about favorites
  Future<Map<String, dynamic>> getFavoritesStats() async {
    try {
      final totalCount = await getFavoritesCount();
      final countsByMediatype = await getFavoritesCountByMediatype();
      final recentCount = (await getRecentFavorites(days: 7)).length;

      // Get oldest and newest favorites
      final oldest = await getAllFavorites(orderBy: 'added_at ASC', limit: 1);
      final newest = await getAllFavorites(orderBy: 'added_at DESC', limit: 1);

      return {
        'total_count': totalCount,
        'counts_by_mediatype': countsByMediatype,
        'recent_count': recentCount,
        'oldest_favorite': oldest.isNotEmpty
            ? oldest.first.addedAt.toIso8601String()
            : null,
        'newest_favorite': newest.isNotEmpty
            ? newest.first.addedAt.toIso8601String()
            : null,
        'most_popular_mediatype': countsByMediatype.isNotEmpty
            ? countsByMediatype.entries
                  .reduce((a, b) => a.value > b.value ? a : b)
                  .key
            : null,
      };
    } catch (e) {
      debugPrint('Error getting favorites stats: $e');
      return {};
    }
  }
}
