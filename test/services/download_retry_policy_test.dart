import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/services/download_retry_policy.dart';

void main() {
  group('DownloadRetryPolicy.shouldRetry', () {
    final policy = DownloadRetryPolicy(random: Random(42));

    test('flaky errors are retryable', () {
      const retryable = [
        'Failed to download file: HTTP 503',
        'Failed to download file: HTTP 500',
        'Failed to download file: HTTP 429',
        'Failed to download file: HTTP 408',
        'Connection timeout',
        'Checksum mismatch (corrupt download): item.pdf',
        'Connection closed early: got 12 of 40 bytes',
      ];

      for (final message in retryable) {
        expect(
          policy.shouldRetry(message, attempt: 0, maxAttempts: 3),
          isTrue,
          reason: message,
        );
      }
    });

    test('unrecoverable errors are never retried', () {
      const fatal = [
        'Failed to download file: HTTP 404',
        'Failed to download file: HTTP 403',
        'Failed to download file: HTTP 401',
        'Failed to download file: HTTP 410',
        'Archive item "x" not found (404)',
        'Permission denied',
        'Insufficient space',
      ];

      for (final message in fatal) {
        expect(
          policy.shouldRetry(message, attempt: 0, maxAttempts: 3),
          isFalse,
          reason: message,
        );
      }
    });

    test('attempt cap is respected', () {
      expect(
        policy.shouldRetry('HTTP 503', attempt: 3, maxAttempts: 3),
        isFalse,
      );
      expect(
        policy.shouldRetry('HTTP 503', attempt: 2, maxAttempts: 3),
        isTrue,
      );
      // Fatal errors are refused even with attempts remaining
      expect(
        policy.shouldRetry('HTTP 404', attempt: 0, maxAttempts: 3),
        isFalse,
      );
    });
  });

  group('DownloadRetryPolicy.delayFor', () {
    test('exponential backoff, capped, without jitter', () {
      final policy = DownloadRetryPolicy(
        baseDelay: const Duration(seconds: 10),
        maxDelay: const Duration(minutes: 5),
        jitterFraction: 0,
      );

      expect(policy.delayFor(0), const Duration(seconds: 10));
      expect(policy.delayFor(1), const Duration(seconds: 20));
      expect(policy.delayFor(2), const Duration(seconds: 40));
      expect(policy.delayFor(3), const Duration(seconds: 80));
      expect(policy.delayFor(4), const Duration(seconds: 160));
      expect(policy.delayFor(5), const Duration(minutes: 5)); // capped
      expect(policy.delayFor(30), const Duration(minutes: 5)); // no overflow
    });

    test('jitter stays within [base, base + jitterFraction * base)', () {
      final policy = DownloadRetryPolicy(
        baseDelay: const Duration(seconds: 10),
        jitterFraction: 0.25,
        random: Random(7),
      );

      for (var i = 0; i < 100; i++) {
        final delay = policy.delayFor(0);
        expect(delay.inMilliseconds, greaterThanOrEqualTo(10000));
        expect(delay.inMilliseconds, lessThan(12500));
      }
    });
  });
}
