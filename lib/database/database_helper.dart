import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/download_task.dart';
import '../models/download_progress.dart';

// Web platform check
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' 
    if (dart.library.io) 'package:sqflite/sqflite.dart';

/// Database helper for managing SQLite database operations
/// Used for metadata caching and file preview caching with versioning and migrations
class DatabaseHelper {
  static const String _databaseName = 'ia_helper.db';
  static const int _databaseVersion = 6;

  // Table names
  static const String tableCachedMetadata = 'cached_metadata';
  static const String tablePreviewCache = 'preview_cache';
  static const String tableFavorites = 'favorites';
  static const String tableCollections = 'collections';
  static const String tableCollectionItems = 'collection_items';
  static const String tableSearchHistory = 'search_history';
  static const String tableSavedSearches = 'saved_searches';
  static const String tableDownloadTasks = 'download_tasks';

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  /// Get database instance, creating it if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database with schema
  Future<Database> _initDatabase() async {
    try {
      // Initialize web database factory if on web
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
      }
      
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);

      debugPrint('Opening database at: $path');

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  /// Configure database settings before opening
  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create database schema
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating database schema version $version');

    // Cached archive metadata table
    await db.execute('''
      CREATE TABLE $tableCachedMetadata (
        identifier TEXT PRIMARY KEY,
        metadata_json TEXT NOT NULL,
        cached_at INTEGER NOT NULL,
        last_accessed INTEGER NOT NULL,
        last_synced INTEGER,
        version INTEGER NOT NULL DEFAULT 1,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        file_count INTEGER NOT NULL DEFAULT 0,
        total_size INTEGER NOT NULL DEFAULT 0,
        creator TEXT,
        title TEXT,
        media_type TEXT,
        etag TEXT,
        UNIQUE(identifier)
      )
    ''');

    // Create indexes for efficient queries
    await db.execute('''
      CREATE INDEX idx_cached_metadata_last_accessed 
      ON $tableCachedMetadata(last_accessed DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_cached_metadata_is_pinned 
      ON $tableCachedMetadata(is_pinned)
    ''');

    await db.execute('''
      CREATE INDEX idx_cached_metadata_cached_at 
      ON $tableCachedMetadata(cached_at DESC)
    ''');

    // File preview cache table
    await db.execute('''
      CREATE TABLE $tablePreviewCache (
        identifier TEXT NOT NULL,
        file_name TEXT NOT NULL,
        preview_type TEXT NOT NULL,
        text_content TEXT,
        preview_data BLOB,
        cached_at INTEGER NOT NULL,
        file_size INTEGER,
        PRIMARY KEY (identifier, file_name)
      )
    ''');

    // Create indexes for preview cache
    await db.execute('''
      CREATE INDEX idx_preview_cache_identifier 
      ON $tablePreviewCache(identifier)
    ''');

    await db.execute('''
      CREATE INDEX idx_preview_cache_cached_at 
      ON $tablePreviewCache(cached_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_preview_cache_type 
      ON $tablePreviewCache(preview_type)
    ''');

    // Favorites table (Phase 4 Task 1)
    await db.execute('''
      CREATE TABLE $tableFavorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        identifier TEXT UNIQUE NOT NULL,
        title TEXT,
        mediatype TEXT,
        added_at INTEGER NOT NULL,
        metadata_json TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_favorites_mediatype 
      ON $tableFavorites(mediatype)
    ''');

    await db.execute('''
      CREATE INDEX idx_favorites_added_at 
      ON $tableFavorites(added_at DESC)
    ''');

    // Collections table (Phase 4 Task 1)
    await db.execute('''
      CREATE TABLE $tableCollections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        icon TEXT,
        color INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_smart INTEGER DEFAULT 0,
        smart_rules_json TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_collections_created_at 
      ON $tableCollections(created_at DESC)
    ''');

    // Collection items table (Phase 4 Task 1)
    await db.execute('''
      CREATE TABLE $tableCollectionItems (
        collection_id INTEGER NOT NULL,
        identifier TEXT NOT NULL,
        added_at INTEGER NOT NULL,
        PRIMARY KEY (collection_id, identifier),
        FOREIGN KEY (collection_id) REFERENCES $tableCollections(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_collection_items_identifier 
      ON $tableCollectionItems(identifier)
    ''');

    await db.execute('''
      CREATE INDEX idx_collection_items_collection_id 
      ON $tableCollectionItems(collection_id)
    ''');

    // Search history table (Phase 4 Task 2)
    await db.execute('''
      CREATE TABLE $tableSearchHistory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        result_count INTEGER,
        mediatype TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_search_history_timestamp 
      ON $tableSearchHistory(timestamp DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_search_history_query 
      ON $tableSearchHistory(query)
    ''');

    // Saved searches table (Phase 4 Task 2)
    await db.execute('''
      CREATE TABLE $tableSavedSearches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        query_json TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_used_at INTEGER,
        use_count INTEGER NOT NULL DEFAULT 0,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        tags_json TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_saved_searches_created_at 
      ON $tableSavedSearches(created_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_saved_searches_last_used_at 
      ON $tableSavedSearches(last_used_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_saved_searches_is_pinned 
      ON $tableSavedSearches(is_pinned DESC, last_used_at DESC)
    ''');

    // Download tasks table (Phase 4 Task 3)
    await db.execute('''
      CREATE TABLE $tableDownloadTasks (
        id TEXT PRIMARY KEY,
        identifier TEXT NOT NULL,
        url TEXT NOT NULL,
        save_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        partial_bytes INTEGER NOT NULL DEFAULT 0,
        etag TEXT,
        last_modified TEXT,
        total_bytes INTEGER NOT NULL,
        priority TEXT NOT NULL DEFAULT 'normal',
        network_requirement TEXT NOT NULL DEFAULT 'any',
        scheduled_time TEXT,
        status TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        error_message TEXT,
        created_at TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT,
        updated_at TEXT NOT NULL,
        metadata TEXT,
        selected_files TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_download_tasks_status 
      ON $tableDownloadTasks(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_download_tasks_scheduled 
      ON $tableDownloadTasks(scheduled_time)
    ''');

    await db.execute('''
      CREATE INDEX idx_download_tasks_priority 
      ON $tableDownloadTasks(priority DESC, created_at ASC)
    ''');

    await db.execute('''
      CREATE INDEX idx_download_tasks_identifier 
      ON $tableDownloadTasks(identifier)
    ''');

    debugPrint('Database schema created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');

    // Migration from version 1 to version 2: Add preview cache table
    if (oldVersion < 2) {
      debugPrint('Migrating to version 2: Adding preview_cache table');

      await db.execute('''
        CREATE TABLE $tablePreviewCache (
          identifier TEXT NOT NULL,
          file_name TEXT NOT NULL,
          preview_type TEXT NOT NULL,
          text_content TEXT,
          preview_data BLOB,
          cached_at INTEGER NOT NULL,
          file_size INTEGER,
          PRIMARY KEY (identifier, file_name)
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_preview_cache_identifier 
        ON $tablePreviewCache(identifier)
      ''');

      await db.execute('''
        CREATE INDEX idx_preview_cache_cached_at 
        ON $tablePreviewCache(cached_at DESC)
      ''');

      await db.execute('''
        CREATE INDEX idx_preview_cache_type 
        ON $tablePreviewCache(preview_type)
      ''');

      debugPrint('Migration to version 2 completed successfully');
    }

    // Migration from version 2 to version 3: Add etag column to cached_metadata
    if (oldVersion < 3) {
      debugPrint('Migrating to version 3: Adding etag column');

      await db.execute('''
        ALTER TABLE $tableCachedMetadata ADD COLUMN etag TEXT
      ''');

      debugPrint('Migration to version 3 completed successfully');
    }

    // Migration from version 3 to version 4: Add favorites and collections tables
    if (oldVersion < 4) {
      debugPrint(
        'Migrating to version 4: Adding favorites and collections tables',
      );

      // Favorites table
      await db.execute('''
        CREATE TABLE $tableFavorites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          identifier TEXT UNIQUE NOT NULL,
          title TEXT,
          mediatype TEXT,
          added_at INTEGER NOT NULL,
          metadata_json TEXT
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_favorites_mediatype 
        ON $tableFavorites(mediatype)
      ''');

      await db.execute('''
        CREATE INDEX idx_favorites_added_at 
        ON $tableFavorites(added_at DESC)
      ''');

      // Collections table
      await db.execute('''
        CREATE TABLE $tableCollections (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          icon TEXT,
          color INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          is_smart INTEGER DEFAULT 0,
          smart_rules_json TEXT
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_collections_created_at 
        ON $tableCollections(created_at DESC)
      ''');

      // Collection items table
      await db.execute('''
        CREATE TABLE $tableCollectionItems (
          collection_id INTEGER NOT NULL,
          identifier TEXT NOT NULL,
          added_at INTEGER NOT NULL,
          PRIMARY KEY (collection_id, identifier),
          FOREIGN KEY (collection_id) REFERENCES $tableCollections(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_collection_items_identifier 
        ON $tableCollectionItems(identifier)
      ''');

      await db.execute('''
        CREATE INDEX idx_collection_items_collection_id 
        ON $tableCollectionItems(collection_id)
      ''');

      debugPrint('Migration to version 4 completed successfully');
    }

    // Migration from version 4 to version 5: Add search history and saved searches tables
    if (oldVersion < 5) {
      debugPrint(
        'Migrating to version 5: Adding search history and saved searches tables',
      );

      // Search history table
      await db.execute('''
        CREATE TABLE $tableSearchHistory (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          query TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          result_count INTEGER,
          mediatype TEXT
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_search_history_timestamp 
        ON $tableSearchHistory(timestamp DESC)
      ''');

      await db.execute('''
        CREATE INDEX idx_search_history_query 
        ON $tableSearchHistory(query)
      ''');

      // Saved searches table
      await db.execute('''
        CREATE TABLE $tableSavedSearches (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          query_json TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          last_used_at INTEGER,
          use_count INTEGER NOT NULL DEFAULT 0,
          is_pinned INTEGER NOT NULL DEFAULT 0,
          tags_json TEXT
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_saved_searches_created_at 
        ON $tableSavedSearches(created_at DESC)
      ''');

      await db.execute('''
        CREATE INDEX idx_saved_searches_last_used_at 
        ON $tableSavedSearches(last_used_at DESC)
      ''');

      await db.execute('''
        CREATE INDEX idx_saved_searches_is_pinned 
        ON $tableSavedSearches(is_pinned DESC, last_used_at DESC)
      ''');

      debugPrint('Migration to version 5 completed successfully');
    }

    // Migration from version 5 to version 6: Add download tasks table for resumable downloads
    if (oldVersion < 6) {
      debugPrint('Migrating to version 6: Adding download_tasks table');

      // Download tasks table for resumable downloads and queue management
      await db.execute('''
        CREATE TABLE $tableDownloadTasks (
          id TEXT PRIMARY KEY,
          identifier TEXT NOT NULL,
          url TEXT NOT NULL,
          save_path TEXT NOT NULL,
          file_name TEXT NOT NULL,
          partial_bytes INTEGER NOT NULL DEFAULT 0,
          etag TEXT,
          last_modified TEXT,
          total_bytes INTEGER NOT NULL,
          priority TEXT NOT NULL DEFAULT 'normal',
          network_requirement TEXT NOT NULL DEFAULT 'any',
          scheduled_time TEXT,
          status TEXT NOT NULL,
          retry_count INTEGER NOT NULL DEFAULT 0,
          error_message TEXT,
          created_at TEXT NOT NULL,
          started_at TEXT,
          completed_at TEXT,
          updated_at TEXT NOT NULL,
          metadata TEXT,
          selected_files TEXT
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_download_tasks_status 
        ON $tableDownloadTasks(status)
      ''');

      await db.execute('''
        CREATE INDEX idx_download_tasks_scheduled 
        ON $tableDownloadTasks(scheduled_time)
      ''');

      await db.execute('''
        CREATE INDEX idx_download_tasks_priority 
        ON $tableDownloadTasks(priority DESC, created_at ASC)
      ''');

      await db.execute('''
        CREATE INDEX idx_download_tasks_identifier 
        ON $tableDownloadTasks(identifier)
      ''');

      debugPrint('Migration to version 6 completed successfully');
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    debugPrint('Database connection closed');
  }

  /// Delete database (useful for testing or reset)
  Future<void> deleteDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);
      await databaseFactory.deleteDatabase(path);
      _database = null;
      debugPrint('Database deleted successfully');
    } catch (e) {
      debugPrint('Error deleting database: $e');
      rethrow;
    }
  }

  /// Get database size in bytes
  Future<int> getDatabaseSize() async {
    try {
      // Since we can't easily get file size in Flutter without dart:io,
      // estimate based on row count
      final db = await database;

      // Count cached metadata
      final metadataResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableCachedMetadata',
      );
      final metadataCount = Sqflite.firstIntValue(metadataResult) ?? 0;

      // Count preview cache and sum data sizes
      final previewResult = await db.rawQuery('''
        SELECT 
          SUM(LENGTH(text_content)) as text_size,
          SUM(LENGTH(preview_data)) as blob_size
        FROM $tablePreviewCache
      ''');
      final textSize = previewResult.first['text_size'] as int? ?? 0;
      final blobSize = previewResult.first['blob_size'] as int? ?? 0;

      // Rough estimate: ~50KB per cached archive + actual preview sizes
      return (metadataCount * 50 * 1024) + textSize + blobSize;
    } catch (e) {
      debugPrint('Error getting database size: $e');
      return 0;
    }
  }

  /// Vacuum database to reclaim space after deletions
  Future<void> vacuum() async {
    try {
      final db = await database;
      await db.execute('VACUUM');
      debugPrint('Database vacuumed successfully');
    } catch (e) {
      debugPrint('Error vacuuming database: $e');
    }
  }

  // ===========================================================================
  // Download Tasks Methods (Phase 4 Task 3)
  // ===========================================================================

  /// Insert or update a download task
  Future<void> upsertDownloadTask(DownloadTask task) async {
    final db = await database;
    await db.insert(
      tableDownloadTasks,
      task.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing download task
  Future<void> updateDownloadTask(DownloadTask task) async {
    final db = await database;
    await db.update(
      tableDownloadTasks,
      task.toJson(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Get a download task by ID
  Future<DownloadTask?> getDownloadTask(String taskId) async {
    final db = await database;
    final results = await db.query(
      tableDownloadTasks,
      where: 'id = ?',
      whereArgs: [taskId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return DownloadTask.fromJson(results.first);
  }

  /// Get all download tasks with optional status filter
  Future<List<DownloadTask>> getDownloadTasks({
    DownloadStatus? status,
    int? limit,
  }) async {
    final db = await database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (status != null) {
      whereClause = 'status = ?';
      whereArgs = [status.index];
    }

    final results = await db.query(
      tableDownloadTasks,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'priority DESC, created_at ASC',
      limit: limit,
    );

    return results.map((json) => DownloadTask.fromJson(json)).toList();
  }

  /// Delete a download task
  Future<void> deleteDownloadTask(String taskId) async {
    final db = await database;
    await db.delete(tableDownloadTasks, where: 'id = ?', whereArgs: [taskId]);
  }

  /// Delete all completed tasks older than specified days
  Future<int> deleteOldCompletedTasks(int daysOld) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    return await db.delete(
      tableDownloadTasks,
      where: 'status = ? AND completed_at < ?',
      whereArgs: [
        DownloadStatus.completed.index,
        cutoffDate.millisecondsSinceEpoch,
      ],
    );
  }
}
