import 'dart:convert';

import 'favorites_service.dart';
import 'local_archive_storage.dart';
import 'watchlist_service.dart';

/// Export format for metadata exports (#91).
enum ExportFormat { json, csv }

/// Which parts of the local library get exported (#91).
enum ExportScope { downloads, favorites, watchlist }

/// Metadata export service (#91): researcher-friendly JSON/CSV exports of
/// the user's local library data, with citation-style records.
///
/// Everything is generated on-device; the file goes only where the user
/// sends it. The data-safety form stays untouched.
class MetadataExportService {
  /// Build the export document for the given scopes and format.
  Future<String> export({
    required Set<ExportScope> scopes,
    required ExportFormat format,
  }) async {
    if (scopes.isEmpty) {
      throw ArgumentError('Select at least one scope to export');
    }

    final records = <Map<String, dynamic>>[];
    for (final scope in ExportScope.values) {
      if (!scopes.contains(scope)) continue;
      records.addAll(await _gather(scope));
    }

    if (format == ExportFormat.json) {
      return _encodeJson(records);
    }
    return _encodeCsv(records);
  }

  Future<List<Map<String, dynamic>>> _gather(ExportScope scope) async {
    switch (scope) {
      case ExportScope.favorites:
        return _gatherFavorites();
      case ExportScope.downloads:
        return _gatherDownloads();
      case ExportScope.watchlist:
        return _gatherWatchlist();
    }
  }

  Future<List<Map<String, dynamic>>> _gatherFavorites() async {
    final favorites = await FavoritesService.instance.getAllFavorites();
    return favorites.map((favorite) {
      final creator =
          favorite.metadataJson?['creator'] is String
          ? favorite.metadataJson!['creator'] as String
          : null;
      return _record(
        identifier: favorite.identifier,
        title: favorite.title,
        creator: creator,
        mediatype: favorite.mediatype,
        source: 'favorites',
        date: favorite.addedAt,
        files: null,
        sizeBytes: null,
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _gatherDownloads() async {
    final storage = LocalArchiveStorage();
    await storage.initialize();
    return storage.archives.values.map((archive) {
      final itemDate = archive.metadata.date;
      final year = itemDate != null && itemDate.length >= 4
          ? itemDate.substring(0, 4)
          : null;
      return _record(
        identifier: archive.identifier,
        title: archive.metadata.title,
        creator: archive.metadata.creator,
        mediatype: archive.metadata.mediaType,
        source: 'downloads',
        date: archive.downloadedAt,
        files: archive.downloadedFiles,
        sizeBytes: archive.downloadedBytes,
        year: year,
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _gatherWatchlist() async {
    final entries = await WatchlistService.instance.getAllEntries();
    return entries.map((entry) {
      return _record(
        identifier: entry.identifier,
        title: entry.title,
        creator: null,
        mediatype: entry.mediatype,
        source: 'watchlist',
        date: entry.addedAt,
        files: entry.hasBaseline ? entry.knownFileCount : null,
        sizeBytes: null,
      );
    }).toList();
  }

  Map<String, dynamic> _record({
    required String identifier,
    required String? title,
    required String? creator,
    required String? mediatype,
    required String source,
    required DateTime date,
    required int? files,
    required int? sizeBytes,
    String? year,
  }) {
    final record = <String, dynamic>{
      'identifier': identifier,
      'title': title ?? identifier,
      'creator': creator,
      'mediatype': mediatype,
      'source': source,
      'added_at': date.toIso8601String(),
      'files': files,
      'size_bytes': sizeBytes,
    };
    record['citation'] = _citation(
      identifier: identifier,
      title: title ?? identifier,
      creator: creator,
      year: year,
    );
    return record;
  }

  /// Citation-style record (Chicago-flavored):
  /// `Creator (Year). Title. Internet Archive. https://archive.org/details/id`
  String _citation({
    required String identifier,
    required String title,
    required String? creator,
    String? year,
  }) {
    final author = (creator == null || creator.isEmpty)
        ? 'Internet Archive'
        : creator;
    final yearPart = (year == null || year.isEmpty) ? '' : ' ($year)';
    return '$author$yearPart. $title. Internet Archive. '
        'https://archive.org/details/$identifier';
  }

  String _encodeJson(List<Map<String, dynamic>> records) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(<String, dynamic>{
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'Internet Archive Helper',
      'record_count': records.length,
      'records': records,
    });
  }

  String _encodeCsv(List<Map<String, dynamic>> records) {
    const columns = [
      'identifier',
      'title',
      'creator',
      'mediatype',
      'source',
      'added_at',
      'files',
      'size_bytes',
      'citation',
    ];

    final buffer = StringBuffer();
    buffer.writeln(columns.map(_csvCell).join(','));
    for (final record in records) {
      buffer.writeln(
        columns.map((column) => _csvCell(record[column])).join(','),
      );
    }
    return buffer.toString();
  }

  /// RFC 4180-style CSV escaping.
  String _csvCell(dynamic value) {
    if (value == null) return '';
    final text = value.toString();
    if (text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }
}
