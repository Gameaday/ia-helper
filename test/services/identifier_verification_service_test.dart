import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/services/identifier_verification_service.dart';
import 'package:internet_archive_helper/models/identifier_cache_metrics.dart';

void main() {
  group('IdentifierCacheMetrics', () {
    test('initial state is all zeros', () {
      final metrics = IdentifierCacheMetrics();
      expect(metrics.cacheHits, equals(0));
      expect(metrics.cacheMisses, equals(0));
      expect(metrics.standardHits, equals(0));
      expect(metrics.strictHits, equals(0));
      expect(metrics.alternativeHits, equals(0));
      expect(metrics.apiCallsMade, equals(0));
      expect(metrics.apiCallsSaved, equals(0));
    });

    test('hit rate calculation', () {
      final metrics = IdentifierCacheMetrics(cacheHits: 75, cacheMisses: 25);
      expect(metrics.hitRate, equals(0.75));
      expect(metrics.hitRatePercent, equals('75.0%'));
    });

    test('api reduction rate calculation', () {
      final metrics = IdentifierCacheMetrics(
        apiCallsMade: 30,
        apiCallsSaved: 70,
      );
      expect(metrics.apiReductionRate, equals(0.70));
      expect(metrics.apiReductionPercent, equals('70.0%'));
    });

    test('standard success rate calculation', () {
      final metrics = IdentifierCacheMetrics(
        standardHits: 60,
        strictHits: 30,
        alternativeHits: 10,
      );
      expect(metrics.standardSuccessRate, equals(0.6));
      expect(metrics.strictSuccessRate, equals(0.3));
      expect(metrics.alternativeSuccessRate, equals(0.1));
    });

    test('incrementHit updates correctly', () {
      var metrics = IdentifierCacheMetrics();
      metrics = metrics.incrementHit(isStandard: true);

      expect(metrics.cacheHits, equals(1));
      expect(metrics.apiCallsSaved, equals(1));
      expect(metrics.standardHits, equals(1));
      expect(metrics.strictHits, equals(0));
      expect(metrics.alternativeHits, equals(0));
    });

    test('incrementMiss updates correctly', () {
      var metrics = IdentifierCacheMetrics();
      metrics = metrics.incrementMiss();

      expect(metrics.cacheMisses, equals(1));
      expect(metrics.apiCallsMade, equals(1));
    });

    test('reset clears all metrics', () {
      var metrics = IdentifierCacheMetrics(
        cacheHits: 100,
        cacheMisses: 50,
        standardHits: 60,
      );
      metrics = metrics.reset();

      expect(metrics.cacheHits, equals(0));
      expect(metrics.cacheMisses, equals(0));
      expect(metrics.standardHits, equals(0));
    });

    test('toJson and fromJson work correctly', () {
      final original = IdentifierCacheMetrics(
        cacheHits: 100,
        cacheMisses: 50,
        standardHits: 60,
        strictHits: 30,
        alternativeHits: 10,
        apiCallsMade: 50,
        apiCallsSaved: 100,
      );

      final json = original.toJson();
      final restored = IdentifierCacheMetrics.fromJson(json);

      expect(restored.cacheHits, equals(original.cacheHits));
      expect(restored.cacheMisses, equals(original.cacheMisses));
      expect(restored.standardHits, equals(original.standardHits));
      expect(restored.strictHits, equals(original.strictHits));
      expect(restored.alternativeHits, equals(original.alternativeHits));
    });

    test('handles zero division gracefully', () {
      final metrics = IdentifierCacheMetrics();
      expect(metrics.hitRate, equals(0.0));
      expect(metrics.apiReductionRate, equals(0.0));
      expect(metrics.standardSuccessRate, equals(0.0));
    });
  });

  group('IdentifierVerificationService', () {
    late IdentifierVerificationService service;

    setUp(() {
      service = IdentifierVerificationService.instance;
      service.clearCache();
      service.resetMetrics();
    });

    test('singleton instance is consistent', () {
      final instance1 = IdentifierVerificationService.instance;
      final instance2 = IdentifierVerificationService.instance;
      expect(instance1, same(instance2));
    });

    test('initial metrics are zero', () {
      final metrics = service.metrics;
      expect(metrics.cacheHits, equals(0));
      expect(metrics.cacheMisses, equals(0));
      expect(metrics.apiCallsMade, equals(0));
    });

    test('clearCache empties the cache', () {
      service.clearCache();
      final stats = service.getCacheStats();
      expect(stats['size'], equals(0));
    });

    test('resetMetrics resets all metrics', () {
      service.resetMetrics();
      final metrics = service.metrics;
      expect(metrics.cacheHits, equals(0));
      expect(metrics.cacheMisses, equals(0));
    });

    test('getCacheStats returns comprehensive information', () {
      final stats = service.getCacheStats();
      expect(stats.containsKey('size'), isTrue);
      expect(stats.containsKey('metrics'), isTrue);
      expect(stats.containsKey('hitRate'), isTrue);
      expect(stats.containsKey('apiReduction'), isTrue);
      expect(stats.containsKey('standardSuccessRate'), isTrue);
      expect(stats.containsKey('strictSuccessRate'), isTrue);
      expect(stats.containsKey('alternativeSuccessRate'), isTrue);
    });

    // Note: Integration tests with actual API calls should be in a separate
    // integration test suite to avoid making real HTTP requests in unit tests.
    // These tests focus on the service's logic, caching, and metrics tracking.
  });

  group('IdentifierVerificationService - Metrics Tracking', () {
    test('demonstrates expected metrics flow', () {
      // This is a demonstration of how metrics should work
      var metrics = IdentifierCacheMetrics();

      // Scenario: User searches for "Mario"
      // 1. First search - cache miss, API call to standard variant "Mario"
      metrics = metrics.incrementMiss();
      expect(metrics.cacheMisses, equals(1));
      expect(metrics.apiCallsMade, equals(1));

      // 2. "Mario" not found, try strict "mario" - another API call
      metrics = metrics.incrementMiss();
      expect(metrics.cacheMisses, equals(2));
      expect(metrics.apiCallsMade, equals(2));

      // 3. "mario" found! Cache it and track as strict hit
      metrics = metrics.incrementHit(isStrict: true);
      expect(metrics.strictHits, equals(1));
      expect(metrics.apiCallsSaved, equals(1));

      // 4. User searches for "mario" again - cache hit!
      metrics = metrics.incrementHit(isStrict: true);
      expect(metrics.cacheHits, equals(2));
      expect(metrics.apiCallsSaved, equals(2));

      // 5. User searches for "MARIO" - normalizes to "mario", cache hit!
      metrics = metrics.incrementHit(isStrict: true);
      expect(metrics.cacheHits, equals(3));
      expect(metrics.apiCallsSaved, equals(3));

      // Results:
      // - API calls made: 2 (initial checks)
      // - API calls saved: 3 (cache hits)
      // - API reduction: 3/(2+3) = 60%
      expect(metrics.apiCallsMade, equals(2));
      expect(metrics.apiCallsSaved, equals(3));
      expect(metrics.apiReductionRate, closeTo(0.6, 0.01));
    });

    test('demonstrates standard vs strict success tracking', () {
      var metrics = IdentifierCacheMetrics();

      // Scenario: Track which normalization level succeeds most often

      // Case 1: "MyArchive" found with standard (preserves case)
      metrics = metrics.incrementMiss(); // API call
      metrics = metrics.incrementHit(isStandard: true);

      // Case 2: "another-archive" found with standard (already lowercase)
      metrics = metrics.incrementMiss();
      metrics = metrics.incrementHit(isStandard: true);

      // Case 3: "SomeArchive" not found with standard, found with strict
      metrics = metrics.incrementMiss(); // Try standard
      metrics = metrics.incrementMiss(); // Try strict
      metrics = metrics.incrementHit(isStrict: true);

      // Case 4: "Test Archive" not found standard/strict, found with alternative
      metrics = metrics.incrementMiss(); // Standard
      metrics = metrics.incrementMiss(); // Strict
      metrics = metrics.incrementMiss(); // Alternative
      metrics = metrics.incrementHit(isAlternative: true);

      // Results show success distribution:
      expect(metrics.standardHits, equals(2)); // 50%
      expect(metrics.strictHits, equals(1)); // 25%
      expect(metrics.alternativeHits, equals(1)); // 25%
      expect(metrics.standardSuccessRate, closeTo(0.5, 0.01));
      expect(metrics.strictSuccessRate, closeTo(0.25, 0.01));
      expect(metrics.alternativeSuccessRate, closeTo(0.25, 0.01));
    });

    test('demonstrates cache efficiency improvement over time', () {
      var metrics = IdentifierCacheMetrics();

      // Phase 1: Cold cache - everything is a miss
      for (int i = 0; i < 10; i++) {
        metrics = metrics.incrementMiss();
      }
      expect(metrics.hitRate, equals(0.0)); // 0% hit rate
      expect(metrics.apiReductionRate, equals(0.0)); // 0% reduction

      // Phase 2: Cache warming up - some hits
      for (int i = 0; i < 5; i++) {
        metrics = metrics.incrementHit(isStandard: true);
      }
      expect(metrics.hitRate, closeTo(0.33, 0.01)); // 33% hit rate
      expect(metrics.apiReductionRate, closeTo(0.33, 0.01)); // 33% reduction

      // Phase 3: Hot cache - mostly hits
      for (int i = 0; i < 20; i++) {
        metrics = metrics.incrementHit(isStandard: true);
      }
      expect(metrics.hitRate, closeTo(0.71, 0.01)); // 71% hit rate
      expect(metrics.apiReductionRate, closeTo(0.71, 0.01)); // 71% reduction

      // Total: 10 misses, 25 hits = 71.4% hit rate
      expect(metrics.cacheMisses, equals(10));
      expect(metrics.cacheHits, equals(25));
      expect(metrics.apiCallsMade, equals(10));
      expect(metrics.apiCallsSaved, equals(25));
    });
  });
}
