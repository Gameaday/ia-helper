import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/models/cached_metadata.dart';
import 'package:internet_archive_helper/models/archive_metadata.dart';

void main() {
  group('CachedMetadata', () {
    late ArchiveMetadata sampleMetadata;

    setUp(() {
      sampleMetadata = ArchiveMetadata(
        identifier: 'test-archive-123',
        title: 'Test Archive',
        creator: 'Test Creator',
        description: 'Test description',
        date: '2024-01-01',
        files: [],
        totalFiles: 10,
        totalSize: 1024000, // 1 MB
      );
    });

    group('Factory Constructors', () {
      test('fromMetadata creates CachedMetadata with correct defaults', () {
        final cached = CachedMetadata.fromMetadata(
          sampleMetadata,
          isPinned: false,
        );

        expect(cached.identifier, equals('test-archive-123'));
        expect(cached.metadata, equals(sampleMetadata));
        expect(cached.isPinned, isFalse);
        expect(cached.cachedAt, isNotNull);
        expect(cached.lastAccessed, isNotNull);
        expect(cached.lastSynced, isNotNull);
      });

      test('fromMetadata creates pinned CachedMetadata', () {
        final cached = CachedMetadata.fromMetadata(
          sampleMetadata,
          isPinned: true,
        );

        expect(cached.isPinned, isTrue);
      });
    });

    group('Staleness Checking', () {
      test('isStale returns false for newly cached metadata', () {
        final cached = CachedMetadata.fromMetadata(sampleMetadata);
        final maxAge = const Duration(days: 30);

        expect(cached.isStale(maxAge), isFalse);
      });

      test('isStale returns true for old metadata', () {
        final oldTimestamp = DateTime.now().subtract(const Duration(days: 31));

        final cached = CachedMetadata(
          identifier: 'test-archive-123',
          metadata: sampleMetadata,
          cachedAt: oldTimestamp,
          lastAccessed: oldTimestamp,
          lastSynced: oldTimestamp,
          isPinned: false,
          fileCount: 10,
          totalSize: 1024000,
        );

        final maxAge = const Duration(days: 30);
        expect(cached.isStale(maxAge), isTrue);
      });

      test('isStale uses lastSynced if available', () async {
        final now = DateTime.now();
        final oldCachedAt = now.subtract(const Duration(days: 60));
        final recentSync = now.subtract(const Duration(days: 5));

        final cached = CachedMetadata(
          identifier: 'test-archive-123',
          metadata: sampleMetadata,
          cachedAt: oldCachedAt,
          lastAccessed: now,
          lastSynced: recentSync,
          isPinned: false,
          fileCount: 10,
          totalSize: 1024000,
        );

        final maxAge = const Duration(days: 30);
        expect(cached.isStale(maxAge), isFalse);
      });
    });

    group('Purge Eligibility', () {
      test('shouldPurge returns false for pinned archive', () {
        final cached = CachedMetadata.fromMetadata(
          sampleMetadata,
          isPinned: true,
        );

        final retentionPeriod = const Duration(days: 7);
        expect(cached.shouldPurge(retentionPeriod), isFalse);
      });

      test('shouldPurge returns false for recently accessed archive', () {
        final cached = CachedMetadata.fromMetadata(sampleMetadata);
        final retentionPeriod = const Duration(days: 7);

        expect(cached.shouldPurge(retentionPeriod), isFalse);
      });

      test('shouldPurge returns true for old unpinned archive', () {
        final oldTimestamp = DateTime.now().subtract(const Duration(days: 8));

        final cached = CachedMetadata(
          identifier: 'test-archive-123',
          metadata: sampleMetadata,
          cachedAt: oldTimestamp,
          lastAccessed: oldTimestamp,
          lastSynced: oldTimestamp,
          isPinned: false,
          fileCount: 10,
          totalSize: 1024000,
        );

        final retentionPeriod = const Duration(days: 7);
        expect(cached.shouldPurge(retentionPeriod), isTrue);
      });
    });

    group('Timestamp Updates', () {
      test('markAccessed updates lastAccessed timestamp', () async {
        final cached = CachedMetadata.fromMetadata(sampleMetadata);
        final originalTimestamp = cached.lastAccessed;

        // Wait a moment to ensure timestamp difference
        await Future.delayed(const Duration(milliseconds: 10));

        final updated = cached.markAccessed();

        expect(updated.lastAccessed.isAfter(originalTimestamp), isTrue);
        expect(updated.identifier, equals(cached.identifier));
      });

      test('markSynced updates lastSynced timestamp', () async {
        final cached = CachedMetadata.fromMetadata(sampleMetadata);
        final originalSynced = cached.lastSynced;

        await Future.delayed(const Duration(milliseconds: 10));

        final updated = cached.markSynced();

        expect(updated.lastSynced!.isAfter(originalSynced!), isTrue);
      });
    });

    group('Pin Toggle', () {
      test('togglePin changes pin status', () {
        final cached = CachedMetadata.fromMetadata(
          sampleMetadata,
          isPinned: false,
        );

        final pinned = cached.togglePin();
        expect(pinned.isPinned, isTrue);

        final unpinned = pinned.togglePin();
        expect(unpinned.isPinned, isFalse);
      });
    });

    group('Human-Readable Formatters', () {
      test('cacheAgeString formats correctly', () {
        final cached = CachedMetadata.fromMetadata(sampleMetadata);
        expect(cached.cacheAgeString, isNotEmpty);
      });

      test('syncStatusString shows last sync time', () {
        final cached = CachedMetadata.fromMetadata(sampleMetadata);
        // Should show sync status ("Just synced" or "Synced X ago")
        expect(cached.syncStatusString, isNotEmpty);
      });

      test('formattedSize converts bytes correctly', () {
        final cached = CachedMetadata.fromMetadata(sampleMetadata);
        // 1 MB = 1024000 bytes - formattedSize uses totalSize
        expect(cached.formattedSize, isNotEmpty);
      });

      test('formattedSize handles MB correctly', () {
        final largeMetadata = ArchiveMetadata(
          identifier: 'large-archive',
          title: 'Large Archive',
          files: [],
          totalFiles: 100,
          totalSize: 5000000, // 5 MB
        );

        final cached = CachedMetadata.fromMetadata(largeMetadata);
        expect(cached.formattedSize, isNotEmpty);
      });

      test('formattedSize handles GB correctly', () {
        final hugeMetadata = ArchiveMetadata(
          identifier: 'huge-archive',
          title: 'Huge Archive',
          files: [],
          totalFiles: 1000,
          totalSize: 2000000000, // 2 GB
        );

        final cached = CachedMetadata.fromMetadata(hugeMetadata);
        expect(cached.formattedSize, isNotEmpty);
      });
    });

    group('Serialization', () {
      test('toMap and fromMap preserve data', () {
        final cached = CachedMetadata.fromMetadata(
          sampleMetadata,
          isPinned: true,
        );

        final map = cached.toMap();
        final restored = CachedMetadata.fromMap(map);

        expect(restored.identifier, equals(cached.identifier));
        expect(restored.isPinned, equals(cached.isPinned));
        // Compare milliseconds since epoch to avoid microsecond precision issues
        expect(restored.cachedAt.millisecondsSinceEpoch,
            equals(cached.cachedAt.millisecondsSinceEpoch));
        expect(restored.lastAccessed.millisecondsSinceEpoch,
            equals(cached.lastAccessed.millisecondsSinceEpoch));
        expect(restored.metadata.title, equals(cached.metadata.title));
      });
    });
  });
}
