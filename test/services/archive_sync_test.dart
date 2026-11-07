import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/models/archive_metadata.dart';
import 'package:internet_archive_helper/models/downloaded_archive.dart';
import 'package:internet_archive_helper/services/archive_sync_service.dart';

String _md5Of(String content) =>
    crypto.md5.convert(utf8.encode(content)).toString();

ArchiveFile _file(
  String name, {
  required String content,
  int? size,
  String? md5,
}) {
  return ArchiveFile(
    name: name,
    size: size ?? utf8.encode(content).length,
    md5: md5 ?? _md5Of(content),
  );
}

ArchiveMetadata _metadata(String identifier, List<ArchiveFile> files) {
  return ArchiveMetadata(
    identifier: identifier,
    title: 'Item $identifier',
    totalFiles: files.length,
    totalSize: files.fold<int>(0, (sum, f) => sum + (f.size ?? 0)),
    files: files,
  );
}

DownloadedArchive _archive(
  ArchiveMetadata metadata,
  String localPath,
  List<String> downloaded,
) {
  return DownloadedArchive.fromMetadata(
    metadata: metadata,
    localPath: localPath,
    downloadedFileNames: downloaded,
  );
}

/// Shared fixture: a stored archive tracking files a-d, a remote item
/// that dropped d, and a disk state with a ok, b truncated, c missing,
/// d present, plus an untracked rogue file.
Future<(Directory, DownloadedArchive, ArchiveMetadata)> _fixture() async {
  final dir = await Directory.systemTemp.createTemp('ia_sync_test');
  addTearDown(() async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  await File('${dir.path}/a.txt').writeAsString('AAA');
  await File('${dir.path}/b.txt').writeAsString('B');
  await File('${dir.path}/d.txt').writeAsString('DDD');
  await File('${dir.path}/rogue.bin').writeAsString('xxx');

  final stored = _metadata('testitem', [
    _file('a.txt', content: 'AAA'),
    _file('b.txt', content: 'BBB'),
    _file('c.txt', content: 'CCC'),
    _file('d.txt', content: 'DDD'),
  ]);
  final remote = _metadata('testitem', [
    _file('a.txt', content: 'AAA'),
    _file('b.txt', content: 'BBB'),
    _file('c.txt', content: 'CCC'),
  ]);
  final archive = _archive(stored, dir.path, [
    'a.txt',
    'b.txt',
    'c.txt',
    'd.txt',
  ]);
  return (dir, archive, remote);
}

void main() {
  test('classifyLocalFile decision table', () {
    expect(
      ArchiveSyncService.classifyLocalFile(exists: false),
      FileSyncStatus.missing,
    );
    expect(
      ArchiveSyncService.classifyLocalFile(
        exists: true,
        expectedSize: 3,
        actualSize: 1,
        expectedMd5: 'aa',
        actualMd5: 'aa',
      ),
      FileSyncStatus.sizeMismatch,
    );
    expect(
      ArchiveSyncService.classifyLocalFile(
        exists: true,
        expectedSize: 3,
        actualSize: 3,
        expectedMd5: 'aa',
        actualMd5: 'bb',
      ),
      FileSyncStatus.corrupt,
    );
    expect(
      ArchiveSyncService.classifyLocalFile(
        exists: true,
        expectedSize: 3,
        actualSize: 3,
        expectedMd5: 'AA',
        actualMd5: 'aa',
      ),
      FileSyncStatus.ok,
    );
    expect(
      ArchiveSyncService.classifyLocalFile(
        exists: true,
        expectedSize: 3,
        actualSize: 3,
        expectedSha1: 'ss',
        actualSha1: 'tt',
      ),
      FileSyncStatus.corrupt,
    );
    // No checksum published: size is all we can verify.
    expect(
      ArchiveSyncService.classifyLocalFile(
        exists: true,
        expectedSize: 3,
        actualSize: 3,
      ),
      FileSyncStatus.ok,
    );
    // Expected checksum but the file is unreadable (hash came back null).
    expect(
      ArchiveSyncService.classifyLocalFile(exists: true, expectedMd5: 'aa'),
      FileSyncStatus.corrupt,
    );
  });

  test('audit classifies ok/sizeMismatch/missing/removedRemote/extra', () async {
    final (_, archive, remote) = await _fixture();
    final service = ArchiveSyncService(metadataFetcher: (_) async => remote);
    addTearDown(service.dispose);

    final report = await service.audit(archive);
    final byName = {for (final f in report.files) f.fileName: f};

    expect(byName['a.txt']?.status, FileSyncStatus.ok);
    expect(byName['b.txt']?.status, FileSyncStatus.sizeMismatch);
    expect(byName['c.txt']?.status, FileSyncStatus.missing);
    expect(byName['d.txt']?.status, FileSyncStatus.removedRemote);
    expect(byName['rogue.bin']?.status, FileSyncStatus.extra);
    expect(report.repairCount, 2);
    expect(report.orphanCount, 2);
    expect(report.hasIssues, isTrue);
  });

  test('applyFixes repairs, removes orphans, and merges the record', () async {
    final (dir, archive, remote) = await _fixture();
    final service = ArchiveSyncService(metadataFetcher: (_) async => remote);
    addTearDown(service.dispose);
    service.downloadOverride = (url, outputPath) async {
      final name = outputPath.split('/').last;
      final content = switch (name) {
        'b.txt' => 'BBB',
        'c.txt' => 'CCC',
        _ => throw Exception('no fixture for $name'),
      };
      await File(outputPath).writeAsString(content);
      return outputPath;
    };

    final report = await service.audit(archive);
    final outcome = await service.applyFixes(archive, report);

    expect(outcome.repairedFiles, 2);
    expect(outcome.deletedOrphans, 2); // d.txt + rogue.bin
    expect(outcome.failures, isEmpty);
    expect(outcome.allApplied, isTrue);

    // On-disk state after the repair.
    expect(await File('${dir.path}/b.txt').readAsString(), 'BBB');
    expect(await File('${dir.path}/c.txt').exists(), isTrue);
    expect(await File('${dir.path}/rogue.bin').exists(), isFalse);
    expect(await File('${dir.path}/d.txt').exists(), isFalse);

    // The merged archive record: refreshed remote metadata, recomputed
    // per-file states and byte totals.
    final updated = outcome.updatedArchive;
    expect(updated.identifier, archive.identifier);
    expect(updated.metadata.files.length, 3);
    expect(updated.fileStates['a.txt'], isTrue);
    expect(updated.fileStates['b.txt'], isTrue);
    expect(updated.fileStates['c.txt'], isTrue);
    expect(updated.fileStates.containsKey('d.txt'), isFalse);
    expect(updated.downloadedFiles, 3);
  });

  test('applyFixes reports failed repairs without breaking the record', () async {
    final (_, archive, remote) = await _fixture();
    final service = ArchiveSyncService(metadataFetcher: (_) async => remote);
    addTearDown(service.dispose);
    service.downloadOverride = (url, outputPath) async {
      throw Exception('network down');
    };

    final report = await service.audit(archive);
    final outcome = await service.applyFixes(archive, report);

    expect(outcome.repairedFiles, 0);
    expect(outcome.failures, containsAll(<String>['b.txt', 'c.txt']));
    expect(outcome.allApplied, isFalse);
    // Orphan cleanup is independent of repair failures and still ran.
    expect(outcome.deletedOrphans, 2);
    // a.txt verified ok before the repair and stays downloaded; the two
    // broken files are marked not-downloaded in the merged record.
    expect(outcome.updatedArchive.fileStates['a.txt'], isTrue);
    expect(outcome.updatedArchive.fileStates['b.txt'], isFalse);
    expect(outcome.updatedArchive.fileStates['c.txt'], isFalse);
  });
}
