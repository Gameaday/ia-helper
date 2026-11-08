import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ia_credentials_service.dart';

/// One item the user has write access to (an S3 "bucket" on archive.org).
class OwnItem {
  final String identifier;
  final DateTime? creationDate;

  const OwnItem({required this.identifier, this.creationDate});
}

/// Raised when archive.org rejects the S3 keys.
///
/// Deliberately carries no key material and its message never echoes the
/// Authorization header (#95).
class IAS3AuthException implements Exception {
  final String message;

  const IAS3AuthException(this.message);

  @override
  String toString() => message;
}

/// Own-item management over IA's S3-compatible API (#95):
/// - List items the user can write to (ListBuckets).
/// - Edit remote item metadata (IA metadata write API,
///   POST /metadata/{identifier} with LOW S3 auth).
///
/// All requests go out over HTTPS with the user's keys from secure
/// storage; keys never appear in errors or logs.
class OwnItemsService {
  static const String _s3Endpoint = 'https://s3.us.archive.org';
  static const String _metadataEndpoint = 'https://archive.org/metadata';
  static const String _userAgent = 'InternetArchiveHelper/1.9.0';

  final http.Client _client;
  final IACredentialsService _credentials;

  OwnItemsService({http.Client? client, IACredentialsService? credentials})
    : _client = client ?? http.Client(),
      _credentials = credentials ?? IACredentialsService();

  /// Auth headers including the LOW-scheme Authorization value. Throws
  /// [IAS3AuthException] when no keys are configured.
  Future<Map<String, String>> _authHeaders() async {
    final keys = await _credentials.getKeys();
    if (keys == null || !keys.isValid) {
      throw const IAS3AuthException(
        'Add your archive.org S3 keys in Settings first.',
      );
    }
    return {
      'Authorization': keys.authorizationHeaderValue,
      'User-Agent': _userAgent,
    };
  }

  /// Lists every item the configured keys grant write access to.
  ///
  /// IA's ListBuckets does not paginate, so the full list comes back in
  /// one response; the UI is expected to offer local filtering.
  Future<List<OwnItem>> listOwnItems() async {
    final headers = await _authHeaders();
    final http.Response response;
    try {
      response = await _client.get(
        Uri.parse('$_s3Endpoint/'),
        headers: headers,
      );
    } catch (e) {
      debugPrint('[OwnItemsService] S3 list request failed: $e');
      throw const IAS3AuthException(
        'Could not reach archive.org. Check your connection and try again.',
      );
    }
    _throwForStatus(response);
    final items = parseBucketList(response.body);
    items.sort((a, b) => a.identifier.compareTo(b.identifier));
    return items;
  }

  /// Edits an item's remote metadata via the IA metadata write API.
  ///
  /// Only the provided (non-null) fields are submitted; null fields keep
  /// their current remote value. Returns whether archive.org accepted
  /// the change (it is applied by archive.org's metadata task queue, so
  /// verify with a re-read).
  Future<bool> updateItemMetadata(
    String identifier, {
    String? title,
    String? description,
    String? subject,
  }) async {
    final fields = <String, String>{
      'title': ?title,
      'description': ?description,
      if (subject != null && subject.isNotEmpty) 'subject': subject,
    };
    if (fields.isEmpty) {
      return false;
    }
    final headers = await _authHeaders();
    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$_metadataEndpoint/$identifier'),
        headers: {
          ...headers,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: fields,
      );
    } catch (e) {
      debugPrint('[OwnItemsService] metadata write request failed: $e');
      throw const IAS3AuthException(
        'Could not reach archive.org. Check your connection and try again.',
      );
    }
    _throwForStatus(response);
    try {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic>) {
        return json['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('[OwnItemsService] Unexpected metadata API response: $e');
      throw Exception('Unexpected response from archive.org metadata API');
    }
  }

  void _throwForStatus(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw IAS3AuthException(
        'archive.org rejected your S3 keys (HTTP ${response.statusCode}). '
        'Verify them at archive.org under account settings, then update '
        'them here.',
      );
    }
    if (response.statusCode != 200) {
      throw Exception('archive.org returned HTTP ${response.statusCode}');
    }
  }

  /// Parses the S3 ListAllMyBucketsResult XML into items. Extracted for
  /// offline unit tests (#95).
  @visibleForTesting
  static List<OwnItem> parseBucketList(String xml) {
    final result = <OwnItem>[];
    final bucketRegex = RegExp(r'<Bucket>(.*?)</Bucket>', dotAll: true);
    for (final match in bucketRegex.allMatches(xml)) {
      final block = match.group(1);
      if (block == null) continue;
      final name = _xmlText(block, 'Name');
      if (name == null || name.isEmpty) continue;
      final dateText = _xmlText(block, 'CreationDate');
      DateTime? date;
      if (dateText != null) {
        date = DateTime.tryParse(dateText);
      }
      result.add(OwnItem(identifier: name, creationDate: date));
    }
    return result;
  }

  static String? _xmlText(String block, String tag) {
    final match = RegExp(
      '<$tag>(.*?)</$tag>',
      dotAll: true,
    ).firstMatch(block);
    if (match == null) return null;
    return _unescapeXml(match.group(1)?.trim() ?? '');
  }

  static String _unescapeXml(String text) => text
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');

  /// Releases the HTTP client owned by this service.
  void dispose() {
    _client.close();
  }
}
