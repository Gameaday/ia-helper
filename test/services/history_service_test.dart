import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_archive_helper/services/history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryEntry', () {
    test('should serialize to/from JSON correctly', () {
      final entry = HistoryEntry(
        identifier: 'test-archive',
        title: 'Test Archive',
        description: 'A test description',
        creator: 'Test Creator',
        totalFiles: 100,
        totalSize: 1024000,
        visitedAt: DateTime(2025, 10, 6, 12, 0),
      );

      final json = entry.toJson();
      expect(json['identifier'], 'test-archive');
      expect(json['title'], 'Test Archive');
      expect(json['description'], 'A test description');
      expect(json['creator'], 'Test Creator');
      expect(json['totalFiles'], 100);
      expect(json['totalSize'], 1024000);
      expect(json['visitedAt'], '2025-10-06T12:00:00.000');

      final decoded = HistoryEntry.fromJson(json);
      expect(decoded.identifier, entry.identifier);
      expect(decoded.title, entry.title);
      expect(decoded.description, entry.description);
      expect(decoded.creator, entry.creator);
      expect(decoded.totalFiles, entry.totalFiles);
      expect(decoded.totalSize, entry.totalSize);
      expect(decoded.visitedAt, entry.visitedAt);
    });

    test('should handle null fields correctly', () {
      final entry = HistoryEntry(
        identifier: 'test-archive',
        title: 'Test Archive',
        totalFiles: 50,
        totalSize: 512000,
        visitedAt: DateTime.now(),
      );

      final json = entry.toJson();
      expect(json['description'], null);
      expect(json['creator'], null);

      final decoded = HistoryEntry.fromJson(json);
      expect(decoded.description, null);
      expect(decoded.creator, null);
    });

    test('should format relative time correctly', () {
      final now = DateTime.now();
      
      // Just now
      var entry = HistoryEntry(
        identifier: 'test',
        title: 'Test',
        totalFiles: 1,
        totalSize: 100,
        visitedAt: now.subtract(const Duration(seconds: 30)),
      );
      expect(entry.relativeTime, 'Just now');

      // Minutes ago
      entry = HistoryEntry(
        identifier: 'test',
        title: 'Test',
        totalFiles: 1,
        totalSize: 100,
        visitedAt: now.subtract(const Duration(minutes: 5)),
      );
      expect(entry.relativeTime, '5m ago');

      // Hours ago
      entry = HistoryEntry(
        identifier: 'test',
        title: 'Test',
        totalFiles: 1,
        totalSize: 100,
        visitedAt: now.subtract(const Duration(hours: 3)),
      );
      expect(entry.relativeTime, '3h ago');

      // Days ago
      entry = HistoryEntry(
        identifier: 'test',
        title: 'Test',
        totalFiles: 1,
        totalSize: 100,
        visitedAt: now.subtract(const Duration(days: 2)),
      );
      expect(entry.relativeTime, '2d ago');

      // Weeks ago
      entry = HistoryEntry(
        identifier: 'test',
        title: 'Test',
        totalFiles: 1,
        totalSize: 100,
        visitedAt: now.subtract(const Duration(days: 10)),
      );
      expect(entry.relativeTime, '1w ago');

      // Months ago
      entry = HistoryEntry(
        identifier: 'test',
        title: 'Test',
        totalFiles: 1,
        totalSize: 100,
        visitedAt: now.subtract(const Duration(days: 45)),
      );
      expect(entry.relativeTime, '1mo ago');

      // Years ago
      entry = HistoryEntry(
        identifier: 'test',
        title: 'Test',
        totalFiles: 1,
        totalSize: 100,
        visitedAt: now.subtract(const Duration(days: 400)),
      );
      expect(entry.relativeTime, '1y ago');
    });

    test('should implement equality correctly', () {
      final entry1 = HistoryEntry(
        identifier: 'test-archive',
        title: 'Test Archive',
        totalFiles: 100,
        totalSize: 1024000,
        visitedAt: DateTime.now(),
      );

      final entry2 = HistoryEntry(
        identifier: 'test-archive',
        title: 'Different Title',
        totalFiles: 50,
        totalSize: 512000,
        visitedAt: DateTime.now(),
      );

      final entry3 = HistoryEntry(
        identifier: 'different-archive',
        title: 'Test Archive',
        totalFiles: 100,
        totalSize: 1024000,
        visitedAt: DateTime.now(),
      );

      expect(entry1, equals(entry2)); // Same identifier
      expect(entry1, isNot(equals(entry3))); // Different identifier
      expect(entry1.hashCode, equals(entry2.hashCode));
    });
  });

  group('HistoryService', () {
    late HistoryService service;

    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
      service = HistoryService();
      await service.loadHistory();
    });

    test('should start with empty history', () {
      expect(service.history, isEmpty);
      expect(service.isLoaded, true);
    });

    test('should add entry to history', () {
      final entry = HistoryEntry(
        identifier: 'test-archive',
        title: 'Test Archive',
        totalFiles: 100,
        totalSize: 1024000,
        visitedAt: DateTime.now(),
      );

      service.addToHistory(entry);

      expect(service.history.length, 1);
      expect(service.history.first, entry);
    });

    test('should add most recent entry first', () {
      final entry1 = HistoryEntry(
        identifier: 'archive-1',
        title: 'Archive 1',
        totalFiles: 100,
        totalSize: 1024000,
        visitedAt: DateTime.now(),
      );

      final entry2 = HistoryEntry(
        identifier: 'archive-2',
        title: 'Archive 2',
        totalFiles: 50,
        totalSize: 512000,
        visitedAt: DateTime.now(),
      );

      service.addToHistory(entry1);
      service.addToHistory(entry2);

      expect(service.history.length, 2);
      expect(service.history.first, entry2); // Most recent first
      expect(service.history.last, entry1);
    });

    test('should update existing entry', () {
      final entry1 = HistoryEntry(
        identifier: 'test-archive',
        title: 'Test Archive',
        totalFiles: 100,
        totalSize: 1024000,
        visitedAt: DateTime.now(),
      );

      service.addToHistory(entry1);
      expect(service.history.length, 1);

      // Add same identifier with different data
      final entry2 = HistoryEntry(
        identifier: 'test-archive',
        title: 'Updated Archive',
        totalFiles: 150,
        totalSize: 2048000,
        visitedAt: DateTime.now(),
      );

      service.addToHistory(entry2);

      expect(service.history.length, 1); // Still only one entry
      expect(service.history.first.title, 'Updated Archive');
      expect(service.history.first.totalFiles, 150);
    });

    test('should limit history to max size', () {
      // Add more than max history size (100)
      for (int i = 0; i < 150; i++) {
        service.addToHistory(
          HistoryEntry(
            identifier: 'archive-$i',
            title: 'Archive $i',
            totalFiles: 10,
            totalSize: 1000,
            visitedAt: DateTime.now(),
          ),
        );
      }

      expect(service.history.length, 100); // Should be limited to 100
      expect(service.history.first.identifier, 'archive-149'); // Most recent
      expect(service.history.last.identifier, 'archive-50'); // Oldest kept
    });

    test('should remove entry from history', () {
      final entry1 = HistoryEntry(
        identifier: 'archive-1',
        title: 'Archive 1',
        totalFiles: 100,
        totalSize: 1024000,
        visitedAt: DateTime.now(),
      );

      final entry2 = HistoryEntry(
        identifier: 'archive-2',
        title: 'Archive 2',
        totalFiles: 50,
        totalSize: 512000,
        visitedAt: DateTime.now(),
      );

      service.addToHistory(entry1);
      service.addToHistory(entry2);
      expect(service.history.length, 2);

      service.removeFromHistory('archive-1');
      expect(service.history.length, 1);
      expect(service.history.first.identifier, 'archive-2');
    });

    test('should clear all history', () {
      for (int i = 0; i < 5; i++) {
        service.addToHistory(
          HistoryEntry(
            identifier: 'archive-$i',
            title: 'Archive $i',
            totalFiles: 10,
            totalSize: 1000,
            visitedAt: DateTime.now(),
          ),
        );
      }

      expect(service.history.length, 5);

      service.clearHistory();
      expect(service.history, isEmpty);
    });

    test('should persist history to storage', () async {
      final entry = HistoryEntry(
        identifier: 'test-archive',
        title: 'Test Archive',
        description: 'Test description',
        creator: 'Test Creator',
        totalFiles: 100,
        totalSize: 1024000,
        visitedAt: DateTime(2025, 10, 6, 12, 0),
      );

      service.addToHistory(entry);

      // Wait for async save to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Create new service and load
      final newService = HistoryService();
      await newService.loadHistory();

      expect(newService.history.length, 1);
      expect(newService.history.first.identifier, 'test-archive');
      expect(newService.history.first.title, 'Test Archive');
      expect(newService.history.first.description, 'Test description');
      expect(newService.history.first.creator, 'Test Creator');
      expect(newService.history.first.totalFiles, 100);
      expect(newService.history.first.totalSize, 1024000);
    });

    test('should handle multiple entries in storage', () async {
      for (int i = 0; i < 5; i++) {
        service.addToHistory(
          HistoryEntry(
            identifier: 'archive-$i',
            title: 'Archive $i',
            totalFiles: i * 10,
            totalSize: i * 1000,
            visitedAt: DateTime.now(),
          ),
        );
      }

      // Wait for async save to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Create new service and load
      final newService = HistoryService();
      await newService.loadHistory();

      expect(newService.history.length, 5);
      expect(newService.history.first.identifier, 'archive-4'); // Most recent
      expect(newService.history.last.identifier, 'archive-0'); // Oldest
    });

    test('should not reload history if already loaded', () async {
      final entry = HistoryEntry(
        identifier: 'test-archive',
        title: 'Test Archive',
        totalFiles: 100,
        totalSize: 1024000,
        visitedAt: DateTime.now(),
      );

      service.addToHistory(entry);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(service.isLoaded, true);
      expect(service.history.length, 1);

      // Try to load again
      await service.loadHistory();
      
      // Should still have same data (not cleared/reloaded)
      expect(service.history.length, 1);
    });

    test('should handle empty storage gracefully', () async {
      final newService = HistoryService();
      await newService.loadHistory();

      expect(newService.history, isEmpty);
      expect(newService.isLoaded, true);
    });

    test('should persist after removal', () async {
      final entry1 = HistoryEntry(
        identifier: 'archive-1',
        title: 'Archive 1',
        totalFiles: 100,
        totalSize: 1024000,
        visitedAt: DateTime.now(),
      );

      final entry2 = HistoryEntry(
        identifier: 'archive-2',
        title: 'Archive 2',
        totalFiles: 50,
        totalSize: 512000,
        visitedAt: DateTime.now(),
      );

      service.addToHistory(entry1);
      service.addToHistory(entry2);
      await Future.delayed(const Duration(milliseconds: 100));

      service.removeFromHistory('archive-1');
      await Future.delayed(const Duration(milliseconds: 100));

      // Create new service and load
      final newService = HistoryService();
      await newService.loadHistory();

      expect(newService.history.length, 1);
      expect(newService.history.first.identifier, 'archive-2');
    });

    test('should persist after clear', () async {
      for (int i = 0; i < 5; i++) {
        service.addToHistory(
          HistoryEntry(
            identifier: 'archive-$i',
            title: 'Archive $i',
            totalFiles: 10,
            totalSize: 1000,
            visitedAt: DateTime.now(),
          ),
        );
      }
      await Future.delayed(const Duration(milliseconds: 100));

      service.clearHistory();
      await Future.delayed(const Duration(milliseconds: 100));

      // Create new service and load
      final newService = HistoryService();
      await newService.loadHistory();

      expect(newService.history, isEmpty);
    });

    test('should notify listeners on changes', () {
      int notificationCount = 0;
      service.addListener(() {
        notificationCount++;
      });

      final entry = HistoryEntry(
        identifier: 'test-archive',
        title: 'Test Archive',
        totalFiles: 100,
        totalSize: 1024000,
        visitedAt: DateTime.now(),
      );

      service.addToHistory(entry);
      expect(notificationCount, 1);

      service.removeFromHistory('test-archive');
      expect(notificationCount, 2);

      service.clearHistory();
      expect(notificationCount, 3);
    });
  });
}
