import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:internet_archive_helper/services/ia_http_client.dart';
import 'package:internet_archive_helper/services/rate_limiter.dart';

void main() {
  group('IAHttpClient', () {
    late RateLimiter testRateLimiter;

    setUp(() {
      // Use a test rate limiter with no delays for faster tests
      testRateLimiter = RateLimiter(maxConcurrent: 10, minDelay: null);
    });

    test('should include User-Agent header in all requests', () async {
      String? capturedUserAgent;

      final mockClient = MockClient((request) async {
        capturedUserAgent = request.headers['User-Agent'];
        return http.Response('OK', 200);
      });

      final client = IAHttpClient(
        innerClient: mockClient,
        rateLimiter: testRateLimiter,
      );

      await client.get(Uri.parse('https://archive.org/test'));

      expect(capturedUserAgent, isNotNull);
      expect(capturedUserAgent, contains('InternetArchiveHelper'));
      expect(capturedUserAgent, contains('1.6.0'));
      expect(capturedUserAgent, contains('support@internetarchivehelper.app'));

      client.close();
    });

    test('should allow custom User-Agent', () async {
      String? capturedUserAgent;

      final mockClient = MockClient((request) async {
        capturedUserAgent = request.headers['User-Agent'];
        return http.Response('OK', 200);
      });

      final client = IAHttpClient(
        userAgent: 'CustomAgent/1.0',
        innerClient: mockClient,
        rateLimiter: testRateLimiter,
      );

      await client.get(Uri.parse('https://archive.org/test'));

      expect(capturedUserAgent, 'CustomAgent/1.0');

      client.close();
    });

    test('should retry on 429 Rate Limited', () async {
      int attemptCount = 0;

      final mockClient = MockClient((request) async {
        attemptCount++;
        if (attemptCount < 3) {
          return http.Response('Rate Limited', 429);
        }
        return http.Response('OK', 200);
      });

      final client = IAHttpClient(
        innerClient: mockClient,
        rateLimiter: testRateLimiter,
        customRetryDelays: [
          const Duration(milliseconds: 10),
          const Duration(milliseconds: 10),
          const Duration(milliseconds: 10),
        ],
      );

      final response = await client.get(Uri.parse('https://archive.org/test'));

      expect(attemptCount, 3);
      expect(response.statusCode, 200);

      client.close();
    });

    test('should retry on 503 Service Unavailable', () async {
      int attemptCount = 0;

      final mockClient = MockClient((request) async {
        attemptCount++;
        if (attemptCount < 2) {
          return http.Response('Service Unavailable', 503);
        }
        return http.Response('OK', 200);
      });

      final client = IAHttpClient(
        innerClient: mockClient,
        rateLimiter: testRateLimiter,
        customRetryDelays: [const Duration(milliseconds: 10)],
      );

      final response = await client.get(Uri.parse('https://archive.org/test'));

      expect(attemptCount, 2);
      expect(response.statusCode, 200);

      client.close();
    });

    test('should respect Retry-After header', () async {
      int attemptCount = 0;
      final startTime = DateTime.now();

      final mockClient = MockClient((request) async {
        attemptCount++;
        if (attemptCount == 1) {
          return http.Response(
            'Rate Limited',
            429,
            headers: {'Retry-After': '1'}, // 1 second
          );
        }
        return http.Response('OK', 200);
      });

      final client = IAHttpClient(
        innerClient: mockClient,
        rateLimiter: testRateLimiter,
      );

      final response = await client.get(Uri.parse('https://archive.org/test'));
      final elapsed = DateTime.now().difference(startTime);

      expect(attemptCount, 2);
      expect(response.statusCode, 200);
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(900)); // ~1 second

      client.close();
    });

    test('should use exponential backoff for retries', () async {
      int attemptCount = 0;
      final attemptTimes = <DateTime>[];

      final mockClient = MockClient((request) async {
        attemptCount++;
        attemptTimes.add(DateTime.now());

        if (attemptCount < 4) {
          return http.Response('Service Unavailable', 503);
        }
        return http.Response('OK', 200);
      });

      final client = IAHttpClient(
        innerClient: mockClient,
        rateLimiter: testRateLimiter,
        customRetryDelays: [
          const Duration(milliseconds: 100), // 1st retry
          const Duration(milliseconds: 200), // 2nd retry
          const Duration(milliseconds: 400), // 3rd retry
        ],
      );

      await client.get(Uri.parse('https://archive.org/test'));

      expect(attemptCount, 4);

      // Check delays between attempts
      final delay1 = attemptTimes[1].difference(attemptTimes[0]);
      final delay2 = attemptTimes[2].difference(attemptTimes[1]);
      final delay3 = attemptTimes[3].difference(attemptTimes[2]);

      expect(delay1.inMilliseconds, greaterThanOrEqualTo(90));
      expect(delay2.inMilliseconds, greaterThanOrEqualTo(190));
      expect(delay3.inMilliseconds, greaterThanOrEqualTo(390));

      client.close();
    });

    test('should throw after max retries exceeded', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Service Unavailable', 503);
      });

      final client = IAHttpClient(
        innerClient: mockClient,
        rateLimiter: testRateLimiter,
        maxRetries: 2,
        customRetryDelays: [
          const Duration(milliseconds: 10),
          const Duration(milliseconds: 10),
        ],
      );

      await expectLater(
        client.get(Uri.parse('https://archive.org/test')),
        throwsA(
          isA<IAHttpException>().having(
            (e) => e.type,
            'type',
            IAHttpExceptionType.serverError,
          ),
        ),
      );

      client.close();
    });

    test('should not retry on 404 Not Found', () async {
      int attemptCount = 0;

      final mockClient = MockClient((request) async {
        attemptCount++;
        return http.Response('Not Found', 404);
      });

      final client = IAHttpClient(
        innerClient: mockClient,
        rateLimiter: testRateLimiter,
      );

      await expectLater(
        client.get(Uri.parse('https://archive.org/test')),
        throwsA(
          isA<IAHttpException>().having(
            (e) => e.type,
            'type',
            IAHttpExceptionType.notFound,
          ),
        ),
      );

      expect(attemptCount, 1); // No retries

      client.close();
    });

    test('should not retry on 400 Bad Request', () async {
      int attemptCount = 0;

      final mockClient = MockClient((request) async {
        attemptCount++;
        return http.Response('Bad Request', 400);
      });

      final client = IAHttpClient(
        innerClient: mockClient,
        rateLimiter: testRateLimiter,
      );

      await expectLater(
        client.get(Uri.parse('https://archive.org/test')),
        throwsA(
          isA<IAHttpException>().having(
            (e) => e.type,
            'type',
            IAHttpExceptionType.clientError,
          ),
        ),
      );

      expect(attemptCount, 1); // No retries

      client.close();
    });

    test('should handle timeout', () async {
      final mockClient = MockClient((request) async {
        await Future.delayed(const Duration(seconds: 2));
        return http.Response('OK', 200);
      });

      final client = IAHttpClient(
        innerClient: mockClient,
        rateLimiter: testRateLimiter,
        defaultTimeout: const Duration(milliseconds: 100),
      );

      await expectLater(
        client.get(Uri.parse('https://archive.org/test')),
        throwsA(
          isA<IAHttpException>().having(
            (e) => e.type,
            'type',
            IAHttpExceptionType.timeout,
          ),
        ),
      );

      client.close();
    });

    test('should support custom timeout per request', () async {
      final mockClient = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 150));
        return http.Response('OK', 200);
      });

      final client = IAHttpClient(
        innerClient: mockClient,
        rateLimiter: testRateLimiter,
        defaultTimeout: const Duration(milliseconds: 100), // Default timeout
      );

      // Should timeout with default
      await expectLater(
        client.get(Uri.parse('https://archive.org/test')),
        throwsA(isA<IAHttpException>()),
      );

      // Should succeed with custom timeout
      final response = await client.get(
        Uri.parse('https://archive.org/test'),
        timeout: const Duration(milliseconds: 200),
      );
      expect(response.statusCode, 200);

      client.close();
    });

    test('should integrate with rate limiter', () async {
      final rateLimiter = RateLimiter(maxConcurrent: 2, minDelay: null);
      int concurrentCount = 0;
      int maxConcurrent = 0;

      final mockClient = MockClient((request) async {
        concurrentCount++;
        maxConcurrent = concurrentCount > maxConcurrent
            ? concurrentCount
            : maxConcurrent;
        await Future.delayed(const Duration(milliseconds: 50));
        concurrentCount--;
        return http.Response('OK', 200);
      });

      final client = IAHttpClient(
        innerClient: mockClient,
        rateLimiter: rateLimiter,
      );

      // Start 10 concurrent requests
      final futures = List.generate(
        10,
        (i) => client.get(Uri.parse('https://archive.org/test$i')),
      );

      await Future.wait(futures);

      // Should never exceed maxConcurrent=2
      expect(maxConcurrent, lessThanOrEqualTo(2));

      client.close();
    });

    test('should support POST requests', () async {
      String? capturedMethod;
      String? capturedBody;

      final mockClient = MockClient((request) async {
        capturedMethod = request.method;
        capturedBody = request.body;
        return http.Response('OK', 200);
      });

      final client = IAHttpClient(
        innerClient: mockClient,
        rateLimiter: testRateLimiter,
      );

      await client.post(
        Uri.parse('https://archive.org/test'),
        body: 'test data',
      );

      expect(capturedMethod, 'POST');
      expect(capturedBody, 'test data');

      client.close();
    });

    test('should support HEAD requests', () async {
      String? capturedMethod;

      final mockClient = MockClient((request) async {
        capturedMethod = request.method;
        return http.Response('', 200, headers: {'content-length': '12345'});
      });

      final client = IAHttpClient(
        innerClient: mockClient,
        rateLimiter: testRateLimiter,
      );

      final response = await client.head(Uri.parse('https://archive.org/test'));

      expect(capturedMethod, 'HEAD');
      expect(response.headers['content-length'], '12345');

      client.close();
    });

    test('IAHttpException should categorize error types correctly', () {
      expect(
        const IAHttpException(
          'test',
          statusCode: 429,
          type: IAHttpExceptionType.rateLimited,
        ).isTransient,
        true,
      );
      expect(
        const IAHttpException(
          'test',
          statusCode: 503,
          type: IAHttpExceptionType.serverError,
        ).isTransient,
        true,
      );
      expect(
        const IAHttpException(
          'test',
          statusCode: 404,
          type: IAHttpExceptionType.notFound,
        ).isTransient,
        false,
      );
      expect(
        const IAHttpException(
          'test',
          statusCode: 400,
          type: IAHttpExceptionType.clientError,
        ).isTransient,
        false,
      );
    });

    test('should provide rate limiter statistics', () {
      final client = IAHttpClient(rateLimiter: testRateLimiter);

      final stats = client.getStats();

      expect(stats, isNotNull);
      expect(stats['maxConcurrent'], 10);
      expect(stats['active'], isA<int>());
      expect(stats['queued'], isA<int>());

      client.close();
    });

    group('Retry-After header parsing', () {
      test('should parse Retry-After as seconds', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            'Rate limited',
            429,
            headers: {'Retry-After': '120'},
          );
        });

        final client = IAHttpClient(
          innerClient: mockClient,
          rateLimiter: testRateLimiter,
          maxRetries: 0, // Don't retry for this test
        );

        try {
          await client.get(Uri.parse('https://archive.org/test'));
          fail('Should have thrown IAHttpException');
        } on IAHttpException catch (e) {
          expect(e.statusCode, 429);

          // Check rate limit status includes retry-after info
          final status = client.getRateLimitStatus();
          expect(status.retryAfterSeconds, 120);
          expect(status.retryAfterExpiry, isNotNull);
        }

        client.close();
      });

      test('should parse Retry-After as HTTP date', () async {
        // Create a date 60 seconds in the future
        final futureDate = DateTime.now().add(const Duration(seconds: 60));
        final httpDate = HttpDate.format(futureDate);

        final mockClient = MockClient((request) async {
          return http.Response(
            'Rate limited',
            429,
            headers: {'Retry-After': httpDate},
          );
        });

        final client = IAHttpClient(
          innerClient: mockClient,
          rateLimiter: testRateLimiter,
          maxRetries: 0, // Don't retry for this test
        );

        try {
          await client.get(Uri.parse('https://archive.org/test'));
          fail('Should have thrown IAHttpException');
        } on IAHttpException catch (e) {
          expect(e.statusCode, 429);

          // Check rate limit status includes retry-after info
          final status = client.getRateLimitStatus();
          expect(status.retryAfterSeconds, isNotNull);
          // Should be approximately 60 seconds (allow 5 second tolerance for test execution)
          expect(status.retryAfterSeconds, greaterThanOrEqualTo(55));
          expect(status.retryAfterSeconds, lessThanOrEqualTo(65));
          expect(status.retryAfterExpiry, isNotNull);
        }

        client.close();
      });

      test('should handle invalid Retry-After gracefully', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            'Rate limited',
            429,
            headers: {'Retry-After': 'invalid-date-format'},
          );
        });

        final client = IAHttpClient(
          innerClient: mockClient,
          rateLimiter: testRateLimiter,
          maxRetries: 0, // Don't retry for this test
        );

        try {
          await client.get(Uri.parse('https://archive.org/test'));
          fail('Should have thrown IAHttpException');
        } on IAHttpException catch (e) {
          expect(e.statusCode, 429);

          // Should not crash, just use default retry behavior
          final status = client.getRateLimitStatus();
          // Invalid format should result in null values
          expect(status.retryAfterSeconds, isNull);
        }

        client.close();
      });
    });
  });
}
