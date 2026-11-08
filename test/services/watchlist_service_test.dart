import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:internet_archive_helper/database/database_helper.dart';
import 'package:internet_archive_helper/services/watchlist_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Watchlist service tests (#91): persistence round-trips, baseline
/// establishment, new-file detection, and the v7 -> v8 migration.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late WatchlistService service;

  /// Simulated remote file count for the watched item; tests grow this
  /// to model new uploads.
  var remoteFileCount = 3;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath, version: 1);
    // Bring the schema to v8 exactly like a v7 install upgrading (#91).
    await DatabaseHelper.instance.debugUpgrade(db, 7, 8);
    remoteFileCount = 3;
    final client = MockClient(
      (request) async => http.Response(
        '{"metadata": {"identifier": "item-1", "title": "Item One", '
            '"mediatype": "texts"}, "files": '
            '${List.generate(remoteFileCount, (i) => '{"name": "file-$i"}').join(',')}}',
        200,
      ),
    );
    service = WatchlistService.test(
      httpClient: client,
      dbOverride: () async => db,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('v7 -> v8 migration creates the watchlist table', () async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name = 'watchlist'",
    );
    expect(tables, hasLength(1));
  });

  test('add, list, and round-trip entries', () async {
    final added = await service.addEntry(
      identifier: 'item-1',
      title: 'Item One',
      mediatype: 'texts',
    );
    expect(added, isTrue);

    final duplicate = await service.addEntry(identifier: 'item-1');
    expect(duplicate, isFalse);

    final entries = await service.getAllEntries();
    expect(entries, hasLength(1));
    expect(entries.first.identifier, 'item-1');
    expect(entries.first.title, 'Item One');
    expect(entries.first.hasBaseline, isFalse); // not checked yet
    expect(await service.isWatched('item-1'), isTrue);
    expect(await service.isWatched('other'), isFalse);
  });

  test('first check establishes the baseline without flagging', () async {
    await service.addEntry(identifier: 'item-1');
    final entry = await service.getEntry('item-1');

    final checked = await service.checkEntry(entry!);
    expect(checked.knownFileCount, 3);
    expect(checked.newFileCount, 0); // baseline, not news
    expect(checked.hasNewFiles, isFalse);
    expect(checked.lastCheckedAt, isNotNull);

    final reloaded = await service.getEntry('item-1');
    expect(reloaded!.knownFileCount, 3);
    expect(reloaded.newFileCount, 0);
  });

  test('new files are detected on later checks and acknowledged on open',
      () async {
    await service.addEntry(identifier: 'item-1');
    var entry = await service.getEntry('item-1');
    await service.checkEntry(entry!);

    // The remote item gains two uploads.
    remoteFileCount = 5;

    entry = await service.getEntry('item-1');
    final grown = await service.checkEntry(entry!);
    expect(grown.knownFileCount, 5);
    expect(grown.newFileCount, 2);
    expect(grown.hasNewFiles, isTrue);
    expect(grown.lastChangedAt, isNotNull);

    // Opening the item acknowledges the badge without touching the
    // stored snapshot.
    await service.acknowledgeNewFiles('item-1');
    final acknowledged = await service.getEntry('item-1');
    expect(acknowledged!.newFileCount, 0);
    expect(acknowledged.knownFileCount, 5);
  });

  test('checkAll reports how many items gained files', () async {
    await service.addEntry(identifier: 'item-1');
    await service.checkAll();
    remoteFileCount = 6;
    final withNew = await service.checkAll();
    expect(withNew, 1);

    final entry = await service.getEntry('item-1');
    expect(entry!.newFileCount, 3);
  });

  test('missing items throw and leave the stored row untouched', () async {
    final missingClient = MockClient(
      (request) async => http.Response('{}', 200),
    );
    final missingService = WatchlistService.test(
      httpClient: missingClient,
      dbOverride: () async => db,
    );

    await missingService.addEntry(identifier: 'gone-item');
    final entry = await missingService.getEntry('gone-item');

    await expectLater(missingService.checkEntry(entry!), throwsException);
    final untouched = await missingService.getEntry('gone-item');
    expect(untouched!.knownFileCount, -1);
    expect(untouched.lastCheckedAt, isNull);
  });

  test('removeEntry deletes the row', () async {
    await service.addEntry(identifier: 'item-1');
    expect(await service.removeEntry('item-1'), isTrue);
    expect(await service.removeEntry('item-1'), isFalse);
    expect(await service.getAllEntries(), isEmpty);
  });

  test('clearAll removes every entry', () async {
    await service.addEntry(identifier: 'a');
    await service.addEntry(identifier: 'b');
    expect(await service.clearAll(), 2);
    expect(await service.getAllEntries(), isEmpty);
  });
}
