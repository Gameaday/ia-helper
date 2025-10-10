import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:internet_archive_helper/models/search_query.dart';
import 'package:internet_archive_helper/models/search_result.dart';
import 'package:internet_archive_helper/services/advanced_search_service.dart';
import 'package:internet_archive_helper/services/archive_service.dart';
import 'package:internet_archive_helper/utils/animation_constants.dart';
import 'package:internet_archive_helper/utils/snackbar_helper.dart';
import 'package:internet_archive_helper/utils/responsive_utils.dart';
import 'package:internet_archive_helper/widgets/archive_result_card.dart';
import 'package:internet_archive_helper/widgets/download_controls_widget.dart';
import 'package:internet_archive_helper/widgets/empty_state_widget.dart';
import 'package:internet_archive_helper/widgets/error_card.dart';
import 'package:internet_archive_helper/widgets/skeleton_loader.dart';
import 'package:internet_archive_helper/widgets/archive_info_widget.dart';
import 'package:internet_archive_helper/widgets/file_list_widget.dart';
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
  
  // Master-detail state
  SearchResult? _selectedResult;
  bool _isLoadingDetail = false;

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
        SnackBarHelper.showError(context, e);
      }
    }
  }

  Future<void> _refresh() async {
    await _executeSearch();
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

    // Use master-detail layout on tablets
    final isTablet = ResponsiveUtils.isTabletOrLarger(context);
    
    if (isTablet) {
      return _buildMasterDetailLayout();
    }

    // Phone: Standard list/grid view
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

  /// Build master-detail layout for tablets
  Widget _buildMasterDetailLayout() {
    return Row(
      children: [
        // Master panel: Results list (40% width)
        Expanded(
          flex: 40,
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: _buildResultsList(),
          ),
        ),

        // Vertical divider
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),

        // Detail panel: Archive preview (60% width)
        Expanded(
          flex: 60,
          child: _buildDetailPanel(),
        ),
      ],
    );
  }

  /// Build results list for master panel
  Widget _buildResultsList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length + (_isLoadingMore ? 1 : (!_hasMore ? 1 : 0)),
      itemBuilder: (context, index) {
        if (index >= _results.length) {
          if (_isLoadingMore) {
            return _buildLoadingMoreIndicator();
          }
          if (!_hasMore) {
            return _buildEndOfListIndicator();
          }
        }

        final result = _results[index];
        final isSelected = _selectedResult?.identifier == result.identifier;

        return Container(
          color: isSelected
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : null,
          child: ArchiveResultCard(
            result: result,
            layout: ArchiveResultCardLayout.list,
            showThumbnail: _showThumbnails,
            onTap: () => _selectResult(result),
          ),
        );
      },
    );
  }

  /// Build detail panel showing selected archive
  Widget _buildDetailPanel() {
    if (_selectedResult == null) {
      return _buildDetailEmptyState();
    }

    return Consumer<ArchiveService>(
      builder: (context, service, child) {
        // Show loading while fetching metadata
        if (_isLoadingDetail) {
          return _buildDetailLoadingState();
        }

        // Show error if metadata failed to load
        if (service.error != null) {
          return _buildDetailErrorState(service.error!);
        }

        // Show detail content if metadata loaded
        if (service.currentMetadata != null) {
          return _buildDetailContent(service);
        }

        // Empty state (shouldn't normally reach here)
        return _buildDetailEmptyState();
      },
    );
  }

  /// Detail panel empty state (no selection)
  Widget _buildDetailEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Select an archive to preview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Detail panel loading state
  Widget _buildDetailLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading archive details...'),
        ],
      ),
    );
  }

  /// Detail panel error state
  Widget _buildDetailErrorState(String error) {
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
            Text(
              'Failed to load archive',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                if (_selectedResult != null) {
                  _selectResult(_selectedResult!);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Detail panel content (archive info + files)
  Widget _buildDetailContent(ArchiveService service) {
    final metadata = service.currentMetadata!;
    
    return Column(
      children: [
        // Header with open button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  metadata.title ?? 'Untitled Archive',
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _openFullDetail(),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open'),
              ),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArchiveInfoWidget(metadata: metadata),
                const SizedBox(height: 16),
                Text(
                  'Files',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FileListWidget(files: service.filteredFiles),
                const SizedBox(height: 16),
                const DownloadControlsWidget(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Select a result and load its metadata
  Future<void> _selectResult(SearchResult result) async {
    if (_selectedResult?.identifier == result.identifier) {
      return; // Already selected
    }

    setState(() {
      _selectedResult = result;
      _isLoadingDetail = true;
    });

    final archiveService = context.read<ArchiveService>();
    
    try {
      await archiveService.fetchMetadata(result.identifier);
      
      if (mounted) {
        setState(() {
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDetail = false;
        });
        // Error will be shown by the Consumer in _buildDetailPanel
      }
    }
  }

  /// Open full detail screen (from tablet preview)
  Future<void> _openFullDetail() async {
    await Navigator.push(
      context,
      MD3PageTransitions.fadeThrough(
        page: const ArchiveDetailScreen(),
        settings: const RouteSettings(name: '/archive-detail'),
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
          itemCount: _results.length + (_isLoadingMore ? 1 : (!_hasMore ? 1 : 0)),
          itemBuilder: (context, index) {
            if (index >= _results.length) {
              if (_isLoadingMore) {
                return _buildLoadingMoreIndicator();
              }
              if (!_hasMore) {
                // Span all columns for end-of-list indicator
                return GridView.count(
                  crossAxisCount: 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_buildEndOfListIndicator()],
                );
              }
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
      itemCount: _results.length + (_isLoadingMore ? 1 : (!_hasMore ? 1 : 0)),
      itemBuilder: (context, index) {
        if (index >= _results.length) {
          if (_isLoadingMore) {
            return _buildLoadingMoreIndicator();
          }
          if (!_hasMore) {
            return _buildEndOfListIndicator();
          }
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
    return Semantics(
      label: 'Loading search results',
      liveRegion: true,
      child: LayoutBuilder(
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
      ),
    );
  }
  Widget _buildErrorState() {
    return ErrorCard(
      error: _error ?? 'An unknown error occurred',
      onRetry: _executeSearch,
      onSecondaryAction: () => Navigator.pop(context),
      secondaryActionLabel: 'Back to Search',
    );
  }

  Widget _buildEmptyState() {
    return Semantics(
      label: 'No search results found. Try adjusting your search query or filters. Tap back to search button to return.',
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.search_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
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
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEndOfListIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: EmptyStateWidget.endOfList(
        totalCount: _totalResults,
      ),
    );
  }

  Future<void> _navigateToDetail(SearchResult result) async {
    // On tablets: Select result instead of navigating
    final isTablet = ResponsiveUtils.isTabletOrLarger(context);
    if (isTablet) {
      await _selectResult(result);
      return;
    }

    // On phones: Navigate to full detail screen
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
        SnackBarHelper.showError(context, e);
      }
    }
  }
}
