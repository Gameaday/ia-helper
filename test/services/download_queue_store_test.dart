import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/database/database_helper.dart';
import 'package:internet_archive_helper/models/archive_metadata.dart';
import 'package:internet_archive_helper/models/download_progress.dart';
import 'package:internet_archive_helper/services/download_queue_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Round-trip and recovery-filter tests for the download queue store (#84).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath, version: 1);
    // Bring the schema up to v7 (fresh installs get this via _onCreate).
    await DatabaseHelper.instance.debugUpgrade(db, 6, 7);
    DownloadQueueStore.instance.databaseOverride = () async => db;
  });

  tearDown(() async {
    DownloadQueueStore.instance.databaseOverride = null;
    await db.close();
  });

  PersistedDownload entry({DownloadStatus status = DownloadStatus.paused}) {
    return PersistedDownload(
      downloadId: 'd1',
      identifier: 'archive-1',
      downloadPath: '/downloads',
      archiveDir: '/downloads/archive-1',
      progress: DownloadProgress(
        downloadId: 'd1',
        identifier: 'archive-1',
        totalFiles: 2,
        totalBytes: 100,
        downloadedBytes: 40,
        progress: 0.4,
        completedFiles: 1,
        status: status,
        errorMessage: status == DownloadStatus.error ? 'boom' : null,
      ),
      selectedFiles: const ['a.pdf', 'b.pdf'],
      completedFiles: const {'a.pdf'},
      metadata: ArchiveMetadata(
        identifier: 'archive-1',
        totalFiles: 2,
        totalSize: 100,
        files: [
          ArchiveFile(name: 'a.pdf', size: 60, md5: 'aaa'),
          ArchiveFile(name: 'b.pdf', size: 40),
        ],
      ),
    );
  }

  test('save and load round-trips all fields', () async {
    await DownloadQueueStore.instance.save(entry());

    final loaded = await DownloadQueueStore.instance.loadRecoverable();
    expect(loaded, hasLength(1));

    final e = loaded.single;
    expect(e.downloadId, 'd1');
    expect(e.identifier, 'archive-1');
    expect(e.downloadPath, '/downloads');
    expect(e.archiveDir, '/downloads/archive-1');
    expect(e.progress.status, DownloadStatus.paused);
    expect(e.progress.downloadedBytes, 40);
    expect(e.progress.totalBytes, 100);
    expect(e.progress.completedFiles, 1);
    expect(e.progress.retryCount, 0);
    expect(e.selectedFiles, ['a.pdf', 'b.pdf']);
    expect(e.completedFiles, {'a.pdf'});
    expect(e.metadata, isNotNull);
    expect(e.metadata!.identifier, 'archive-1');
    expect(e.metadata!.files, hasLength(2));
    expect(e.metadata!.files.first.md5, 'aaa');
  });

  test('queued, downloading, paused and error entries are recoverable', () async {
    for (final status in [
      DownloadStatus.queued,
      DownloadStatus.downloading,
      DownloadStatus.paused,
      DownloadStatus.error,
    ]) {
      await DownloadQueueStore.instance.delete('d1');
      await DownloadQueueStore.instance.save(entry(status: status));
      final loaded = await DownloadQueueStore.instance.loadRecoverable();
      expect(loaded, hasLength(1), reason: 'status ${status.name}');
      expect(loaded.single.progress.status, status);
    }
  });

  test('completed and cancelled entries are not returned', () async {
    await DownloadQueueStore.instance
        .save(entry(status: DownloadStatus.completed));
    await DownloadQueueStore.instance
        .save(entry(status: DownloadStatus.cancelled));
    expect(await DownloadQueueStore.instance.loadRecoverable(), isEmpty);
  });

  test('delete removes the persisted entry', () async {
    await DownloadQueueStore.instance.save(entry());
    await DownloadQueueStore.instance.delete('d1');
    expect(await DownloadQueueStore.instance.loadRecoverable(), isEmpty);
  });

  test('malformed rows are skipped instead of throwing', () async {
    await db.insert(DatabaseHelper.tableDownloadQueue, {
      'download_id': 'broken',
      'identifier': 'x',
      'download_path': '/d',
      'archive_dir': '/d/x',
      'status': 'paused',
      'total_files': 1,
      'selected_files': 'not json[',
      'completed_files': '[]',
      'created_at': 1,
      'updated_at': 1,
    });

    final loaded = await DownloadQueueStore.instance.loadRecoverable();
    expect(loaded, isEmpty);
  });
}
