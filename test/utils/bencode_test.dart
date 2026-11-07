import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/utils/bencode.dart';

/// Minimal bencode encoder used only to build test fixtures; the app itself
/// only decodes (torrent handoff, #93).
List<int> enc(dynamic value) {
  if (value is int) return utf8.encode('i${value}e');
  if (value is String) {
    final bytes = utf8.encode(value);
    return [...utf8.encode('${bytes.length}:'), ...bytes];
  }
  if (value is List) {
    return [0x6C, ...value.expand(enc), 0x65];
  }
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
  group('Bencode.decode', () {
    test('decodes integers', () {
      expect(Bencode.decode(utf8.encode('i42e')), 42);
      expect(Bencode.decode(utf8.encode('i-7e')), -7);
      expect(Bencode.decode(utf8.encode('i0e')), 0);
    });

    test('decodes strings', () {
      expect(Bencode.decode(utf8.encode('5:hello')), 'hello');
      expect(Bencode.decode(utf8.encode('0:')), '');
    });

    test('decodes UTF-8 strings', () {
      expect(Bencode.decode(enc('naïve')), 'naïve');
    });

    test('keeps binary strings lossless via Latin-1 fallback', () {
      final decoded = Bencode.decode(
        [...utf8.encode('3:'), 0xFF, 0xFE, 0xFD],
      ) as String;
      expect(decoded.length, 3);
      expect(decoded.codeUnitAt(0), 0xFF);
    });

    test('decodes lists (nested)', () {
      expect(Bencode.decode(utf8.encode('l4:spami42ee')), ['spam', 42]);
      expect(
        Bencode.decode(enc([
          'spam',
          42,
          ['nested'],
        ])),
        ['spam', 42, ['nested']],
      );
    });

    test('decodes dictionaries (nested)', () {
      expect(Bencode.decode(utf8.encode('d3:foo3:bare')), {'foo': 'bar'});
      final root = <String, dynamic>{
        'announce': 'http://bt1.archive.org:6969/announce',
        'info': <String, dynamic>{
          'name': 'sampleitem',
          'piece length': 32768,
        },
      };
      expect(Bencode.decode(enc(root)), root);
    });

    test('rejects trailing bytes', () {
      expect(
        () => Bencode.decode([...utf8.encode('i42e'), ...utf8.encode('i1e')]),
        throwsA(isA<BencodeFormatException>()),
      );
    });

    test('rejects malformed input', () {
      expect(
        () => Bencode.decode(utf8.encode('i42')), // unterminated
        throwsA(isA<BencodeFormatException>()),
      );
      expect(
        () => Bencode.decode(utf8.encode('x5:hello')), // bad type byte
        throwsA(isA<BencodeFormatException>()),
      );
      expect(
        () => Bencode.decode(utf8.encode('4:hel')), // exceeds buffer
        throwsA(isA<BencodeFormatException>()),
      );
    });
  });

  group('Bencode.extractInfoBytes', () {
    final info = <String, dynamic>{
      'length': 1024,
      'name': 'sampleitem',
      'piece length': 32768,
    };

    test('returns the exact raw bytes of the info dictionary', () {
      final torrent = enc(<String, dynamic>{
        'announce': 'http://bt1.archive.org:6969/announce',
        'info': info,
      });
      final extracted = Bencode.extractInfoBytes(torrent);
      expect(extracted, enc(info));
    });

    test('works when info is the first entry', () {
      final torrent = enc(<String, dynamic>{'info': info});
      expect(Bencode.extractInfoBytes(torrent), enc(info));
    });

    test('throws when there is no info dictionary', () {
      expect(
        () => Bencode.extractInfoBytes(enc(<String, dynamic>{'announce': 'x'})),
        throwsA(isA<BencodeFormatException>()),
      );
    });

    test('throws when the root is not a dictionary', () {
      expect(
        () => Bencode.extractInfoBytes(enc(<dynamic>[1, 2])),
        throwsA(isA<BencodeFormatException>()),
      );
    });
  });
}
