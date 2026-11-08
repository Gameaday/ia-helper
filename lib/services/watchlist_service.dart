import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/watchlist_entry.dart';

/// Watchlist service (#91): local-only tracking of archive.org items for
/// new uploads.
///
/// Checks happen on demand — when the watchlist screen opens or the user
/// taps refresh — by comparing the item's current file count against the
/// last stored snapshot. No background polling, no push server, no
/// notifications bill.
class WatchlistService extends ChangeNotifier {
  WatchlistService._internal({
    http.Client? httpClient,
    Future<Database> Function()? dbOverride,
  }) : _httpClient = httpClient ?? http.Client(),
       _dbOverride = dbOverride;

  static WatchlistService? _instance;

  /// Singleton for app use.
  static WatchlistService get instance =>
      _instance ??= WatchlistService._internal();

  /// Test factory with an in-memory database and/or injected HTTP client.
  @visibleForTesting
  factory WatchlistService.test({
    http.Client? httpClient,
    Future<Database> Function()? dbOverride,
  }) {
    return WatchlistService._internal(
      httpClient: httpClient,
      dbOverride: dbOverride,
    );
  }

  final http.Client _httpClient;
  final Future<Database> Function()? _dbOverride;

  Future<Database> get _database async =>
      _dbOverride?.call() ?? DatabaseHelper.instance.database;

  bool _isChecking = false;

  /// Whether a check-all pass is in flight (drives progress UI).
  bool get isChecking => _isChecking;

  /// Add an item to the watchlist.
  ///
  /// Returns true when the item was newly added; false when it was
  /// already watched.
  Future<bool> addEntry({
    required String identifier,
    String? title,
    String? mediatype,
    Map<String, dynamic>? metadataJson,
  }) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('identifier cannot be empty');
    }

    final db = await _database;
    final entry = WatchlistEntry(
      identifier: trimmed,
      title: title,
      mediatype: mediatype,
      addedAt: DateTime.now(),
      metadataJson: metadataJson,
    );

    final existing = await db.query(
      DatabaseHelper.tableWatchlist,
      where: 'identifier = ?',
      whereArgs: [trimmed],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return false;
    }

    await db.insert(
      DatabaseHelper.tableWatchlist,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    notifyListeners();
    return true;
  }

  /// Remove an item from the watchlist.
  ///
  /// Returns true when a row was deleted.
  Future<bool> removeEntry(String identifier) async {
    final db = await _database;
    final count = await db.delete(
      DatabaseHelper.tableWatchlist,
      where: 'identifier = ?',
      whereArgs: [identifier],
    );
    if (count > 0) notifyListeners();
    return count > 0;
  }

  /// Whether the identifier is currently watched.
  Future<bool> isWatched(String identifier) async =>
      await getEntry(identifier) != null;

  /// Get a single entry, or null when not watched.
  Future<WatchlistEntry?> getEntry(String identifier) async {
    final db = await _database;
    final maps = await db.query(
      DatabaseHelper.tableWatchlist,
      where: 'identifier = ?',
      whereArgs: [identifier],
      limit: 1,
    );
    return maps.isEmpty ? null : WatchlistEntry.fromMap(maps.first);
  }

  /// All watched items, freshest news first.
  Future<List<WatchlistEntry>> getAllEntries() async {
    final db = await _database;
    final maps = await db.query(
      DatabaseHelper.tableWatchlist,
      orderBy: 'new_file_count DESC, last_changed_at DESC NULLS LAST, '
          'added_at DESC',
    );
    return maps.map(WatchlistEntry.fromMap).toList();
  }

  /// Check a single entry against archive.org and store the delta.
  ///
  /// The first check (or [resetBaseline]) establishes the baseline
  /// without flagging new files. Throws when the item cannot be found or
  /// the network fails — the stored row is left untouched in that case.
  Future<WatchlistEntry> checkEntry(
    WatchlistEntry entry, {
    bool resetBaseline = false,
  }) async {
    final response = await _httpClient
        .get(Uri.parse('https://archive.org/metadata/${entry.identifier}'))
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception(
        'Archive.org returned ${response.statusCode} for ${entry.identifier}',
      );
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Could not read metadata for ${entry.identifier}');
    }

    // archive.org answers {} for identifiers that do not exist.
    if (!json.containsKey('metadata') && !json.containsKey('files')) {
      throw Exception('${entry.identifier} was not found on archive.org');
    }

    final files = json['files'];
    final currentFileCount = files is List ? files.length : 0;

    final metadata = json['metadata'];
    final metaMap = metadata is Map<String, dynamic> ? metadata : null;
    final remoteTitle = metaMap?['title'] as String?;
    final remoteMediatype = metaMap?['mediatype'] as String?;

    final hasBaseline = entry.hasBaseline && !resetBaseline;
    final delta = currentFileCount - entry.knownFileCount;
    final newCount = hasBaseline && delta > 0 ? delta : 0;
    final now = DateTime.now();

    final updated = entry.copyWith(
      title: entry.title ?? remoteTitle,
      mediatype: entry.mediatype ?? remoteMediatype,
      knownFileCount: currentFileCount,
      newFileCount: newCount,
      lastCheckedAt: now,
      lastChangedAt: newCount > 0 ? now : entry.lastChangedAt,
    );

    final db = await _database;
    await db.update(
      DatabaseHelper.tableWatchlist,
      updated.toMap(),
      where: 'identifier = ?',
      whereArgs: [entry.identifier],
    );
    notifyListeners();
    return updated;
  }

  /// Check every watched item. Entries are checked sequentially; a
  /// failing item is skipped without aborting the pass.
  ///
  /// Returns the number of items that now have unacknowledged new files.
  Future<int> checkAll() async {
    if (_isChecking) return 0;

    _isChecking = true;
    notifyListeners();

    var withNewFiles = 0;
    try {
      final entries = await getAllEntries();
      for (final entry in entries) {
        try {
          final updated = await checkEntry(entry);
          if (updated.hasNewFiles) withNewFiles++;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Watchlist check failed for ${entry.identifier}: $e');
          }
        }
      }
    } finally {
      _isChecking = false;
      notifyListeners();
    }

    return withNewFiles;
  }

  /// Acknowledge new files (called when the user opens the item).
  Future<void> acknowledgeNewFiles(String identifier) async {
    final db = await _database;
    final existing = await getEntry(identifier);
    if (existing == null || !existing.hasNewFiles) return;

    await db.update(
      DatabaseHelper.tableWatchlist,
      existing.copyWith(newFileCount: 0).toMap(),
      where: 'identifier = ?',
      whereArgs: [identifier],
    );
    notifyListeners();
  }

  /// Clear the entire watchlist. Returns the number of removed rows.
  Future<int> clearAll() async {
    final db = await _database;
    final count = await db.delete(DatabaseHelper.tableWatchlist);
    if (count > 0) notifyListeners();
    return count;
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}
