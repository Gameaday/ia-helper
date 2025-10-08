import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:internet_archive_helper/services/ia_http_client.dart';

void main() {
  group('IAHttpClient ETag Tests', () {
    test('get() includes If-None-Match header when etag provided', () async {
      String? capturedHeader;

      final mockClient = MockClient((request) async {
        capturedHeader = request.headers['If-None-Match'];
        return http.Response('{"test": true}', 200);
      });

      final client = IAHttpClient(innerClient: mockClient);

      await client.get(
        Uri.parse('https://archive.org/test'),
        ifNoneMatch: '"test-etag"',
      );

      expect(capturedHeader, equals('"test-etag"'));
      client.close();
    });

    test('get() does NOT include If-None-Match when etag is null', () async {
      Map<String, String>? capturedHeaders;

      final mockClient = MockClient((request) async {
        capturedHeaders = request.headers;
        return http.Response('{"test": true}', 200);
      });

      final client = IAHttpClient(innerClient: mockClient);

      await client.get(Uri.parse('https://archive.org/test'));

      expect(capturedHeaders?.containsKey('If-None-Match'), isFalse);
      client.close();
    });

    test('extractETag() extracts ETag from response headers', () {
      final response = http.Response(
        '{"test": true}',
        200,
        headers: {'etag': '"response-etag-123"'},
      );

      final etag = IAHttpClient.extractETag(response);
      expect(etag, equals('"response-etag-123"'));
    });

    test('extractETag() handles case-insensitive ETag header', () {
      // Test lowercase 'etag'
      final response1 = http.Response(
        '{}',
        200,
        headers: {'etag': '"lowercase"'},
      );
      expect(IAHttpClient.extractETag(response1), equals('"lowercase"'));

      // Test capitalized 'ETag'
      final response2 = http.Response(
        '{}',
        200,
        headers: {'ETag': '"capitalized"'},
      );
      expect(IAHttpClient.extractETag(response2), equals('"capitalized"'));

      // Test all-caps 'ETAG'
      final response3 = http.Response(
        '{}',
        200,
        headers: {'ETAG': '"allcaps"'},
      );
      expect(IAHttpClient.extractETag(response3), equals('"allcaps"'));
    });

    test('extractETag() returns null when no ETag header', () {
      final response = http.Response('{}', 200);
      expect(IAHttpClient.extractETag(response), isNull);
    });

    test('304 Not Modified response handled correctly', () async {
      final mockClient = MockClient((request) async {
        final ifNoneMatch = request.headers['If-None-Match'];

        if (ifNoneMatch == null) {
          // First request without ETag - return fresh data
          return http.Response(
            '{"data": "fresh"}',
            200,
            headers: {'etag': '"fresh-etag"'},
          );
        } else if (ifNoneMatch == '"fresh-etag"') {
          // Second request with matching ETag - return 304
          return http.Response('', 304, headers: {'etag': '"fresh-etag"'});
        } else {
          // Different ETag - return updated data
          return http.Response(
            '{"data": "updated"}',
            200,
            headers: {'etag': '"updated-etag"'},
          );
        }
      });

      final client = IAHttpClient(innerClient: mockClient);

      // First request - no cache
      final response1 = await client.get(Uri.parse('https://archive.org/test'));
      expect(response1.statusCode, equals(200));
      final etag1 = IAHttpClient.extractETag(response1);
      expect(etag1, equals('"fresh-etag"'));

      // Second request - with cached etag (should get 304)
      final response2 = await client.get(
        Uri.parse('https://archive.org/test'),
        ifNoneMatch: etag1,
      );
      expect(response2.statusCode, equals(304));
      expect(response2.body, isEmpty); // 304 has no body

      client.close();
    });

    test('Conditional GET workflow with ETag updates', () async {
      var requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;

        if (requestCount == 1) {
          // First request: return fresh data with ETag
          return http.Response(
            '{"identifier":"test","title":"Original"}',
            200,
            headers: {'etag': '"v1"'},
          );
        } else if (request.headers['If-None-Match'] == '"v1"') {
          // Same ETag: return 304
          return http.Response('', 304, headers: {'etag': '"v1"'});
        } else {
          // Different or no ETag: return updated data
          return http.Response(
            '{"identifier":"test","title":"Updated"}',
            200,
            headers: {'etag': '"v2"'},
          );
        }
      });

      final client = IAHttpClient(innerClient: mockClient);

      // Fetch original
      final response1 = await client.get(
        Uri.parse('https://archive.org/metadata/test'),
      );
      expect(response1.statusCode, equals(200));
      final etag1 = IAHttpClient.extractETag(response1);
      expect(etag1, equals('"v1"'));

      // Conditional refetch - should get 304
      final response2 = await client.get(
        Uri.parse('https://archive.org/metadata/test'),
        ifNoneMatch: etag1,
      );
      expect(response2.statusCode, equals(304));

      // Simulate data change - no If-None-Match
      final response3 = await client.get(
        Uri.parse('https://archive.org/metadata/test'),
      );
      expect(response3.statusCode, equals(200));
      final etag3 = IAHttpClient.extractETag(response3);
      expect(etag3, equals('"v2"'));

      client.close();
    });

    test('ETag with weak validator format', () {
      final response = http.Response(
        '{}',
        200,
        headers: {'etag': 'W/"weak-etag-123"'},
      );

      final etag = IAHttpClient.extractETag(response);
      expect(etag, equals('W/"weak-etag-123"'));
    });

    test('Multiple conditional GET requests with same ETag', () async {
      var callCount = 0;

      final mockClient = MockClient((request) async {
        callCount++;

        if (request.headers['If-None-Match'] == '"static-etag"') {
          return http.Response('', 304, headers: {'etag': '"static-etag"'});
        }

        return http.Response(
          '{"data": "value"}',
          200,
          headers: {'etag': '"static-etag"'},
        );
      });

      final client = IAHttpClient(innerClient: mockClient);

      // First call - no ETag
      final response1 = await client.get(Uri.parse('https://archive.org/test'));
      expect(response1.statusCode, equals(200));
      final etag = IAHttpClient.extractETag(response1);

      // Multiple conditional calls - all should get 304
      for (var i = 0; i < 3; i++) {
        final response = await client.get(
          Uri.parse('https://archive.org/test'),
          ifNoneMatch: etag,
        );
        expect(response.statusCode, equals(304));
      }

      expect(callCount, equals(4)); // 1 initial + 3 conditional

      client.close();
    });
  });
}
