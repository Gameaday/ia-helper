import 'dart:convert';
import 'dart:typed_data';

/// Thrown when a bencoded buffer cannot be parsed.
class BencodeFormatException implements Exception {
  final String message;
  const BencodeFormatException(this.message);

  @override
  String toString() => 'BencodeFormatException: $message';
}

/// Minimal bencode decoder (BEP-3) with byte-span tracking.
///
/// Used to read `.torrent` metadata and to capture the raw bytes of the
/// `info` dictionary so the btih can be computed as SHA-1 over the exact
/// bencoded bytes (torrent handoff, #93). Decode-only: the app never
/// creates or speaks BitTorrent itself.
class Bencode {
  Bencode._();

  /// Decodes [bytes] into Dart values.
  ///
  /// Returns [Map], [List], [int] or [String]. Byte strings are decoded as
  /// UTF-8 with a Latin-1 fallback so binary values (e.g. `pieces`) stay
  /// lossless.
  static dynamic decode(List<int> bytes) {
    final decoded = _decodeValue(bytes, 0);
    if (decoded.end != bytes.length) {
      throw const BencodeFormatException('Trailing bytes after bencoded value');
    }
    return decoded.value;
  }

  /// Extracts the raw bencoded bytes of the `info` dictionary from a
  /// torrent file, exactly as they appear in the file.
  ///
  /// SHA-1 over these bytes is the torrent's info hash (btih).
  static Uint8List extractInfoBytes(List<int> bytes) {
    final top = _decodeValue(bytes, 0);
    if (top.value is! Map) {
      throw const BencodeFormatException('Torrent root is not a dictionary');
    }
    for (final entry in top.entries ?? const <MapEntry<String, _Span>>[]) {
      if (entry.key == 'info') {
        return Uint8List.fromList(
          bytes.sublist(entry.value.start, entry.value.end),
        );
      }
    }
    throw const BencodeFormatException('Torrent has no info dictionary');
  }

  static _Decoded _decodeValue(List<int> bytes, int offset) {
    if (offset >= bytes.length) {
      throw const BencodeFormatException('Unexpected end of data');
    }
    final byte = bytes[offset];

    if (byte == 0x69 /* 'i' */) {
      final end = bytes.indexOf(0x65 /* 'e' */, offset);
      if (end < 0) {
        throw const BencodeFormatException('Unterminated integer');
      }
      final digits = String.fromCharCodes(bytes.sublist(offset + 1, end));
      final value = int.tryParse(digits);
      if (value == null) {
        throw BencodeFormatException('Invalid integer: "$digits"');
      }
      return _Decoded(value, end + 1, null);
    }

    if (byte == 0x6C /* 'l' */) {
      var pos = offset + 1;
      final list = <dynamic>[];
      while (true) {
        if (pos >= bytes.length) {
          throw const BencodeFormatException('Unterminated list');
        }
        if (bytes[pos] == 0x65 /* 'e' */) {
          return _Decoded(list, pos + 1, null);
        }
        final decoded = _decodeValue(bytes, pos);
        list.add(decoded.value);
        pos = decoded.end;
      }
    }

    if (byte == 0x64 /* 'd' */) {
      var pos = offset + 1;
      final map = <String, dynamic>{};
      final entries = <MapEntry<String, _Span>>[];
      while (true) {
        if (pos >= bytes.length) {
          throw const BencodeFormatException('Unterminated dictionary');
        }
        if (bytes[pos] == 0x65 /* 'e' */) {
          return _Decoded(map, pos + 1, entries);
        }
        final key = _decodeValue(bytes, pos);
        if (key.value is! String) {
          throw const BencodeFormatException('Dictionary key is not a string');
        }
        final valueStart = key.end;
        final value = _decodeValue(bytes, valueStart);
        map[key.value as String] = value.value;
        entries.add(MapEntry(key.value as String, _Span(valueStart, value.end)));
        pos = value.end;
      }
    }

    if (byte >= 0x30 /* '0' */ && byte <= 0x39 /* '9' */) {
      final colon = bytes.indexOf(0x3A /* ':' */, offset);
      if (colon < 0) {
        throw const BencodeFormatException('Unterminated string length');
      }
      final lengthText = String.fromCharCodes(bytes.sublist(offset, colon));
      final length = int.tryParse(lengthText);
      if (length == null || length < 0) {
        throw BencodeFormatException('Invalid string length: "$lengthText"');
      }
      final start = colon + 1;
      final end = start + length;
      if (end > bytes.length) {
        throw const BencodeFormatException('String extends past end of data');
      }
      final raw = bytes.sublist(start, end);
      String text;
      try {
        text = utf8.decode(raw);
      } catch (_) {
        // Binary values (e.g. `pieces`): keep them lossless via Latin-1.
        text = latin1.decode(raw);
      }
      return _Decoded(text, end, null);
    }

    throw BencodeFormatException(
      'Unexpected byte 0x${byte.toRadixString(16).padLeft(2, '0')}',
    );
  }
}

/// A successfully decoded value plus the offset just past it, and for
/// dictionaries the byte spans of each entry's value.
class _Decoded {
  final dynamic value;
  final int end;
  final List<MapEntry<String, _Span>>? entries;

  const _Decoded(this.value, this.end, this.entries);
}

/// Byte span [start, end) of a dictionary entry's value.
class _Span {
  final int start;
  final int end;

  const _Span(this.start, this.end);
}
