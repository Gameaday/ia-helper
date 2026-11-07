import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/services/torrent_handoff_service.dart';

/// Torrent handoff tests (#93). Everything here is offline: the magnet
/// construction is pure string work, and the torrent parsing operates on
/// synthetic bencoded fixtures (a local encoder builds them).
List<int> enc(dynamic value) {
  if (value is int) return utf8.encode('i${value}e');
  if (value is String) {
    final bytes = utf8.encode(value);
    return [...utf8.encode('${bytes.length}:'), ...bytes];
  }
  if (value is List) return [0x6C, ...value.expand(enc), 0x65];
  if (value is Map<String, dynamic>) {
    final out = <int>[0x64];
    for (final entry in value.entries) {
      out.addAll(enc(entry.key));
      out.addAll(enc(entry.value));
    }
    out.add(0x65);
    return out;
  }
  throw ArgumentError('Unsupported fixture value: $value');
}

void main() {
  group('TorrentHandoffService.buildMagnet', () {
    test('builds the canonical magnet with trackers and webseed', () {
      final magnet = TorrentHandoffService.buildMagnet(
        btih: 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2',
        displayName: 'Some Item',
        webseedUrl: 'https://archive.org/download/foo/',
      );
      expect(magnet,
        'magnet:?xt=urn:btih:a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2'
        '&dn=Some%20Item'
        '&tr=http%3A%2F%2Fbt1.archive.org%3A6969%2Fannounce'
        '&tr=http%3A%2F%2Fbt2.archive.org%3A6969%2Fannounce'
        '&ws=https%3A%2F%2Farchive.org%2Fdownload%2Ffoo%2F');
    });

    test('omits ws when no webseed is given', () {
      final magnet = TorrentHandoffService.buildMagnet(
        btih: 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2',
        displayName: 'Some Item',
      );
      expect(magnet, isNot(contains('ws=')));
      expect(magnet, contains('tr=http%3A%2F%2Fbt2.archive.org%3A6969%2Fannounce'));
    });

    test('percent-encodes special characters in the display name', () {
      final magnet = TorrentHandoffService.buildMagnet(
        btih: 'abcdefabcdefabcdefabcdefabcdefabcdefabcd',
        displayName: 'A/B & C',
      );
      expect(magnet, contains('dn=A%2FB%20%26%20C'));
    });
  });

  group('TorrentHandoffService.parseTorrentBytes', () {
    final info = <String, dynamic>{
      'length': 1024,
      'name': 'sampleitem',
      'piece length': 32768,
    };

    List<int> torrentWith(Map<String, dynamic> infoDict) => enc(
          <String, dynamic>{
            'announce': 'http://bt1.archive.org:6969/announce',
            'info': infoDict,
          },
        );

    test('computes the btih as SHA-1 over the raw info bytes', () {
      final bytes = torrentWith(info);
      final expectedBtih = sha1.convert(enc(info)).toString();

      final handoff = TorrentHandoffService.parseTorrentBytes(
        identifier: 'sampleitem',
        bytes: bytes,
      );

      expect(handoff.btih, expectedBtih);
      expect(handoff.name, 'sampleitem');
      expect(handoff.torrentBytes, bytes);
      expect(
        handoff.magnetLink,
        startsWith('magnet:?xt=urn:btih:$expectedBtih&dn=sampleitem&'),
      );
      // Both official IA trackers must be present for external clients
      expect(
        handoff.magnetLink,
        contains('tr=http%3A%2F%2Fbt1.archive.org%3A6969%2Fannounce'),
      );
      expect(
        handoff.magnetLink,
        contains('tr=http%3A%2F%2Fbt2.archive.org%3A6969%2Fannounce'),
      );
      // Webseed so clients can complete with zero live seeders
      expect(handoff.magnetLink, contains('ws='));
    });

    test('falls back to the identifier when the info has no name', () {
      final handoff = TorrentHandoffService.parseTorrentBytes(
        identifier: 'sampleitem',
        bytes: torrentWith(<String, dynamic>{'length': 1024}),
      );
      expect(handoff.name, 'sampleitem');
    });

    test('wraps malformed torrent bytes in a friendly exception', () {
      expect(
        () => TorrentHandoffService.parseTorrentBytes(
          identifier: 'sampleitem',
          bytes: utf8.encode('this is not a torrent'),
        ),
        throwsA(isA<TorrentHandoffException>()),
      );
    });

    test('rejects torrents without an info dictionary', () {
      expect(
        () => TorrentHandoffService.parseTorrentBytes(
          identifier: 'sampleitem',
          bytes: enc(<String, dynamic>{'announce': 'x'}),
        ),
        throwsA(isA<TorrentHandoffException>()),
      );
    });

    test('rejects non-dictionary torrent roots', () {
      expect(
        () => TorrentHandoffService.parseTorrentBytes(
          identifier: 'sampleitem',
          bytes: enc(<dynamic>['not', 'a', 'dict']),
        ),
        throwsA(isA<TorrentHandoffException>()),
      );
    });
  });
}
