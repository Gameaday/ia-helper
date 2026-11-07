import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/bencode.dart';
import 'archive_url_service.dart';
import 'ia_http_client.dart';

/// Official Internet Archive torrent trackers.
///
/// Reference: https://help.archive.org/help/archive-bittorrents/
const List<String> _iaTrackers = [
  'http://bt1.archive.org:6969/announce',
  'http://bt2.archive.org:6969/announce',
];

/// A prepared torrent handoff: the item's official .torrent plus the
/// derived magnet link (#93).
class TorrentHandoff {
  const TorrentHandoff({
    required this.identifier,
    required this.name,
    required this.torrentBytes,
    required this.btih,
    required this.magnetLink,
  });

  final String identifier;

  /// Display name from the torrent's info dict (falls back to identifier).
  final String name;

  /// The official `{identifier}_archive.torrent` exactly as served by IA.
  final Uint8List torrentBytes;

  /// Info hash: SHA-1 over the raw bencoded info dict (40-char hex).
  final String btih;

  /// Magnet link with IA trackers and the item's webseed URL.
  final String magnetLink;
}

/// Thrown when a torrent handoff cannot be prepared.
class TorrentHandoffException implements Exception {
  final String message;
  const TorrentHandoffException(this.message);

  @override
  String toString() => message;
}

/// Hands the official IA torrent of an item to an external torrent app so
/// users can download/seed items themselves — especially items whose
/// torrents have no seeders left (#93).
///
/// The app itself never speaks BitTorrent: it only fetches the .torrent
/// file (a plain HTTP download through the standard IA client) and shares
/// it, plus builds the canonical magnet link. No torrent engine, no peer
/// connections, no Play Store policy exposure.
class TorrentHandoffService {
  const TorrentHandoffService();

  /// Fetches the item's official `{identifier}_archive.torrent` and parses
  /// it into a [TorrentHandoff].
  Future<TorrentHandoff> prepare(String identifier) async {
    final url = Uri.parse(
      ArchiveUrlService().getDownloadUrl(
        identifier,
        '${identifier}_archive.torrent',
      ),
    );

    final client = IAHttpClient();
    try {
      final response = await client.get(url);
      return parseTorrentBytes(identifier: identifier, bytes: response.bodyBytes);
    } on IAHttpException catch (e) {
      if (e.statusCode == 404 || e.type == IAHttpExceptionType.notFound) {
        throw const TorrentHandoffException(
          'This item has no torrent file. Not every item has one.',
        );
      }
      if (e.type == IAHttpExceptionType.rateLimited) {
        throw const TorrentHandoffException(
          'Internet Archive rate limit hit; please try again in a moment.',
        );
      }
      throw TorrentHandoffException(
        'Could not fetch the torrent file: ${e.message}',
      );
    } finally {
      client.close();
    }
  }

  /// Parses raw `.torrent` bytes into a [TorrentHandoff] (no network).
  ///
  /// Visible for testing and reuse; [prepare] calls it after the fetch.
  @visibleForTesting
  static TorrentHandoff parseTorrentBytes({
    required String identifier,
    required List<int> bytes,
  }) {
    final Uint8List infoBytes;
    final Map<String, dynamic> root;
    try {
      infoBytes = Bencode.extractInfoBytes(bytes);
      final decoded = Bencode.decode(bytes);
      if (decoded is! Map<String, dynamic>) {
        throw const BencodeFormatException('Torrent root is not a dictionary');
      }
      root = decoded;
    } on BencodeFormatException catch (e) {
      throw TorrentHandoffException(
        'The torrent file for this item could not be read: ${e.message}',
      );
    }

    final info = root['info'];
    if (info is! Map) {
      throw const TorrentHandoffException(
        'Torrent file has no info dictionary',
      );
    }
    final rawName = info['name'];
    final name = rawName is String && rawName.isNotEmpty ? rawName : identifier;

    final btih = sha1.convert(infoBytes).toString();
    return TorrentHandoff(
      identifier: identifier,
      name: name,
      torrentBytes: Uint8List.fromList(bytes),
      btih: btih,
      magnetLink: buildMagnet(
        btih: btih,
        displayName: name,
        webseedUrl: ArchiveUrlService().getDirectoryUrl(identifier),
      ),
    );
  }

  /// Builds the canonical magnet link for an IA item torrent.
  ///
  /// Includes both official IA trackers and the item's `ws=` webseed URL
  /// (IA serves files over HTTP as a Getright-style webseed), so any
  /// external client can complete the download even with zero live
  /// seeders.
  static String buildMagnet({
    required String btih,
    required String displayName,
    String? webseedUrl,
  }) {
    final params = <String>[
      'xt=urn:btih:$btih',
      'dn=${Uri.encodeComponent(displayName)}',
      ..._iaTrackers.map((t) => 'tr=${Uri.encodeComponent(t)}'),
      if (webseedUrl != null) 'ws=${Uri.encodeComponent(webseedUrl)}',
    ];
    return 'magnet:?${params.join('&')}';
  }

  /// Saves the .torrent into [directory], or the app's `torrents/`
  /// documents folder when omitted. Returns the written file.
  Future<File> saveTorrentFile(
    TorrentHandoff handoff, {
    String? directory,
  }) async {
    final Directory dir;
    if (directory != null) {
      dir = Directory(directory);
    } else {
      final docs = await getApplicationDocumentsDirectory();
      dir = Directory('${docs.path}/torrents');
    }
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}/${handoff.identifier}_archive.torrent');
    await file.writeAsBytes(handoff.torrentBytes, flush: true);
    return file;
  }

  /// Saves the .torrent and hands it to the OS share sheet, where any
  /// installed torrent client can pick it up.
  Future<void> shareTorrentFile(TorrentHandoff handoff) async {
    final file = await saveTorrentFile(handoff);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/x-bittorrent')],
        text:
            'Internet Archive torrent for "${handoff.name}" — open it with '
            'your torrent app to download and seed.',
      ),
    );
  }

  /// Copies the magnet link to the clipboard.
  Future<void> copyMagnetLink(TorrentHandoff handoff) async {
    await Clipboard.setData(ClipboardData(text: handoff.magnetLink));
  }
}
