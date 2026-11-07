import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/database/database_helper.dart';
import 'package:internet_archive_helper/models/download_progress.dart';
import 'package:internet_archive_helper/services/background_download_service.dart';
import 'package:internet_archive_helper/services/download_queue_store.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Connectivity-aware pause/resume state machine tests (#85).
///
/// The service is driven via
/// [BackgroundDownloadService.handleConnectivityChange] with seeded
/// downloads ([BackgroundDownloadService.debugSeedDownload]), so no real
/// network or platform connectivity channel is involved: the state
/// transitions are exercised in isolation. Queue persistence calls
/// (pause/resume persist their state, #84) run against an in-memory FFI
/// database.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late BackgroundDownloadService service;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath, version: 1);
    await DatabaseHelper.instance.debugUpgrade(db, 6, 7);
    DownloadQueueStore.instance.databaseOverride = () async => db;
    service = BackgroundDownloadService();
    // Keep the state machine under test; no network restarts in tests.
    service.debugDisableNetworkRestarts = true;
  });

  tearDown(() async {
    DownloadQueueStore.instance.databaseOverride = null;
    await db.close();
  });

  DownloadProgress? progressFor(String id) => service.activeDownloads[id];

  test('connection loss pauses in-flight downloads cleanly', () async {
    service.debugSeedDownload(
      downloadId: 'a',
      identifier: 'arch-a',
      selectedFiles: ['a1.pdf'],
      downloadPath: '/dl',
    );
    service.debugSeedDownload(
      downloadId: 'b',
      identifier: 'arch-b',
      selectedFiles: ['b1.pdf'],
      downloadPath: '/dl',
    );

    await service.handleConnectivityChange(online: false);

    expect(service.isOnline, isFalse);
    // Clean pause: paused status, no error message, no failure metric
    expect(progressFor('a')?.status, DownloadStatus.paused);
    expect(progressFor('b')?.status, DownloadStatus.paused);
    expect(progressFor('a')?.errorMessage, isNull);
    expect(progressFor('b')?.errorMessage, isNull);
    expect(service.metrics.pauses, 2);
    expect(service.metrics.failures, 0);
  });

  test('queued downloads are left untouched by connection loss', () async {
    service.debugSeedDownload(
      downloadId: 'q',
      identifier: 'arch-q',
      selectedFiles: ['q1.pdf'],
      downloadPath: '/dl',
      status: DownloadStatus.queued,
    );

    await service.handleConnectivityChange(online: false);

    expect(progressFor('q')?.status, DownloadStatus.queued);
  });

  test('reconnect auto-resumes only connectivity-paused downloads',
      () async {
    // 'user' was paused by the user BEFORE the disconnect
    service.debugSeedDownload(
      downloadId: 'user',
      identifier: 'arch-user',
      selectedFiles: ['u1.pdf'],
      downloadPath: '/dl',
      status: DownloadStatus.paused,
    );
    // 'conn' is actively downloading when the connection drops
    service.debugSeedDownload(
      downloadId: 'conn',
      identifier: 'arch-conn',
      selectedFiles: ['c1.pdf'],
      downloadPath: '/dl',
    );

    await service.handleConnectivityChange(online: false);
    await service.handleConnectivityChange(online: true);

    // Connectivity-paused: resumed automatically
    expect(progressFor('conn')?.status, DownloadStatus.downloading);
    // User-paused: stays paused
    expect(progressFor('user')?.status, DownloadStatus.paused);
    expect(service.metrics.resumes, 1);
  });

  test('retry sweep does not burn attempts while offline', () async {
    service.debugSeedDownload(
      downloadId: 'e',
      identifier: 'arch-e',
      selectedFiles: ['e1.pdf'],
      downloadPath: '/dl',
      status: DownloadStatus.error,
      errorMessage: 'Connection closed early: got 1 of 100 bytes',
    );

    await service.handleConnectivityChange(online: false);
    await service.debugRunRetrySweep();

    // Offline: no attempt consumed, no state churn
    expect(progressFor('e')?.status, DownloadStatus.error);
    expect(progressFor('e')?.retryCount, 0);

    await service.handleConnectivityChange(online: true);

    // Reconnect: the sweep runs immediately and retries once
    expect(progressFor('e')?.retryCount, 1);
    expect(progressFor('e')?.status, DownloadStatus.downloading);
  });

  test('queue processing is gated while offline and drains on reconnect',
      () async {
    service.debugSeedDownload(
      downloadId: 'q',
      identifier: 'arch-q',
      selectedFiles: ['q1.pdf'],
      downloadPath: '/dl',
      status: DownloadStatus.queued,
      queued: true,
    );

    await service.handleConnectivityChange(online: false);
    await service.debugProcessQueue();
    expect(progressFor('q')?.status, DownloadStatus.queued);

    await service.handleConnectivityChange(online: true);
    expect(progressFor('q')?.status, DownloadStatus.downloading);
  });

  test('duplicate offline reports do not re-pause (flapping dedupe)',
      () async {
    service.debugSeedDownload(
      downloadId: 'a',
      identifier: 'arch-a',
      selectedFiles: ['a1.pdf'],
      downloadPath: '/dl',
    );

    await service.handleConnectivityChange(online: false);
    final pausesAfterFirst = service.metrics.pauses;

    // connectivity_plus can emit repeated reports for the same state
    await service.handleConnectivityChange(online: false);

    expect(service.metrics.pauses, pausesAfterFirst);
  });
}
