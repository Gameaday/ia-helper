import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/utils/file_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ia_helper_checksum');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('calculateFileHash streams md5 and sha1', () async {
    final file = File('${tempDir.path}/hello.txt')
      ..writeAsStringSync('hello world');

    expect(
      await FileUtils.calculateFileHash(file.path),
      '5eb63bbbe01eeed093cb22bb8f5acdc3',
    );
    expect(
      await FileUtils.calculateFileHash(file.path, algorithm: 'sha1'),
      '2aae6c35c94fcfb415dbe95f408b9ce91ee846ed',
    );
  });

  test('calculateFileHash returns null for missing files', () async {
    expect(
      await FileUtils.calculateFileHash('${tempDir.path}/missing.bin'),
      isNull,
    );
  });

  test('calculateFileHash rejects unsupported algorithms', () async {
    final file = File('${tempDir.path}/x.txt')..writeAsStringSync('x');
    expect(
      () => FileUtils.calculateFileHash(file.path, algorithm: 'crc32'),
      throwsArgumentError,
    );
  });

  test('verifyChecksum detects matches, mismatches and missing files', () async {
    final file = File('${tempDir.path}/data.txt')
      ..writeAsStringSync('hello world');

    expect(
      await FileUtils.verifyChecksum(
        file.path,
        '5eb63bbbe01eeed093cb22bb8f5acdc3',
      ),
      isTrue,
    );
    expect(
      await FileUtils.verifyChecksum(
        file.path,
        'deadbeefdeadbeefdeadbeefdeadbeef',
      ),
      isFalse,
    );
    expect(
      await FileUtils.verifyChecksum(
        '${tempDir.path}/gone.txt',
        '5eb63bbbe01eeed093cb22bb8f5acdc3',
      ),
      isFalse,
    );
  });

  test('verifyChecksum handles a multi-MB file (streaming path)', () async {
    final file = File('${tempDir.path}/big.bin');
    final sink = file.openSync(mode: FileMode.write);
    final rng = Random(1);
    for (var i = 0; i < 4096; i++) {
      sink.addSync(List<int>.generate(1024, (_) => rng.nextInt(256)));
    }
    await sink.flush();
    sink.closeSync();

    final digest = await FileUtils.calculateFileHash(file.path);
    expect(digest, isNotNull);
    expect(await FileUtils.verifyChecksum(file.path, digest!), isTrue);
  });
}
