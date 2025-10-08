import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/services/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    test('should allow up to maxConcurrent operations', () async {
      final limiter = RateLimiter(maxConcurrent: 3, minDelay: null);
      
      // Acquire 3 permits (should not block)
      await limiter.acquire();
      await limiter.acquire();
      await limiter.acquire();
      
      expect(limiter.activeCount, 3);
      expect(limiter.isAtCapacity, true);
      
      // Release all
      limiter.release();
      limiter.release();
      limiter.release();
      
      expect(limiter.activeCount, 0);
    });

    test('should queue requests beyond maxConcurrent', () async {
      final limiter = RateLimiter(maxConcurrent: 2, minDelay: null);
      
      // Acquire 2 permits (at capacity)
      await limiter.acquire();
      await limiter.acquire();
      
      expect(limiter.activeCount, 2);
      expect(limiter.isAtCapacity, true);
      
      // Try to acquire a third (should queue)
      final acquireFuture = limiter.acquire();
      await Future.delayed(const Duration(milliseconds: 10)); // Let it queue
      
      expect(limiter.queueLength, 1);
      expect(limiter.activeCount, 2); // Still at capacity
      
      // Release one permit - queued request should proceed
      limiter.release();
      await acquireFuture; // Should complete now
      
      expect(limiter.activeCount, 2); // Back to capacity
      expect(limiter.queueLength, 0); // Queue empty
      
      // Cleanup
      limiter.release();
      limiter.release();
    });

    test('execute() should handle acquire/release automatically', () async {
      final limiter = RateLimiter(maxConcurrent: 1, minDelay: null);
      
      var executed = false;
      final result = await limiter.execute(() async {
        expect(limiter.activeCount, 1);
        executed = true;
        return 'done';
      });
      
      expect(executed, true);
      expect(result, 'done');
      expect(limiter.activeCount, 0); // Released automatically
    });

    test('execute() should release permit even on error', () async {
      final limiter = RateLimiter(maxConcurrent: 1, minDelay: null);
      
      await expectLater(
        limiter.execute(() async {
          expect(limiter.activeCount, 1);
          throw Exception('test error');
        }),
        throwsA(isA<Exception>()),
      );
      
      expect(limiter.activeCount, 0); // Released despite error
    });

    test('should respect minDelay between releases', () async {
      final limiter = RateLimiter(
        maxConcurrent: 5,
        minDelay: const Duration(milliseconds: 100),
      );
      
      final startTime = DateTime.now();
      
      // Do 3 quick operations
      await limiter.execute(() async => await Future.delayed(const Duration(milliseconds: 10)));
      await limiter.execute(() async => await Future.delayed(const Duration(milliseconds: 10)));
      await limiter.execute(() async => await Future.delayed(const Duration(milliseconds: 10)));
      
      final elapsed = DateTime.now().difference(startTime);
      
      // Should take at least 200ms (2 delays of 100ms between 3 operations)
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(200));
    });

    test('getStats() should return accurate statistics', () {
      final limiter = RateLimiter(maxConcurrent: 3);
      
      final stats = limiter.getStats();
      expect(stats['active'], 0);
      expect(stats['queued'], 0);
      expect(stats['maxConcurrent'], 3);
      expect(stats['isAtCapacity'], false);
    });

    test('reset() should clear all state', () async {
      final limiter = RateLimiter(maxConcurrent: 1, minDelay: null);
      
      await limiter.acquire();
      final queuedFuture = limiter.acquire();
      
      // Should have 1 active and 1 queued
      expect(limiter.activeCount, 1);
      expect(limiter.queueLength, 1);
      
      limiter.reset();
      
      expect(limiter.activeCount, 0);
      expect(limiter.queueLength, 0);
      
      // Queued future should complete with error
      await expectLater(
        queuedFuture,
        throwsA(isA<StateError>()),
      );
    });

    test('concurrent execution stress test', () async {
      final limiter = RateLimiter(maxConcurrent: 3, minDelay: null);
      
      final results = <int>[];
      final futures = <Future>[];
      
      // Start 20 concurrent operations
      for (int i = 0; i < 20; i++) {
        futures.add(limiter.execute(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          results.add(i);
        }));
      }
      
      await Future.wait(futures);
      
      expect(results.length, 20);
      expect(limiter.activeCount, 0);
      expect(limiter.queueLength, 0);
    });
  });

  group('StaggeredStarter', () {
    test('should delay between starts', () async {
      final stagger = StaggeredStarter(
        delayBetweenStarts: const Duration(milliseconds: 100),
      );
      
      final startTime = DateTime.now();
      
      await stagger.waitForNextStart(); // First call - no delay
      await stagger.waitForNextStart(); // Should delay 100ms
      await stagger.waitForNextStart(); // Should delay 100ms
      
      final elapsed = DateTime.now().difference(startTime);
      
      // Should take at least 180ms (2 delays with some tolerance for CI)
      // Using 180ms instead of 200ms to account for timing variations in CI
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(180));
    });

    test('first call should not delay', () async {
      final stagger = StaggeredStarter(
        delayBetweenStarts: const Duration(milliseconds: 100),
      );
      
      final startTime = DateTime.now();
      await stagger.waitForNextStart();
      final elapsed = DateTime.now().difference(startTime);
      
      // First call should be immediate
      expect(elapsed.inMilliseconds, lessThan(50));
    });

    test('reset() should allow immediate next start', () async {
      final stagger = StaggeredStarter(
        delayBetweenStarts: const Duration(milliseconds: 100),
      );
      
      await stagger.waitForNextStart();
      stagger.reset();
      
      final startTime = DateTime.now();
      await stagger.waitForNextStart();
      final elapsed = DateTime.now().difference(startTime);
      
      // After reset, should be immediate
      expect(elapsed.inMilliseconds, lessThan(50));
    });
  });

  group('Global instances', () {
    test('archiveRateLimiter should be configured correctly', () {
      expect(archiveRateLimiter.maxConcurrent, 3);
      final stats = archiveRateLimiter.getStats();
      expect(stats['minDelayMs'], 150);
    });

    test('archiveStaggeredStarter should be configured correctly', () {
      expect(
        archiveStaggeredStarter.delayBetweenStarts,
        const Duration(milliseconds: 500),
      );
    });
  });
}
