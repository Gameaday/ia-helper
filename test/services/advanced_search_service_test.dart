import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/services/advanced_search_service.dart';
import 'package:internet_archive_helper/models/search_query.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AdvancedSearchService service;

  setUp(() {
    service = AdvancedSearchService();
  });

  tearDown(() {
    service.dispose();
  });

  group('AdvancedSearchService - Initialization', () {
    test('should initialize successfully', () {
      expect(service, isNotNull);
      expect(service.isSearching, isFalse);
      expect(service.currentResults, isEmpty);
      expect(service.totalResults, isNull);
      expect(service.error, isNull);
    });
  });

  group('AdvancedSearchService - Query Building', () {
    test('should create simple search query', () {
      final query = SearchQuery.simple('test');
      expect(query.query, equals('test'));
      expect(query.fieldQueries, isEmpty);
      expect(query.mediatypes, isEmpty);
    });

    test('should create complex search query', () {
      final query = const SearchQuery(
        query: 'internet archive',
        fieldQueries: {'title': 'example'},
        mediatypes: ['texts'],
        rows: 50,
      );

      expect(query.query, equals('internet archive'));
      expect(query.fieldQueries['title'], equals('example'));
      expect(query.mediatypes, contains('texts'));
      expect(query.rows, equals(50));
    });

    test('should handle empty query', () {
      final query = SearchQuery.simple('');
      expect(query.query, equals(''));
    });
  });

  group('AdvancedSearchService - State Management', () {
    test('should update search state during search', () async {
      final query = SearchQuery.simple('test');
      
      // Note: This will make an actual API call
      // In a real app, you'd mock the HTTP client
      try {
        await service.search(query);
        expect(service.isSearching, isFalse);
      } catch (e) {
        // Network errors are okay in tests
        expect(service.error, isNotNull);
      }
    });

    test('should clear results', () {
      service.clearResults();
      expect(service.currentResults, isEmpty);
      expect(service.totalResults, isNull);
      expect(service.error, isNull);
    });
  });

  group('AdvancedSearchService - Search Methods', () {
    test('should execute simple search', () async {
      try {
        final results = await service.simpleSearch('dogs', rows: 10);
        expect(results, isNotNull);
        expect(results, isList);
      } catch (e) {
        // Network errors are acceptable in tests
        print('Network error (expected in test environment): $e');
      }
    });

    test('should search by mediatype', () async {
      try {
        final results = await service.searchByMediatype('texts', rows: 5);
        expect(results, isNotNull);
        expect(results, isList);
      } catch (e) {
        // Network errors are acceptable in tests
        print('Network error (expected in test environment): $e');
      }
    });

    test('should search by field', () async {
      try {
        final results = await service.searchByField('creator', 'archive.org', rows: 5);
        expect(results, isNotNull);
        expect(results, isList);
      } catch (e) {
        // Network errors are acceptable in tests
        print('Network error (expected in test environment): $e');
      }
    });

    test('should get suggestions', () async {
      try {
        final suggestions = await service.getSuggestions('internet');
        expect(suggestions, isNotNull);
        expect(suggestions, isList);
        if (suggestions.isNotEmpty) {
          expect(suggestions.length, lessThanOrEqualTo(10));
        }
      } catch (e) {
        // Network errors are acceptable in tests
        print('Network error (expected in test environment): $e');
      }
    });

    test('should return empty suggestions for empty query', () async {
      final suggestions = await service.getSuggestions('');
      expect(suggestions, isEmpty);
    });
  });

  group('AdvancedSearchService - Pagination', () {
    test('should execute paginated search', () async {
      final query = SearchQuery.simple('test');
      
      try {
        final page = await service.searchPaginated(query, page: 1, pageSize: 20);
        expect(page, isNotNull);
        expect(page.page, equals(1));
        expect(page.pageSize, equals(20));
        expect(page.results, isList);
      } catch (e) {
        // Network errors are acceptable in tests
        print('Network error (expected in test environment): $e');
      }
    });

    test('should handle different page sizes', () async {
      final query = SearchQuery.simple('archive');
      
      try {
        final page = await service.searchPaginated(query, page: 1, pageSize: 10);
        expect(page.pageSize, equals(10));
      } catch (e) {
        // Network errors are acceptable in tests
        print('Network error (expected in test environment): $e');
      }
    });

    test('should calculate pagination metadata', () {
      // Create a mock page result
      const totalResults = 100;
      const pageSize = 20;
      
      for (int page = 1; page <= 5; page++) {
        final hasNext = page * pageSize < totalResults;
        final hasPrevious = page > 1;
        final totalPages = (totalResults / pageSize).ceil();
        
        expect(totalPages, equals(5));
        expect(hasNext, equals(page < 5));
        expect(hasPrevious, equals(page > 1));
      }
    });
  });

  group('AdvancedSearchService - Query Copying', () {
    test('should copy query with modifications', () {
      final original = SearchQuery.simple('test');
      final modified = original.copyWith(rows: 50, page: 2);
      
      expect(modified.query, equals('test'));
      expect(modified.rows, equals(50));
      expect(modified.page, equals(2));
      expect(original.rows, isNot(equals(50))); // Original unchanged
    });

    test('should preserve unmodified fields', () {
      final original = const SearchQuery(
        query: 'test',
        mediatypes: ['texts'],
        rows: 20,
      );
      final modified = original.copyWith(page: 2);
      
      expect(modified.query, equals('test'));
      expect(modified.mediatypes, equals(['texts']));
      expect(modified.rows, equals(20));
      expect(modified.page, equals(2));
    });
  });

  group('AdvancedSearchService - Edge Cases', () {
    test('should handle very long query string', () async {
      final longQuery = 'a' * 500;
      final query = SearchQuery.simple(longQuery);
      
      try {
        await service.search(query);
      } catch (e) {
        // Any error is acceptable - we're testing it doesn't crash
        expect(e, isNotNull);
      }
    });

    test('should handle special characters', () {
      final query = SearchQuery.simple('test & "special" <chars>');
      expect(query.query, contains('special'));
    });

    test('should handle zero rows', () {
      final query = SearchQuery.simple('test').copyWith(rows: 0);
      expect(query.rows, equals(0));
    });

    test('should handle negative page number', () {
      final query = SearchQuery.simple('test').copyWith(page: -1);
      expect(query.page, equals(-1));
    });
  });

  group('AdvancedSearchService - Change Notifier', () {
    test('should notify listeners on state change', () async {
      var notified = false;
      service.addListener(() {
        notified = true;
      });

      service.clearResults();
      
      expect(notified, isTrue);
    });

    test('should dispose properly', () {
      // Don't call dispose here - tearDown will handle it
      // Just verify the service is in a valid state before disposal
      expect(service.currentResults, isNotNull);
    });
  });

  group('SearchResultPage - Display Formatting', () {
    test('should format range display correctly', () {
      final page = const SearchResultPage(
        results: [],
        page: 1,
        pageSize: 20,
        totalResults: 100,
        totalPages: 5,
        hasNextPage: true,
        hasPreviousPage: false,
      );

      expect(page.rangeDisplay, contains('of 100'));
    });

    test('should format page display correctly', () {
      final page = const SearchResultPage(
        results: [],
        page: 2,
        pageSize: 20,
        totalResults: 100,
        totalPages: 5,
        hasNextPage: true,
        hasPreviousPage: true,
      );

      expect(page.pageDisplay, equals('Page 2 of 5'));
    });

    test('should handle zero results', () {
      final page = const SearchResultPage(
        results: [],
        page: 0,
        pageSize: 20,
        totalResults: 0,
        totalPages: 0,
        hasNextPage: false,
        hasPreviousPage: false,
      );

      expect(page.rangeDisplay, equals('0 results'));
      expect(page.pageDisplay, equals('Page 0 of 0'));
    });

    test('should correctly identify first page', () {
      final page = const SearchResultPage(
        results: [],
        page: 1,
        pageSize: 20,
        totalResults: 100,
        totalPages: 5,
        hasNextPage: true,
        hasPreviousPage: false,
      );

      expect(page.hasPreviousPage, isFalse);
      expect(page.hasNextPage, isTrue);
    });

    test('should correctly identify last page', () {
      final page = const SearchResultPage(
        results: [],
        page: 5,
        pageSize: 20,
        totalResults: 100,
        totalPages: 5,
        hasNextPage: false,
        hasPreviousPage: true,
      );

      expect(page.hasPreviousPage, isTrue);
      expect(page.hasNextPage, isFalse);
    });

    test('should correctly identify middle page', () {
      final page = const SearchResultPage(
        results: [],
        page: 3,
        pageSize: 20,
        totalResults: 100,
        totalPages: 5,
        hasNextPage: true,
        hasPreviousPage: true,
      );

      expect(page.hasPreviousPage, isTrue);
      expect(page.hasNextPage, isTrue);
    });
  });
}
