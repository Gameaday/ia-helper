import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/archive_metadata.dart';
import '../models/download_progress.dart';

/// A download queue entry persisted across app/OS kills (#84).
///
/// The production download path (BackgroundDownloadService) keeps its queue
/// in memory only; persisting one row per download makes a force-stop
/// mid-queue recoverable on next launch.
class PersistedDownload {
  final String downloadId;
  final String identifier;
  final String downloadPath;
  final String archiveDir;
  final DownloadProgress progress;
  final List<String> selectedFiles;
  final Set<String> completedFiles;
  final ArchiveMetadata? metadata;

  PersistedDownload({
    required this.downloadId,
    required this.identifier,
    required this.downloadPath,
    required this.archiveDir,
    required this.progress,
    this.selectedFiles = const [],
    this.completedFiles = const {},
    this.metadata,
  });

  /// Statuses worth offering for recovery on next launch. Completed and
  /// cancelled downloads are deleted from the store instead.
  static const Set<DownloadStatus> recoverableStatuses = {
    DownloadStatus.queued,
    DownloadStatus.downloading,
    DownloadStatus.paused,
    DownloadStatus.error,
  };

  bool get isRecoverable => recoverableStatuses.contains(progress.status);
}

/// SQLite-backed store for the production download queue (#84).
///
/// Writes are fire-and-forget from the service's perspective: persistence
/// failures must never interrupt an active download. Reads happen once at
/// startup (BackgroundDownloadService.restorePersistedQueue).
class DownloadQueueStore {
  DownloadQueueStore._();

  static final DownloadQueueStore instance = DownloadQueueStore._();

  /// Test hook: use this database instead of the app database.
  @visibleForTesting
  Future<Database> Function()? databaseOverride;

  Future<Database> _db() async =>
      databaseOverride?.call() ?? DatabaseHelper.instance.database;

  /// Insert or replace the row for [entry].
  Future<void> save(PersistedDownload entry) async {
    final db = await _db();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      DatabaseHelper.tableDownloadQueue,
      {
        'download_id': entry.downloadId,
        'identifier': entry.identifier,
        'download_path': entry.downloadPath,
        'archive_dir': entry.archiveDir,
        'status': entry.progress.status.name,
        'total_files': entry.progress.totalFiles,
        'selected_files': jsonEncode(entry.selectedFiles),
        'completed_files': jsonEncode(entry.completedFiles.toList()),
        'progress_json': jsonEncode(entry.progress.toJson()),
        'metadata_json':
            entry.metadata == null ? null : jsonEncode(entry.metadata!.toJson()),
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Remove the row for [downloadId] (completion/cancel/restore-drop).
  Future<void> delete(String downloadId) async {
    final db = await _db();
    await db.delete(
      DatabaseHelper.tableDownloadQueue,
      where: 'download_id = ?',
      whereArgs: [downloadId],
    );
  }

  /// Load all recoverable entries, oldest first. Malformed rows are
  /// skipped silently rather than aborting startup recovery.
  Future<List<PersistedDownload>> loadRecoverable() async {
    final db = await _db();
    final rows = await db.query(
      DatabaseHelper.tableDownloadQueue,
      orderBy: 'created_at ASC',
    );
    final result = <PersistedDownload>[];
    for (final row in rows) {
      final entry = _fromRow(row);
      if (entry == null) continue;
      if (!entry.isRecoverable) continue;
      result.add(entry);
    }
    return result;
  }

  PersistedDownload? _fromRow(Map<String, dynamic> row) {
    try {
      final progressJson = row['progress_json'] as String?;
      final progress = progressJson == null
          ? DownloadProgress(
              downloadId: row['download_id'] as String,
              identifier: row['identifier'] as String,
              totalFiles: (row['total_files'] as int?) ?? 0,
              status: DownloadStatus.queued,
            )
          : DownloadProgress.fromJson(
              jsonDecode(progressJson) as Map<String, dynamic>,
            );

      final selected =
          (jsonDecode(row['selected_files'] as String? ?? '[]')
                  as List<dynamic>)
              .cast<String>()
              .toList();

      final completed =
          (jsonDecode(row['completed_files'] as String? ?? '[]')
                  as List<dynamic>)
              .cast<String>()
              .toSet();

      ArchiveMetadata? metadata;
      final metadataJson = row['metadata_json'] as String?;
      if (metadataJson != null && metadataJson.isNotEmpty) {
        metadata = ArchiveMetadata.fromJson(
          jsonDecode(metadataJson) as Map<String, dynamic>,
        );
      }

      return PersistedDownload(
        downloadId: row['download_id'] as String,
        identifier: row['identifier'] as String,
        downloadPath: row['download_path'] as String? ?? '',
        archiveDir: row['archive_dir'] as String? ?? '',
        progress: progress,
        selectedFiles: selected,
        completedFiles: completed,
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('DownloadQueueStore: skipping unreadable queue row: $e');
      return null;
    }
  }
}
