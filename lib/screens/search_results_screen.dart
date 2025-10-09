import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:internet_archive_helper/models/search_query.dart';
import 'package:internet_archive_helper/models/search_result.dart';
import 'package:internet_archive_helper/services/advanced_search_service.dart';
import 'package:internet_archive_helper/services/archive_service.dart';
import 'package:internet_archive_helper/utils/animation_constants.dart';
import 'archive_detail_screen.dart';

/// Material Design 3 compliant search results display screen
///
/// Features:
/// - Paginated search results from AdvancedSearchService
/// - Pull-to-refresh to re-execute search
/// - Infinite scroll for pagination
/// - Archive preview cards with metadata
/// - Navigate to ArchiveDetailScreen
/// - Error handling and retry
/// - Empty state messaging
/// - Loading states
/// - MD3 animations and transitions
class SearchResultsScreen extends StatefulWidget {
  static const String routeName = '/search-results';

  final SearchQuery query;
  final String? title;

  const SearchResultsScreen({required this.query, this.title, super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final _scrollController = ScrollController();
  final _advancedSearchService = AdvancedSearchService();

  List<SearchResult> _results = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  int? _totalResults;
  bool _hasMore = true;

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _executeSearch();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _advancedSearchService.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _executeSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _results = [];
      _hasMore = true;
    });

    try {
      final page = await _advancedSearchService.searchPaginated(
        widget.query,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          _results = page.results;
          _totalResults = page.totalResults;
          _hasMore = page.hasNextPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final page = await _advancedSearchService.searchPaginated(
        widget.query,
        page: _currentPage + 1,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          _currentPage++;
          _results.addAll(page.results);
          _hasMore = page.hasNextPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        _showSnackBar('Error loading more results: $e');
      }
    }
  }

  Future<void> _refresh() async {
    await _executeSearch();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.title ?? 'Search Results'),
      actions: [
        if (_totalResults != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '$_totalResults results',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_results.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _results.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _results.length) {
            return _buildLoadingMoreIndicator();
          }

          final result = _results[index];
          return _buildResultCard(result);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Searching Internet Archive...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('Search Error', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _executeSearch,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search query or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildResultCard(SearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToDetail(result),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (result.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  result.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      result.identifier,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToDetail(SearchResult result) async {
    // Load metadata into ArchiveService
    final archiveService = context.read<ArchiveService>();

    try {
      await archiveService.fetchMetadata(result.identifier);

      if (!mounted) return;

      // Navigate to detail screen with MD3 fadeThrough transition
      await Navigator.push(
        context,
        MD3PageTransitions.fadeThrough(
          page: const ArchiveDetailScreen(),
          settings: const RouteSettings(name: '/archive-detail'),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading archive: $e');
      }
    }
  }
}
