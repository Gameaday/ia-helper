import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:internet_archive_helper/models/search_query.dart';
import 'package:internet_archive_helper/models/search_result.dart';
import 'package:internet_archive_helper/services/advanced_search_service.dart';
import 'package:internet_archive_helper/services/archive_service.dart';
import 'package:internet_archive_helper/utils/animation_constants.dart';
import 'package:internet_archive_helper/widgets/archive_result_card.dart';
import 'package:internet_archive_helper/widgets/skeleton_loader.dart';
import 'package:internet_archive_helper/screens/api_intensity_settings_screen.dart';
import 'archive_detail_screen.dart';

/// Material Design 3 compliant search results display screen
///
/// Features:
/// - Paginated search results from AdvancedSearchService
/// - Grid/list view toggle
/// - Responsive grid layout (2-5 columns)
/// - Pull-to-refresh to re-execute search
/// - Infinite scroll for pagination
/// - Archive preview cards with thumbnails
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
  bool _showThumbnails = true;
  ArchiveResultCardLayout _viewLayout = ArchiveResultCardLayout.grid;

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadApiSettings();
    _executeSearch();
  }

  /// Load API intensity settings
  Future<void> _loadApiSettings() async {
    final settings = await ApiIntensitySettingsScreen.getSettings();
    if (mounted) {
      setState(() {
        _showThumbnails = settings.loadThumbnails;
      });
    }
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
        // View toggle button
        IconButton(
          icon: Icon(
            _viewLayout == ArchiveResultCardLayout.grid
                ? Icons.view_list
                : Icons.grid_view,
          ),
          onPressed: () {
            setState(() {
              _viewLayout = _viewLayout == ArchiveResultCardLayout.grid
                  ? ArchiveResultCardLayout.list
                  : ArchiveResultCardLayout.grid;
            });
          },
          tooltip: _viewLayout == ArchiveResultCardLayout.grid
              ? 'Switch to list view'
              : 'Switch to grid view',
        ),
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

    // Smooth transition between grid and list views
    return RefreshIndicator(
      onRefresh: _refresh,
      child: AnimatedSwitcher(
        duration: MD3Durations.medium,
        switchInCurve: MD3Curves.emphasized,
        switchOutCurve: MD3Curves.emphasized,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_viewLayout),
          child: _viewLayout == ArchiveResultCardLayout.grid
              ? _buildGridView()
              : _buildListView(),
        ),
      ),
    );
  }

  /// Build grid view with responsive columns
  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive column count based on width
        final crossAxisCount = _getColumnCount(constraints.maxWidth);

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.7, // Cards are taller than wide
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _results.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _results.length) {
              return _buildLoadingMoreIndicator();
            }

            final result = _results[index];
            return ArchiveResultCard(
              result: result,
              layout: ArchiveResultCardLayout.grid,
              showThumbnail: _showThumbnails,
              onTap: () => _navigateToDetail(result),
            );
          },
        );
      },
    );
  }

  /// Build list view
  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _results.length) {
          return _buildLoadingMoreIndicator();
        }

        final result = _results[index];
        return ArchiveResultCard(
          result: result,
          layout: ArchiveResultCardLayout.list,
          showThumbnail: _showThumbnails,
          onTap: () => _navigateToDetail(result),
        );
      },
    );
  }

  /// Get responsive column count based on screen width
  int _getColumnCount(double width) {
    if (width < 600) {
      return 2; // Phone portrait
    } else if (width < 900) {
      return 3; // Phone landscape / small tablet
    } else if (width < 1200) {
      return 4; // Tablet
    } else {
      return 5; // Desktop / large tablet
    }
  }

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isPhone = width < 600;
        final crossAxisCount = isPhone ? 2 : (width < 900 ? 3 : 4);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Loading indicator with message
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Searching Internet Archive...'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Skeleton loaders
              SkeletonGrid(
                itemCount: 6,
                crossAxisCount: crossAxisCount,
              ),
            ],
          ),
        );
      },
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
