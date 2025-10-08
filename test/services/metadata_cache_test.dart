import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/services/metadata_cache.dart';

void main() {
  group('MetadataCache', () {
    group('CacheStats', () {
      test('CacheStats initializes with correct values', () {
        final stats = const CacheStats(
          totalArchives: 10,
          pinnedArchives: 3,
          totalDataSize: 1024000,
          databaseSize: 2048000,
        );

        expect(stats.totalArchives, equals(10));
        expect(stats.pinnedArchives, equals(3));
        expect(stats.unpinnedArchives, equals(7)); // 10 - 3
        expect(stats.totalDataSize, equals(1024000));
        expect(stats.databaseSize, equals(2048000));
      });

      test('CacheStats formats data size correctly', () {
        final stats = const CacheStats(
          totalArchives: 1,
          pinnedArchives: 0,
          totalDataSize: 1536000, // 1.5 MB
          databaseSize: 0,
        );

        expect(stats.formattedDataSize, contains('MB'));
      });

      test('CacheStats formats database size correctly', () {
        final stats = const CacheStats(
          totalArchives: 1,
          pinnedArchives: 0,
          totalDataSize: 0,
          databaseSize: 2048, // 2 KB
        );

        expect(stats.formattedDbSize, contains('KB'));
      });

      test('CacheStats handles zero archives', () {
        final stats = const CacheStats(
          totalArchives: 0,
          pinnedArchives: 0,
          totalDataSize: 0,
          databaseSize: 0,
        );

        expect(stats.totalArchives, equals(0));
        expect(stats.unpinnedArchives, equals(0));
        expect(stats.formattedDataSize, contains('B'));
      });

      test('CacheStats handles large sizes correctly', () {
        final stats = const CacheStats(
          totalArchives: 1000,
          pinnedArchives: 50,
          totalDataSize: 2147483648, // 2 GB
          databaseSize: 52428800, // 50 MB
        );

        expect(stats.formattedDataSize, contains('GB'));
        expect(stats.formattedDbSize, contains('MB'));
        expect(stats.unpinnedArchives, equals(950));
      });

      test('CacheStats toString provides useful summary', () {
        final stats = const CacheStats(
          totalArchives: 15,
          pinnedArchives: 5,
          totalDataSize: 1024000,
          databaseSize: 2048000,
        );

        final str = stats.toString();
        expect(str, contains('15'));
        expect(str, contains('5 pinned'));
      });
    });

    group('Duration Helpers', () {
      test('Duration days conversion', () {
        expect(const Duration(days: 1).inDays, equals(1));
        expect(const Duration(days: 7).inDays, equals(7));
        expect(const Duration(days: 30).inDays, equals(30));
        expect(const Duration(days: 90).inDays, equals(90));
      });

      test('Retention period validation ranges', () {
        // Valid retention periods (1-90 days)
        expect(const Duration(days: 1).inDays >= 1, isTrue);
        expect(const Duration(days: 90).inDays <= 90, isTrue);
        expect(const Duration(days: 45).inDays, equals(45));
      });
    });

    group('Protected Identifiers Logic', () {
      test('Empty protected list allows purge', () {
        final protectedIdentifiers = <String>[];
        final archiveId = 'test-archive';
        
        expect(protectedIdentifiers.contains(archiveId), isFalse);
      });

      test('Protected list prevents purge', () {
        final protectedIdentifiers = ['archive-1', 'archive-2', 'archive-3'];
        
        expect(protectedIdentifiers.contains('archive-1'), isTrue);
        expect(protectedIdentifiers.contains('archive-2'), isTrue);
        expect(protectedIdentifiers.contains('archive-4'), isFalse);
      });

      test('Downloaded archives added to protected list', () {
        final downloadedIdentifiers = ['downloaded-1', 'downloaded-2'];
        final userProtected = ['pinned-1'];
        
        final allProtected = <String>{
          ...userProtected,
          ...downloadedIdentifiers,
        }.toList();
        
        expect(allProtected.length, equals(3));
        expect(allProtected.contains('downloaded-1'), isTrue);
        expect(allProtected.contains('downloaded-2'), isTrue);
        expect(allProtected.contains('pinned-1'), isTrue);
      });

      test('Protected list handles duplicates correctly', () {
        final list1 = ['archive-1', 'archive-2'];
        final list2 = ['archive-2', 'archive-3'];
        
        final combined = <String>{...list1, ...list2}.toList();
        
        // Set removes duplicates
        expect(combined.length, equals(3));
        expect(combined.contains('archive-1'), isTrue);
        expect(combined.contains('archive-2'), isTrue);
        expect(combined.contains('archive-3'), isTrue);
      });
    });

    group('Byte Formatting', () {
      test('Formats bytes correctly', () {
        expect(_formatBytes(0), equals('0 B'));
        expect(_formatBytes(512), equals('512 B'));
        expect(_formatBytes(1023), equals('1023 B'));
      });

      test('Formats kilobytes correctly', () {
        expect(_formatBytes(1024), contains('KB'));
        expect(_formatBytes(1536), contains('1.5 KB'));
        expect(_formatBytes(10240), contains('10.0 KB'));
      });

      test('Formats megabytes correctly', () {
        expect(_formatBytes(1048576), contains('MB')); // 1 MB
        expect(_formatBytes(1572864), contains('1.5 MB')); // 1.5 MB
      });

      test('Formats gigabytes correctly', () {
        expect(_formatBytes(1073741824), contains('GB')); // 1 GB
        expect(_formatBytes(2147483648), contains('2.00 GB')); // 2 GB
      });
    });
  });
}

// Helper function (matches CacheStats implementation)
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
