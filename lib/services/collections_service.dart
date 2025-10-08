import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/collection.dart';

/// Service for managing collections of archives
///
/// Provides CRUD operations for creating and managing collections.
/// Collections can be regular (manually curated) or smart (auto-populated).
/// Uses SQLite for persistent storage with proper relationship management.
///
/// Features:
/// - Create/rename/delete collections
/// - Add/remove items to/from collections
/// - Get collections and their items
/// - Count items in collections
/// - Smart collection support (future enhancement)
class CollectionsService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Singleton pattern
  CollectionsService._privateConstructor();
  static final CollectionsService instance =
      CollectionsService._privateConstructor();

  // MARK: - Collection CRUD Operations

  /// Create a new collection
  ///
  /// Returns the ID of the created collection, or null if creation failed
  Future<int?> createCollection({
    required String name,
    String? description,
    String? icon,
    Color? color,
    bool isSmart = false,
    Map<String, dynamic>? smartRulesJson,
  }) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();

      final collection = Collection(
        name: name,
        description: description,
        icon: icon,
        color: color,
        createdAt: now,
        updatedAt: now,
        isSmart: isSmart,
        smartRulesJson: smartRulesJson,
      );

      final id = await db.insert(
        DatabaseHelper.tableCollections,
        collection.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      debugPrint('Created collection: $name (id: $id)');
      return id;
    } catch (e) {
      debugPrint('Error creating collection: $e');
      return null;
    }
  }

  /// Update an existing collection
  ///
  /// Returns true if updated successfully
  Future<bool> updateCollection({
    required int id,
    String? name,
    String? description,
    String? icon,
    Color? color,
    bool? isSmart,
    Map<String, dynamic>? smartRulesJson,
  }) async {
    try {
      final db = await _dbHelper.database;
      final existing = await getCollection(id);

      if (existing == null) {
        debugPrint('Collection $id not found');
        return false;
      }

      final updated = existing.copyWith(
        name: name,
        description: description,
        icon: icon,
        color: color,
        updatedAt: DateTime.now(),
        isSmart: isSmart,
        smartRulesJson: smartRulesJson,
      );

      final count = await db.update(
        DatabaseHelper.tableCollections,
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      debugPrint('Updated collection $id (rows affected: $count)');
      return count > 0;
    } catch (e) {
      debugPrint('Error updating collection: $e');
      return false;
    }
  }

  /// Rename a collection
  ///
  /// Convenience method for updating just the name
  Future<bool> renameCollection({
    required int id,
    required String newName,
  }) async {
    return updateCollection(id: id, name: newName);
  }

  /// Delete a collection
  ///
  /// Also deletes all items in the collection (CASCADE)
  /// Returns true if deleted successfully
  Future<bool> deleteCollection(int id) async {
    try {
      final db = await _dbHelper.database;

      final count = await db.delete(
        DatabaseHelper.tableCollections,
        where: 'id = ?',
        whereArgs: [id],
      );

      debugPrint('Deleted collection $id (rows affected: $count)');
      return count > 0;
    } catch (e) {
      debugPrint('Error deleting collection: $e');
      return false;
    }
  }

  /// Get a collection by ID
  Future<Collection?> getCollection(int id) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableCollections,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      return Collection.fromMap(maps.first);
    } catch (e) {
      debugPrint('Error getting collection: $e');
      return null;
    }
  }

  /// Get all collections
  ///
  /// [orderBy] - Sort order: 'created_at DESC' (default), 'created_at ASC', 'name ASC', 'name DESC', 'updated_at DESC'
  /// [includeItemCount] - If true, adds 'item_count' to each collection map
  Future<List<Collection>> getAllCollections({
    String orderBy = 'created_at DESC',
    bool includeItemCount = false,
  }) async {
    try {
      final db = await _dbHelper.database;

      List<Map<String, dynamic>> maps;

      if (includeItemCount) {
        // Join with collection_items to get count
        maps = await db.rawQuery('''
          SELECT c.*, COUNT(ci.identifier) as item_count
          FROM ${DatabaseHelper.tableCollections} c
          LEFT JOIN ${DatabaseHelper.tableCollectionItems} ci ON c.id = ci.collection_id
          GROUP BY c.id
          ORDER BY ${_sanitizeOrderBy(orderBy)}
        ''');
      } else {
        maps = await db.query(
          DatabaseHelper.tableCollections,
          orderBy: _sanitizeOrderBy(orderBy),
        );
      }

      return maps.map((map) => Collection.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting all collections: $e');
      return [];
    }
  }

  /// Search collections by name
  Future<List<Collection>> searchCollections({
    required String query,
    String orderBy = 'name ASC',
  }) async {
    try {
      final db = await _dbHelper.database;
      final searchQuery = '%${query.toLowerCase()}%';

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableCollections,
        where: 'LOWER(name) LIKE ? OR LOWER(description) LIKE ?',
        whereArgs: [searchQuery, searchQuery],
        orderBy: _sanitizeOrderBy(orderBy),
      );

      return maps.map((map) => Collection.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error searching collections: $e');
      return [];
    }
  }

  // MARK: - Collection Items Management

  /// Add an item to a collection
  ///
  /// Returns true if added successfully, false if already in collection
  Future<bool> addItemToCollection({
    required int collectionId,
    required String identifier,
  }) async {
    try {
      final db = await _dbHelper.database;

      // Check if item already in collection
      if (await isItemInCollection(
        collectionId: collectionId,
        identifier: identifier,
      )) {
        debugPrint('Item $identifier already in collection $collectionId');
        return false;
      }

      final item = CollectionItem(
        collectionId: collectionId,
        identifier: identifier,
        addedAt: DateTime.now(),
      );

      await db.insert(
        DatabaseHelper.tableCollectionItems,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      // Update collection's updated_at timestamp
      await db.update(
        DatabaseHelper.tableCollections,
        {'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [collectionId],
      );

      debugPrint('Added item $identifier to collection $collectionId');
      return true;
    } catch (e) {
      debugPrint('Error adding item to collection: $e');
      return false;
    }
  }

  /// Add multiple items to a collection
  ///
  /// Returns the number of items successfully added
  Future<int> addItemsToCollection({
    required int collectionId,
    required List<String> identifiers,
  }) async {
    int addedCount = 0;

    for (final identifier in identifiers) {
      final success = await addItemToCollection(
        collectionId: collectionId,
        identifier: identifier,
      );
      if (success) addedCount++;
    }

    return addedCount;
  }

  /// Remove an item from a collection
  ///
  /// Returns true if removed successfully
  Future<bool> removeItemFromCollection({
    required int collectionId,
    required String identifier,
  }) async {
    try {
      final db = await _dbHelper.database;

      final count = await db.delete(
        DatabaseHelper.tableCollectionItems,
        where: 'collection_id = ? AND identifier = ?',
        whereArgs: [collectionId, identifier],
      );

      // Update collection's updated_at timestamp
      if (count > 0) {
        await db.update(
          DatabaseHelper.tableCollections,
          {'updated_at': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [collectionId],
        );
      }

      debugPrint(
        'Removed item $identifier from collection $collectionId (rows: $count)',
      );
      return count > 0;
    } catch (e) {
      debugPrint('Error removing item from collection: $e');
      return false;
    }
  }

  /// Check if an item is in a collection
  Future<bool> isItemInCollection({
    required int collectionId,
    required String identifier,
  }) async {
    try {
      final db = await _dbHelper.database;

      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          '''
          SELECT COUNT(*) 
          FROM ${DatabaseHelper.tableCollectionItems}
          WHERE collection_id = ? AND identifier = ?
        ''',
          [collectionId, identifier],
        ),
      );

      return (count ?? 0) > 0;
    } catch (e) {
      debugPrint('Error checking if item in collection: $e');
      return false;
    }
  }

  /// Get all items in a collection
  ///
  /// Returns a list of identifiers
  Future<List<String>> getCollectionItems({
    required int collectionId,
    String orderBy = 'added_at DESC',
  }) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableCollectionItems,
        columns: ['identifier'],
        where: 'collection_id = ?',
        whereArgs: [collectionId],
        orderBy: _sanitizeOrderBy(orderBy),
      );

      return maps.map((map) => map['identifier'] as String).toList();
    } catch (e) {
      debugPrint('Error getting collection items: $e');
      return [];
    }
  }

  /// Get all CollectionItem objects for a collection
  Future<List<CollectionItem>> getCollectionItemDetails({
    required int collectionId,
    String orderBy = 'added_at DESC',
  }) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableCollectionItems,
        where: 'collection_id = ?',
        whereArgs: [collectionId],
        orderBy: _sanitizeOrderBy(orderBy),
      );

      return maps.map((map) => CollectionItem.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting collection item details: $e');
      return [];
    }
  }

  /// Get all collections that contain a specific item
  Future<List<Collection>> getCollectionsForItem(String identifier) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT c.* 
        FROM ${DatabaseHelper.tableCollections} c
        INNER JOIN ${DatabaseHelper.tableCollectionItems} ci ON c.id = ci.collection_id
        WHERE ci.identifier = ?
        ORDER BY c.name ASC
      ''',
        [identifier],
      );

      return maps.map((map) => Collection.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting collections for item: $e');
      return [];
    }
  }

  /// Count items in a collection
  Future<int> getCollectionItemCount(int collectionId) async {
    try {
      final db = await _dbHelper.database;

      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          '''
          SELECT COUNT(*) 
          FROM ${DatabaseHelper.tableCollectionItems}
          WHERE collection_id = ?
        ''',
          [collectionId],
        ),
      );

      return count ?? 0;
    } catch (e) {
      debugPrint('Error counting collection items: $e');
      return 0;
    }
  }

  /// Clear all items from a collection
  ///
  /// Returns the number of items deleted
  Future<int> clearCollection(int collectionId) async {
    try {
      final db = await _dbHelper.database;

      final count = await db.delete(
        DatabaseHelper.tableCollectionItems,
        where: 'collection_id = ?',
        whereArgs: [collectionId],
      );

      // Update collection's updated_at timestamp
      if (count > 0) {
        await db.update(
          DatabaseHelper.tableCollections,
          {'updated_at': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [collectionId],
        );
      }

      debugPrint('Cleared collection $collectionId ($count items removed)');
      return count;
    } catch (e) {
      debugPrint('Error clearing collection: $e');
      return 0;
    }
  }

  // MARK: - Statistics and Utilities

  /// Get count of all collections
  Future<int> getCollectionsCount() async {
    try {
      final db = await _dbHelper.database;

      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.tableCollections}',
        ),
      );

      return count ?? 0;
    } catch (e) {
      debugPrint('Error counting collections: $e');
      return 0;
    }
  }

  /// Get statistics about collections
  Future<Map<String, dynamic>> getCollectionsStats() async {
    try {
      final db = await _dbHelper.database;

      final totalCollections = await getCollectionsCount();

      // Get total items across all collections
      final totalItems =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM ${DatabaseHelper.tableCollectionItems}',
            ),
          ) ??
          0;

      // Get largest collection
      final largest = await db.rawQuery('''
        SELECT c.id, c.name, COUNT(ci.identifier) as item_count
        FROM ${DatabaseHelper.tableCollections} c
        LEFT JOIN ${DatabaseHelper.tableCollectionItems} ci ON c.id = ci.collection_id
        GROUP BY c.id
        ORDER BY item_count DESC
        LIMIT 1
      ''');

      // Get most recently updated collection
      final recentCollections = await getAllCollections(
        orderBy: 'updated_at DESC',
      );

      return {
        'total_collections': totalCollections,
        'total_items': totalItems,
        'average_items_per_collection': totalCollections > 0
            ? (totalItems / totalCollections).toStringAsFixed(1)
            : '0',
        'largest_collection': largest.isNotEmpty
            ? {
                'id': largest.first['id'],
                'name': largest.first['name'],
                'item_count': largest.first['item_count'],
              }
            : null,
        'most_recent_collection': recentCollections.isNotEmpty
            ? recentCollections.first.name
            : null,
      };
    } catch (e) {
      debugPrint('Error getting collections stats: $e');
      return {};
    }
  }

  /// Duplicate a collection
  ///
  /// Creates a copy of the collection with all its items
  /// Returns the ID of the new collection, or null if duplication failed
  Future<int?> duplicateCollection({
    required int sourceCollectionId,
    String? newName,
  }) async {
    try {
      final source = await getCollection(sourceCollectionId);
      if (source == null) return null;

      // Create new collection with modified name
      final newCollectionId = await createCollection(
        name: newName ?? '${source.name} (Copy)',
        description: source.description,
        icon: source.icon,
        color: source.color,
        isSmart: source.isSmart,
        smartRulesJson: source.smartRulesJson,
      );

      if (newCollectionId == null) return null;

      // Copy all items
      final items = await getCollectionItems(collectionId: sourceCollectionId);
      await addItemsToCollection(
        collectionId: newCollectionId,
        identifiers: items,
      );

      debugPrint(
        'Duplicated collection $sourceCollectionId to $newCollectionId',
      );
      return newCollectionId;
    } catch (e) {
      debugPrint('Error duplicating collection: $e');
      return null;
    }
  }

  // MARK: - Helper Methods

  /// Sanitize orderBy clause to prevent SQL injection
  String _sanitizeOrderBy(String orderBy) {
    // Only allow specific column names and directions
    final allowedColumns = [
      'id',
      'name',
      'created_at',
      'updated_at',
      'added_at',
    ];
    final allowedDirections = ['ASC', 'DESC'];

    final parts = orderBy.trim().split(' ');
    if (parts.isEmpty || parts.length > 2) return 'created_at DESC';

    final column = parts[0].toLowerCase();
    final direction = parts.length > 1 ? parts[1].toUpperCase() : 'DESC';

    if (!allowedColumns.contains(column) ||
        !allowedDirections.contains(direction)) {
      return 'created_at DESC';
    }

    return '$column $direction';
  }
}
