import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/services/saf_download_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SAF download-location service tests (#90): picker persistence, the
/// export decision table (not configured / grant revoked / exported /
/// failed), and grant release. The method channel and the platform gate
/// are injected; no test touches a real platform.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.internetarchive.helper/saf');

  /// Calls received by the mock handler, for asserting arguments.
  final received = <MethodCall>[];

  /// Behavior table for the mock handler: method -> result or exception.
  final behaviors = <String, Object?>{};

  Future<Object?> handler(MethodCall call) async {
    received.add(call);
    final behavior = behaviors[call.method];
    if (behavior is Exception) {
      throw behavior;
    }
    return behavior;
  }

  late SafDownloadService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    received.clear();
    behaviors.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
    service = SafDownloadService.test(
      channel: channel,
      platformCheck: () => true,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('pickFolder persists the tree URI and folder name', () async {
    behaviors['pickFolder'] = <String, Object>{
      'treeUri': 'content://tree/primary%3ADownload',
      'folderName': 'Download',
    };

    final name = await service.pickFolder();

    expect(name, 'Download');
    expect(
      await service.currentTreeUri(),
      'content://tree/primary%3ADownload',
    );
    expect(await service.currentFolderName(), 'Download');
  });

  test('pickFolder with a missing plugin returns null and stores nothing',
      () async {
    behaviors['pickFolder'] = MissingPluginException();

    final name = await service.pickFolder();

    expect(name, isNull);
    expect(await service.currentTreeUri(), isNull);
  });

  test('pickFolder is a no-op on unsupported platforms', () async {
    final unsupported = SafDownloadService.test(
      channel: channel,
      platformCheck: () => false,
    );

    expect(await unsupported.pickFolder(), isNull);
    expect(received, isEmpty);
  });

  test('exportFile with no configured folder is notConfigured', () async {
    final outcome = await service.exportFile('/tmp/app/a-file.zip');

    expect(outcome, SafExportOutcome.notConfigured);
    expect(received, isEmpty);
  });

  test('exportFile with a revoked grant clears the folder and reports it',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      SafDownloadService.prefTreeUri,
      'content://tree/primary%3ADownload',
    );
    await prefs.setString(SafDownloadService.prefFolderName, 'Download');
    behaviors['hasValidGrant'] = false;

    final outcome = await service.exportFile('/tmp/app/a-file.zip');

    expect(outcome, SafExportOutcome.grantRevoked);
    // The stored folder is gone: the next download uses app storage.
    expect(await service.currentTreeUri(), isNull);
    expect(await service.currentFolderName(), isNull);
    // The stale grant was released before the pref was dropped.
    expect(received.any((c) => c.method == 'releaseGrant'), isTrue);
  });

  test('exportFile exports with a derived name and mime type', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      SafDownloadService.prefTreeUri,
      'content://tree/primary%3ADownload',
    );
    behaviors['hasValidGrant'] = true;
    behaviors['exportFile'] = <String, Object>{'documentName': 'a-file.zip'};

    final outcome = await service.exportFile(
      '/tmp/app/a-file.zip',
      fileName: 'a-file.zip',
    );

    expect(outcome, SafExportOutcome.exported);
    final exportCall = received.firstWhere(
      (c) => c.method == 'exportFile',
    );
    expect(exportCall.arguments, <String, Object?>{
      'treeUri': 'content://tree/primary%3ADownload',
      'filePath': '/tmp/app/a-file.zip',
      'fileName': 'a-file.zip',
      'mimeType': 'application/zip',
    });
  });

  test('exportFile reports failure without touching the stored folder',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      SafDownloadService.prefTreeUri,
      'content://tree/primary%3ADownload',
    );
    behaviors['hasValidGrant'] = true;
    behaviors['exportFile'] = PlatformException(code: 'EXPORT_ERROR');

    final outcome = await service.exportFile('/tmp/app/a-file.bin');

    expect(outcome, SafExportOutcome.failed);
    // A transient failure keeps the folder configured for the next file.
    expect(await service.currentTreeUri(), 'content://tree/primary%3ADownload');
  });

  test('clearFolder releases the grant and clears the prefs', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      SafDownloadService.prefTreeUri,
      'content://tree/primary%3ADownload',
    );
    await prefs.setString(SafDownloadService.prefFolderName, 'Download');
    behaviors['releaseGrant'] = true;

    await service.clearFolder();

    expect(await service.currentTreeUri(), isNull);
    expect(await service.currentFolderName(), isNull);
    final releaseCall = received.firstWhere(
      (c) => c.method == 'releaseGrant',
    );
    expect(
      releaseCall.arguments,
      <String, Object?>{'treeUri': 'content://tree/primary%3ADownload'},
    );
  });

  test('hasValidGrant consults the native grant state', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      SafDownloadService.prefTreeUri,
      'content://tree/primary%3ADownload',
    );
    behaviors['hasValidGrant'] = true;
    expect(await service.hasValidGrant(), isTrue);

    behaviors['hasValidGrant'] = false;
    expect(await service.hasValidGrant(), isFalse);
  });

  test('hasValidGrant with no folder configured is false', () async {
    expect(await service.hasValidGrant(), isFalse);
    expect(received, isEmpty);
  });
}
