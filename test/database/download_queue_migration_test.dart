import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Versioned migration tests for the app schema (#84).
///
/// Every schema bump must keep these green: fresh install creates the
/// current schema, and each upgrade chain preserves existing data.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath, version: 1);
  });

  tearDown(() async {
    await db.close();
  });

  Future<Set<String>> tableNames() async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    return rows.map((r) => r['name'] as String).toSet();
  }

  test('fresh install creates download_queue with its indexes', () async {
    await DatabaseHelper.instance.debugCreateSchema(db);

    final names = await tableNames();
    expect(names, contains(DatabaseHelper.tableDownloadQueue));

    final indexes = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'index' AND tbl_name = ?",
      [DatabaseHelper.tableDownloadQueue],
    );
    final indexNames = indexes.map((r) => r['name'] as String).toSet();
    expect(indexNames, containsAll(['idx_download_queue_status', 'idx_download_queue_identifier']));
  });

  test('v6 -> v7 adds download_queue and keeps download_tasks data', () async {
    // Fabricate a v6 database: download_tasks plus one row.
    await db.execute('''
      CREATE TABLE download_tasks (
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
        scheduled_time INTEGER,
        status TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        error_message TEXT,
        created_at TEXT NOT NULL,
        started_at INTEGER,
        completed_at INTEGER,
        updated_at TEXT NOT NULL,
        metadata TEXT,
        selected_files TEXT
      )
    ''');
    await db.insert('download_tasks', {
      'id': 'task-1',
      'identifier': 'archive-1',
      'url': 'https://example.com/a.pdf',
      'save_path': '/downloads',
      'file_name': 'a.pdf',
      'total_bytes': 100,
      'status': 'paused',
      'created_at': '2026-01-01T00:00:00.000',
      'updated_at': '2026-01-01T00:00:00.000',
    });

    await DatabaseHelper.instance.debugUpgrade(db, 6, 7);

    expect(await tableNames(), contains(DatabaseHelper.tableDownloadQueue));
    final rows = await db.query('download_tasks');
    expect(rows.single['id'], 'task-1');
    expect(rows.single['status'], 'paused');
  });

  test('v7 -> v8 adds the watchlist table and keeps v7 data', () async {
    // Fabricate a v7 database: download_tasks (v6 schema) plus one row.
    // (oldVersion = 7 skips every earlier migration block, so this is
    // exactly the surface the v7 -> v8 upgrade operates on.)
    await db.execute('''
      CREATE TABLE download_tasks (
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
        scheduled_time INTEGER,
        status TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        error_message TEXT,
        created_at TEXT NOT NULL,
        started_at INTEGER,
        completed_at INTEGER,
        updated_at TEXT NOT NULL,
        metadata TEXT,
        selected_files TEXT
      )
    ''');
    await db.insert('download_tasks', {
      'id': 'task-1',
      'identifier': 'archive-1',
      'url': 'https://example.com/a.pdf',
      'save_path': '/downloads',
      'file_name': 'a.pdf',
      'total_bytes': 100,
      'status': 'paused',
      'created_at': '2026-01-01T00:00:00.000',
      'updated_at': '2026-01-01T00:00:00.000',
    });

    await DatabaseHelper.instance.debugUpgrade(db, 7, 8);

    // The watchlist table exists (#91)
    expect(await tableNames(), contains(DatabaseHelper.tableWatchlist));

    // v7 data is untouched
    final rows = await db.query('download_tasks');
    expect(rows.single['id'], 'task-1');
    expect(rows.single['status'], 'paused');

    // The new table is usable in the exact shape WatchlistService writes:
    // a first check stores the -1 baseline ("not yet known").
    await db.insert(DatabaseHelper.tableWatchlist, {
      'identifier': 'arch-1',
      'title': 'Archive 1',
      'added_at': 1,
      'known_file_count': -1,
      'new_file_count': 0,
    });
    final wl = await db.query(DatabaseHelper.tableWatchlist);
    expect(wl.single['identifier'], 'arch-1');
    expect(wl.single['known_file_count'], -1);

    // Fresh-install and migration DDL share _createWatchlistTable; the
    // index is the marker that the shared helper ran.
    final indexes = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'index' AND tbl_name = ?",
      [DatabaseHelper.tableWatchlist],
    );
    expect(
      indexes.map((r) => r['name'] as String),
      contains('idx_watchlist_added_at'),
    );
  });

  test('v1 -> v7 full chain creates every table and preserves v1 data', () async {
    // Fabricate a v1 database: cached_metadata without the etag column
    // (etag was added by the v2 -> v3 migration).
    await db.execute('''
      CREATE TABLE cached_metadata (
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
        media_type TEXT
      )
    ''');
    await db.insert('cached_metadata', {
      'identifier': 'v1-item',
      'metadata_json': '{}',
      'cached_at': 1,
      'last_accessed': 1,
    });

    await DatabaseHelper.instance.debugUpgrade(db, 1, 7);

    final names = await tableNames();
    const expectedTables = [
      DatabaseHelper.tableCachedMetadata,
      DatabaseHelper.tablePreviewCache,
      DatabaseHelper.tableFavorites,
      DatabaseHelper.tableCollections,
      DatabaseHelper.tableCollectionItems,
      DatabaseHelper.tableSearchHistory,
      DatabaseHelper.tableSavedSearches,
      DatabaseHelper.tableDownloadTasks,
      DatabaseHelper.tableDownloadQueue,
    ];
    for (final table in expectedTables) {
      expect(names, contains(table),
          reason: 'missing table after upgrade: $table');
    }

    final rows = await db.query(DatabaseHelper.tableCachedMetadata);
    expect(rows.single['identifier'], 'v1-item');

    final columns = await db.rawQuery('PRAGMA table_info(cached_metadata)');
    final columnNames = columns.map((c) => c['name'] as String).toSet();
    expect(columnNames, contains('etag'));
  });
}
