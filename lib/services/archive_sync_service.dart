import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/archive_metadata.dart';
import '../models/downloaded_archive.dart';
import '../utils/file_utils.dart';
import 'archive_url_service.dart';
import 'internet_archive_api.dart';

/// Verdict for one file after comparing the local copy with the remote
/// item's current metadata (#94).
enum FileSyncStatus {
  /// Present on disk and verified (checksum, or size when the item
  /// publishes no checksum for the file).
  ok,

  /// Tracked as downloaded but not on disk (deleted by the user or a
  /// cleanup tool).
  missing,

  /// On disk with a different length than the remote file - the remote
  /// file changed, or the local copy is a truncated stale download.
  sizeMismatch,

  /// Correct length but the content checksum does not match - corrupt
  /// local copy.
  corrupt,

  /// Tracked locally but no longer part of the remote item (removed from
  /// archive.org).
  removedRemote,

  /// On disk but neither tracked nor present in the remote metadata.
  extra,
}

/// Per-file audit verdict.
class FileSyncReport {
  final String fileName;
  final FileSyncStatus status;
  final int? expectedSize;
  final int? actualSize;

  const FileSyncReport({
    required this.fileName,
    required this.status,
    this.expectedSize,
    this.actualSize,
  });

  /// Whether re-downloading this file can fix it.
  bool get needsRedownload =>
      status == FileSyncStatus.missing ||
      status == FileSyncStatus.sizeMismatch ||
      status == FileSyncStatus.corrupt;

  /// Whether the local copy should be deleted (no longer meaningful).
  bool get isOrphan =>
      status == FileSyncStatus.removedRemote || status == FileSyncStatus.extra;
}

/// Full audit result for one archive: refreshed remote metadata plus the
/// verdict for every tracked or stray local file.
class ArchiveSyncReport {
  final String identifier;
  final ArchiveMetadata remoteMetadata;
  final List<FileSyncReport> files;

  const ArchiveSyncReport({
    required this.identifier,
    required this.remoteMetadata,
    required this.files,
  });

  int count(FileSyncStatus status) =>
      files.where((f) => f.status == status).length;

  int get okCount => count(FileSyncStatus.ok);
  int get missingCount => count(FileSyncStatus.missing);
  int get sizeMismatchCount => count(FileSyncStatus.sizeMismatch);
  int get corruptCount => count(FileSyncStatus.corrupt);
  int get removedRemoteCount => count(FileSyncStatus.removedRemote);
  int get extraCount => count(FileSyncStatus.extra);

  /// Files a re-download can repair.
  int get repairCount => missingCount + sizeMismatchCount + corruptCount;

  /// Local copies that only deletion can fix.
  int get orphanCount => removedRemoteCount + extraCount;

  bool get hasIssues => files.any((f) => f.status != FileSyncStatus.ok);

  Map<String, FileSyncReport> get byName => {
    for (final f in files) f.fileName: f,
  };

  List<FileSyncReport> get filesToRedownload =>
      files.where((f) => f.needsRedownload).toList();

  List<FileSyncReport> get orphanedFiles =>
      files.where((f) => f.isOrphan).toList();
}

/// Result of applying the fixes for an [ArchiveSyncReport].
class ArchiveSyncOutcome {
  /// The audit the fixes were applied for.
  final ArchiveSyncReport report;

  /// Files successfully re-downloaded (and checksum-verified).
  final int repairedFiles;

  /// Orphaned local files deleted (removed remotely / not in the item).
  final int deletedOrphans;

  /// File names that could not be repaired.
  final List<String> failures;

  /// The archive record with refreshed metadata and recomputed file
  /// states, ready to persist via LocalArchiveStorage.
  final DownloadedArchive updatedArchive;

  const ArchiveSyncOutcome({
    required this.report,
    required this.repairedFiles,
    required this.deletedOrphans,
    required this.failures,
    required this.updatedArchive,
  });

  bool get allApplied => failures.isEmpty;
}

/// Local <-> remote archive synchronization (#94).
///
/// For one downloaded archive the service:
/// 1. Refreshes the item's metadata from archive.org - conditionally:
///    when a [metadataFetcher] backed by ArchiveService's MetadataCache
///    is supplied, an unchanged item costs a single If-None-Match GET
///    (304), not a full re-download.
/// 2. Audits every file the user has: existence, size, and content
///    checksum (md5 preferred, sha1 fallback - the same policy as the
///    download path, #83) against the remote metadata. Files never
///    selected for download are not the sync's business.
/// 3. Repairs what the user confirms: re-downloads missing, changed
///    (size-mismatch) and corrupt files - deleting the stale bytes first
///    so the #83 Range resume never mixes old and new content - and
///    deletes orphaned local copies (removed remotely / not in the item).
/// 4. Merges the refreshed remote metadata and recomputed file states
///    into the stored archive record.
class ArchiveSyncService {
  /// API supplied by the caller (tests / shared clients). When absent,
  /// one is created lazily on first use so audit-only usage (with a
  /// metadata fetcher) never opens a client.
  final InternetArchiveApi? _apiOverride;
  InternetArchiveApi? _ownedApi;

  InternetArchiveApi get _api =>
      _apiOverride ?? (_ownedApi ??= InternetArchiveApi());

  final Future<ArchiveMetadata> Function(String identifier)?
  _metadataFetcher;
  final ArchiveUrlService _urlService = ArchiveUrlService();

  /// Test seam: replaces the network download used for repairs.
  @visibleForTesting
  Future<String> Function(String url, String outputPath)? downloadOverride;

  ArchiveSyncService({
    InternetArchiveApi? api,
    Future<ArchiveMetadata> Function(String identifier)? metadataFetcher,
  }) : _apiOverride = api,
       _metadataFetcher = metadataFetcher;

  /// Conditional metadata refresh + local file audit for [archive].
  Future<ArchiveSyncReport> audit(DownloadedArchive archive) async {
    final remote = await _fetchRemote(archive.identifier);
    final files = await _auditFiles(archive: archive, remote: remote);
    return ArchiveSyncReport(
      identifier: archive.identifier,
      remoteMetadata: remote,
      files: files,
    );
  }

  Future<ArchiveMetadata> _fetchRemote(String identifier) async {
    final fetcher = _metadataFetcher;
    if (fetcher != null) {
      return fetcher(identifier);
    }
    return _api.fetchMetadata(identifier);
  }

  Future<List<FileSyncReport>> _auditFiles({
    required DownloadedArchive archive,
    required ArchiveMetadata remote,
  }) async {
    final reports = <FileSyncReport>[];
    final remoteByName = {for (final f in remote.files) f.name: f};
    final archiveDir = archive.localPath;

    // Every file the user has (tracked as downloaded in the record).
    for (final entry in archive.fileStates.entries) {
      if (!entry.value) continue;
      final remoteFile = remoteByName[entry.key];
      if (remoteFile == null) {
        reports.add(
          FileSyncReport(
            fileName: entry.key,
            status: FileSyncStatus.removedRemote,
          ),
        );
        continue;
      }
      reports.add(
        await _auditOne(archiveDir: archiveDir, remoteFile: remoteFile),
      );
    }

    // Stray files on disk that neither side knows about. Expected on-disk
    // names mirror how downloads write them (FileUtils.safeJoin).
    final knownDiskNames = <String>{
      for (final name in remoteByName.keys) FileUtils.sanitizeFilename(name),
      for (final name in archive.fileStates.keys)
        FileUtils.sanitizeFilename(name),
    };
    final dir = Directory(archiveDir);
    if (await dir.exists()) {
      final prefix = archiveDir.endsWith('/') ? archiveDir : '$archiveDir/';
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;
        final rel = entity.path.startsWith(prefix)
            ? entity.path.substring(prefix.length)
            : entity.path;
        if (!knownDiskNames.contains(rel)) {
          reports.add(
            FileSyncReport(
              fileName: rel,
              status: FileSyncStatus.extra,
              actualSize: await entity.length(),
            ),
          );
        }
      }
    }
    return reports;
  }

  Future<FileSyncReport> _auditOne({
    required String archiveDir,
    required ArchiveFile remoteFile,
  }) async {
    final diskPath = FileUtils.safeJoin(archiveDir, remoteFile.name);
    final file = File(diskPath);
    if (!await file.exists()) {
      return FileSyncReport(
        fileName: remoteFile.name,
        status: FileSyncStatus.missing,
        expectedSize: remoteFile.size,
      );
    }
    final actualSize = await file.length();

    // Size is the cheap check; only hash when the length matches (or the
    // item publishes no size). One checksum is enough - md5 preferred,
    // sha1 fallback, same policy as the download path (#83).
    final expectedMd5 = _orNull(remoteFile.md5);
    final expectedSha1 = _orNull(remoteFile.sha1);
    String? actualMd5;
    String? actualSha1;
    if (expectedMd5 != null) {
      actualMd5 = await FileUtils.calculateFileHash(
        diskPath,
        algorithm: 'md5',
      );
    } else if (expectedSha1 != null) {
      actualSha1 = await FileUtils.calculateFileHash(
        diskPath,
        algorithm: 'sha1',
      );
    }

    final status = classifyLocalFile(
      exists: true,
      expectedSize: remoteFile.size,
      actualSize: actualSize,
      expectedMd5: expectedMd5,
      actualMd5: actualMd5,
      expectedSha1: expectedSha1,
      actualSha1: actualSha1,
    );
    return FileSyncReport(
      fileName: remoteFile.name,
      status: status,
      expectedSize: remoteFile.size,
      actualSize: actualSize,
    );
  }

  /// Pure decision table (#94): how a local file compares to its remote
  /// counterpart. Extracted so the audit logic is unit-testable without
  /// disk or network.
  @visibleForTesting
  static FileSyncStatus classifyLocalFile({
    required bool exists,
    int? expectedSize,
    int? actualSize,
    String? expectedMd5,
    String? actualMd5,
    String? expectedSha1,
    String? actualSha1,
  }) {
    if (!exists) return FileSyncStatus.missing;
    if (expectedSize != null &&
        actualSize != null &&
        expectedSize != actualSize) {
      return FileSyncStatus.sizeMismatch;
    }
    if (expectedMd5 != null) {
      if (actualMd5 == null) return FileSyncStatus.corrupt; // unreadable
      if (!_hashMatches(expectedMd5, actualMd5)) {
        return FileSyncStatus.corrupt;
      }
    } else if (expectedSha1 != null) {
      if (actualSha1 == null) return FileSyncStatus.corrupt;
      if (!_hashMatches(expectedSha1, actualSha1)) {
        return FileSyncStatus.corrupt;
      }
    }
    return FileSyncStatus.ok;
  }

  static bool _hashMatches(String expected, String actual) =>
      expected.toLowerCase() == actual.toLowerCase();

  static String? _orNull(String? value) =>
      (value == null || value.isEmpty) ? null : value;

  /// Apply the fixes for [report]: re-download missing/changed/corrupt
  /// files, delete orphaned local copies, and merge the refreshed
  /// metadata into the archive record.
  Future<ArchiveSyncOutcome> applyFixes(
    DownloadedArchive archive,
    ArchiveSyncReport report, {
    void Function(int done, int total)? onProgress,
  }) async {
    final failures = <String>[];
    final repairedNames = <String>{};
    final remoteByName = {
      for (final f in report.remoteMetadata.files) f.name: f,
    };
    final toRepair = report.filesToRedownload;
    var done = 0;

    for (final entry in toRepair) {
      final remoteFile = remoteByName[entry.fileName];
      if (remoteFile == null) {
        failures.add(entry.fileName);
        continue;
      }
      try {
        final diskPath = FileUtils.safeJoin(archive.localPath, entry.fileName);
        // The local copy is stale or corrupt: delete it so the repair
        // fetches fresh bytes. (Resuming via #83's Range support would
        // keep the stale prefix and produce a corrupt hybrid.)
        final existing = File(diskPath);
        if (await existing.exists()) {
          await existing.delete();
        }
        final url = _urlService.getDownloadUrl(
          archive.identifier,
          entry.fileName,
        );
        final downloader = downloadOverride;
        if (downloader != null) {
          await downloader(url, diskPath);
        } else {
          await _api.downloadFile(url, diskPath);
        }
        if (!await _verify(diskPath, remoteFile)) {
          failures.add(entry.fileName);
        } else {
          repairedNames.add(entry.fileName);
        }
      } catch (e) {
        debugPrint(
          '[ArchiveSyncService] Failed to repair ${entry.fileName}: $e',
        );
        failures.add(entry.fileName);
      }
      done++;
      onProgress?.call(done, toRepair.length);
    }

    var deletedOrphans = 0;
    for (final orphan in report.orphanedFiles) {
      try {
        final diskPath = FileUtils.safeJoin(
          archive.localPath,
          orphan.fileName,
        );
        final file = File(diskPath);
        if (await file.exists()) {
          await file.delete();
          deletedOrphans++;
        }
      } catch (e) {
        debugPrint(
          '[ArchiveSyncService] Failed to delete ${orphan.fileName}: $e',
        );
      }
    }

    return ArchiveSyncOutcome(
      report: report,
      repairedFiles: repairedNames.length,
      deletedOrphans: deletedOrphans,
      failures: failures,
      updatedArchive: _mergeRecord(
        archive,
        report,
        repairedNames: repairedNames,
      ),
    );
  }

  /// Post-repair verification - same md5 -> sha1 preference as downloads.
  Future<bool> _verify(String diskPath, ArchiveFile remoteFile) async {
    final md5Hash = _orNull(remoteFile.md5);
    if (md5Hash != null) {
      return FileUtils.verifyChecksum(diskPath, md5Hash, algorithm: 'md5');
    }
    final sha1Hash = _orNull(remoteFile.sha1);
    if (sha1Hash != null) {
      return FileUtils.verifyChecksum(diskPath, sha1Hash, algorithm: 'sha1');
    }
    return true;
  }

  /// Merge the refreshed remote metadata and audit results into the stored
  /// archive record: new file list, per-file states recomputed from what
  /// is actually on disk, and honest byte totals.
  DownloadedArchive _mergeRecord(
    DownloadedArchive archive,
    ArchiveSyncReport report, {
    required Set<String> repairedNames,
  }) {
    final states = <String, bool>{};
    var downloadedFiles = 0;
    var downloadedBytes = 0;
    var totalBytes = 0;

    for (final file in report.remoteMetadata.files) {
      totalBytes += file.size ?? 0;
      final entry = report.byName[file.name];
      final bool downloaded;
      if (entry == null) {
        // Not audited (never tracked): keep the user's selection.
        downloaded = archive.fileStates[file.name] ?? false;
      } else if (entry.status == FileSyncStatus.ok) {
        downloaded = true;
      } else if (repairedNames.contains(file.name)) {
        downloaded = true;
      } else {
        // Still broken after the repair attempt.
        downloaded = false;
      }
      states[file.name] = downloaded;
      if (downloaded) {
        downloadedFiles++;
        downloadedBytes += file.size ?? 0;
      }
    }

    return archive.copyWith(
      metadata: report.remoteMetadata,
      totalFiles: report.remoteMetadata.files.length,
      totalBytes: totalBytes,
      downloadedFiles: downloadedFiles,
      downloadedBytes: downloadedBytes,
      fileStates: states,
    );
  }

  /// Releases the owned HTTP client (if one was created). Do not use the
  /// service afterwards.
  void dispose() {
    _ownedApi?.dispose();
  }
}
