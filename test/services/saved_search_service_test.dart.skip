import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/services/saved_search_service.dart';
import 'package:internet_archive_helper/models/saved_search.dart';
import 'package:internet_archive_helper/models/search_query.dart';
import 'package:internet_archive_helper/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SavedSearchService service;
  late DatabaseHelper dbHelper;

  setUp(() async {
    // Create test instance
    dbHelper = DatabaseHelper.instance;
    service = SavedSearchService.test(dbHelper);
    
    // Clear any existing data
    final searches = await service.getAllSavedSearches();
    for (final search in searches) {
      if (search.id != null) {
        await service.deleteSavedSearch(search.id!);
      }
    }
  });

  tearDown(() async {
    // Clean up after each test
    final searches = await service.getAllSavedSearches();
    for (final search in searches) {
      if (search.id != null) {
        await service.deleteSavedSearch(search.id!);
      }
    }
  });

  group('SavedSearchService - Basic Operations', () {
    test('should initialize successfully', () {
      expect(service, isNotNull);
    });

    test('should start with empty saved searches', () async {
      final searches = await service.getAllSavedSearches();
      expect(searches, isEmpty);
    });

    test('should create new saved search', () async {
      final query = SearchQuery.simple('test query');
      final search = SavedSearch(
        name: 'Test Search',
        query: query,
        createdAt: DateTime.now(),
      );

      final created = await service.createSavedSearch(search);
      
      expect(created.id, isNotNull);
      expect(created.name, equals('Test Search'));
      expect(created.query.query, equals('test query'));
    });

    test('should prevent duplicate names', () async {
      final query1 = SearchQuery.simple('query 1');
      final search1 = SavedSearch(
        name: 'Duplicate Name',
        query: query1,
        createdAt: DateTime.now(),
      );
      await service.createSavedSearch(search1);

      final query2 = SearchQuery.simple('query 2');
      final search2 = SavedSearch(
        name: 'Duplicate Name',
        query: query2,
        createdAt: DateTime.now(),
      );

      expect(
        () => service.createSavedSearch(search2),
        throwsException,
      );
    });

    test('should get saved search by ID', () async {
      final query = SearchQuery.simple('test');
      final search = SavedSearch(
        name: 'Find Me',
        query: query,
        createdAt: DateTime.now(),
      );
      final created = await service.createSavedSearch(search);

      final found = await service.getSavedSearch(created.id!);
      
      expect(found, isNotNull);
      expect(found!.name, equals('Find Me'));
    });

    test('should get saved search by name', () async {
      final query = SearchQuery.simple('test');
      final search = SavedSearch(
        name: 'Unique Search Name',
        query: query,
        createdAt: DateTime.now(),
      );
      await service.createSavedSearch(search);

      final found = await service.getSavedSearchByName('Unique Search Name');
      
      expect(found, isNotNull);
      expect(found!.query.query, equals('test'));
    });

    test('should update saved search', () async {
      final query = SearchQuery.simple('original');
      final search = SavedSearch(
        name: 'Update Me',
        query: query,
        createdAt: DateTime.now(),
      );
      final created = await service.createSavedSearch(search);

      final updatedQuery = SearchQuery.simple('updated');
      final updated = created.copyWith(query: updatedQuery);
      await service.updateSavedSearch(updated);

      final found = await service.getSavedSearch(created.id!);
      expect(found!.query.query, equals('updated'));
    });

    test('should delete saved search', () async {
      final query = SearchQuery.simple('delete me');
      final search = SavedSearch(
        name: 'To Delete',
        query: query,
        createdAt: DateTime.now(),
      );
      final created = await service.createSavedSearch(search);

      await service.deleteSavedSearch(created.id!);

      final found = await service.getSavedSearch(created.id!);
      expect(found, isNull);
    });
  });

  group('SavedSearchService - Pinning', () {
    test('should get pinned searches', () async {
      await service.createSavedSearch(SavedSearch(
        name: 'Pinned 1',
        query: SearchQuery.simple('test1'),
        createdAt: DateTime.now(),
        isPinned: true,
      ));

      await service.createSavedSearch(SavedSearch(
        name: 'Not Pinned',
        query: SearchQuery.simple('test2'),
        createdAt: DateTime.now(),
        isPinned: false,
      ));

      final pinnedSearches = await service.getPinnedSearches();
      
      expect(pinnedSearches.length, equals(1));
      expect(pinnedSearches.first.name, equals('Pinned 1'));
    });

    test('should toggle pin status', () async {
      final search = await service.createSavedSearch(SavedSearch(
        name: 'Toggle Pin',
        query: SearchQuery.simple('test'),
        createdAt: DateTime.now(),
        isPinned: false,
      ));

      final toggled = search.copyWith(isPinned: !search.isPinned);
      await service.updateSavedSearch(toggled);

      final found = await service.getSavedSearch(search.id!);
      expect(found!.isPinned, isTrue);
    });
  });

  group('SavedSearchService - Tags', () {
    test('should get searches by tag', () async {
      await service.createSavedSearch(SavedSearch(
        name: 'Tagged 1',
        query: SearchQuery.simple('test1'),
        createdAt: DateTime.now(),
        tags: ['work', 'important'],
      ));

      await service.createSavedSearch(SavedSearch(
        name: 'Tagged 2',
        query: SearchQuery.simple('test2'),
        createdAt: DateTime.now(),
        tags: ['work', 'personal'],
      ));

      await service.createSavedSearch(SavedSearch(
        name: 'Tagged 3',
        query: SearchQuery.simple('test3'),
        createdAt: DateTime.now(),
        tags: ['personal'],
      ));

      final workSearches = await service.getSearchesByTag('work');
      expect(workSearches.length, equals(2));
    });

    test('should get all unique tags', () async {
      await service.createSavedSearch(SavedSearch(
        name: 'Search 1',
        query: SearchQuery.simple('test1'),
        createdAt: DateTime.now(),
        tags: ['tag1', 'tag2'],
      ));

      await service.createSavedSearch(SavedSearch(
        name: 'Search 2',
        query: SearchQuery.simple('test2'),
        createdAt: DateTime.now(),
        tags: ['tag2', 'tag3'],
      ));

      final allTags = await service.getAllTags();
      
      expect(allTags.length, equals(3));
      expect(allTags, containsAll(['tag1', 'tag2', 'tag3']));
      // Check if sorted
      expect(allTags, equals(['tag1', 'tag2', 'tag3']));
    });

    test('should add and remove tags', () async {
      final search = await service.createSavedSearch(SavedSearch(
        name: 'Tag Test',
        query: SearchQuery.simple('test'),
        createdAt: DateTime.now(),
        tags: ['initial'],
      ));

      final withTag = search.copyWith(tags: [...search.tags, 'new']);
      await service.updateSavedSearch(withTag);

      var found = await service.getSavedSearch(search.id!);
      expect(found!.tags, containsAll(['initial', 'new']));

      final withoutTag = found.copyWith(tags: found.tags.where((t) => t != 'initial').toList());
      await service.updateSavedSearch(withoutTag);

      found = await service.getSavedSearch(search.id!);
      expect(found!.tags, equals(['new']));
    });
  });

  group('SavedSearchService - Usage Tracking', () {
    test('should mark search as used', () async {
      final search = await service.createSavedSearch(SavedSearch(
        name: 'Track Usage',
        query: SearchQuery.simple('test'),
        createdAt: DateTime.now(),
      ));

      expect(search.useCount, equals(0));
      expect(search.lastUsedAt, isNull);

      await service.markSearchUsed(search.id!);

      final updated = await service.getSavedSearch(search.id!);
      expect(updated!.useCount, equals(1));
      expect(updated.lastUsedAt, isNotNull);
    });

    test('should increment use count on multiple uses', () async {
      final search = await service.createSavedSearch(SavedSearch(
        name: 'Multi Use',
        query: SearchQuery.simple('test'),
        createdAt: DateTime.now(),
      ));

      await service.markSearchUsed(search.id!);
      await service.markSearchUsed(search.id!);
      await service.markSearchUsed(search.id!);

      final updated = await service.getSavedSearch(search.id!);
      expect(updated!.useCount, equals(3));
    });
  });

  group('SavedSearchService - Sorting', () {
    test('should return pinned searches first', () async {
      await service.createSavedSearch(SavedSearch(
        name: 'Unpinned',
        query: SearchQuery.simple('test1'),
        createdAt: DateTime.now(),
        isPinned: false,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      await service.createSavedSearch(SavedSearch(
        name: 'Pinned',
        query: SearchQuery.simple('test2'),
        createdAt: DateTime.now(),
        isPinned: true,
      ));

      final all = await service.getAllSavedSearches();
      
      expect(all.first.name, equals('Pinned'));
      expect(all.last.name, equals('Unpinned'));
    });
  });

  group('SavedSearchService - Edge Cases', () {
    test('should handle empty name', () async {
      final search = SavedSearch(
        name: '',
        query: SearchQuery.simple('test'),
        createdAt: DateTime.now(),
      );

      final created = await service.createSavedSearch(search);
      expect(created.name, equals(''));
    });

    test('should handle long name', () async {
      final longName = 'a' * 200;
      final search = SavedSearch(
        name: longName,
        query: SearchQuery.simple('test'),
        createdAt: DateTime.now(),
      );

      final created = await service.createSavedSearch(search);
      expect(created.name.length, equals(200));
    });

    test('should handle complex query', () async {
      final complexQuery = SearchQuery(
        query: 'test',
        fieldQueries: {'title': 'example', 'creator': 'author'},
        mediatypes: ['texts', 'movies'],
      );

      final search = SavedSearch(
        name: 'Complex',
        query: complexQuery,
        createdAt: DateTime.now(),
      );

      final created = await service.createSavedSearch(search);
      final found = await service.getSavedSearch(created.id!);
      
      expect(found!.query.query, equals('test'));
      expect(found.query.fieldQueries, equals({'title': 'example', 'creator': 'author'}));
      expect(found.query.mediatypes, equals(['texts', 'movies']));
    });

    test('should handle empty tags list', () async {
      final search = SavedSearch(
        name: 'No Tags',
        query: SearchQuery.simple('test'),
        createdAt: DateTime.now(),
        tags: [],
      );

      final created = await service.createSavedSearch(search);
      expect(created.tags, isEmpty);
    });

    test('should handle special characters in name', () async {
      final search = SavedSearch(
        name: 'Test & <Search>: "Special"',
        query: SearchQuery.simple('test'),
        createdAt: DateTime.now(),
      );

      final created = await service.createSavedSearch(search);
      expect(created.name, contains('Special'));
    });
  });

  group('SavedSearchService - ChangeNotifier', () {
    test('should notify listeners on create', () async {
      var notified = false;
      service.addListener(() {
        notified = true;
      });

      await service.createSavedSearch(SavedSearch(
        name: 'Test',
        query: SearchQuery.simple('test'),
        createdAt: DateTime.now(),
      ));

      expect(notified, isTrue);
    });

    test('should notify listeners on update', () async {
      final search = await service.createSavedSearch(SavedSearch(
        name: 'Test',
        query: SearchQuery.simple('test'),
        createdAt: DateTime.now(),
      ));

      var notified = false;
      service.addListener(() {
        notified = true;
      });

      await service.updateSavedSearch(search.copyWith(name: 'Updated'));

      expect(notified, isTrue);
    });

    test('should notify listeners on delete', () async {
      final search = await service.createSavedSearch(SavedSearch(
        name: 'Test',
        query: SearchQuery.simple('test'),
        createdAt: DateTime.now(),
      ));

      var notified = false;
      service.addListener(() {
        notified = true;
      });

      await service.deleteSavedSearch(search.id!);

      expect(notified, isTrue);
    });
  });
}
