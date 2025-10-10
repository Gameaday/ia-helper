import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/favorite.dart';
import '../models/search_query.dart';
import '../models/search_result.dart';
import '../models/sort_option.dart';
import '../services/advanced_search_service.dart';
import '../services/archive_service.dart';
import '../services/favorites_service.dart';
import '../utils/animation_constants.dart';
import '../utils/snackbar_helper.dart';
import 'advanced_search_screen.dart';
import 'archive_detail_screen.dart';
import 'search_results_screen.dart';

/// Discover screen for exploring Internet Archive content
///
/// Features:
/// - Keyword search bar for general queries
/// - Quick access to advanced search
/// - Trending and recommended archives
/// - Popular collections
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final AdvancedSearchService _searchService = AdvancedSearchService();
  final FavoritesService _favoritesService = FavoritesService.instance;
  List<SearchResult> _trendingResults = [];
  List<Favorite> _recentFavorites = [];
  bool _isLoadingTrending = false;
  bool _isLoadingMore = false;
  bool _hasMoreResults = true;
  bool _showFavorites = false;
  int _currentPage = 0;
  static const int _pageSize = 20; // Reduced from 40 to halve image API requests

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTrendingContent();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !_hasMoreResults) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = 200.0; // Trigger 200px before bottom

    if (currentScroll >= (maxScroll - delta)) {
      _loadMoreTrendingContent();
    }
  }

  Future<void> _loadTrendingContent() async {
    setState(() {
      _isLoadingTrending = true;
      _currentPage = 0;
      _hasMoreResults = true;
    });

    try {
      // Search for popular items sorted by downloads
      const query = SearchQuery(
        query: 'mediatype:(texts OR movies OR audio OR software)',
        sortBy: SortOption.downloads,
        rows: 40, // _pageSize
        page: 1,
      );

      final results = await _searchService.search(query);

      // Also load recent favorites (up to 5)
      final favorites = await _favoritesService.getAllFavorites();
      final recentFavorites = favorites.take(5).toList();

      if (mounted) {
        setState(() {
          _trendingResults = results;
          _recentFavorites = recentFavorites;
          _isLoadingTrending = false;
          _currentPage = 1;
          _hasMoreResults = results.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTrending = false;
        });
        SnackBarHelper.showError(context, e);
      }
    }
  }

  Future<void> _loadMoreTrendingContent() async {
    if (_isLoadingMore || !_hasMoreResults) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final query = SearchQuery(
        query: 'mediatype:(texts OR movies OR audio OR software)',
        sortBy: SortOption.downloads,
        rows: _pageSize,
        page: nextPage,
      );

      final results = await _searchService.search(query);

      if (mounted) {
        setState(() {
          _trendingResults.addAll(results);
          _currentPage = nextPage;
          _hasMoreResults = results.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        // Silent failure for pagination - don't show error snackbar
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      return;
    }

    // Navigate to search results with simple search
    final searchQuery = SearchQuery.simple(query);

    if (mounted) {
      await Navigator.push(
        context,
        MD3PageTransitions.sharedAxis(
          page: SearchResultsScreen(query: searchQuery),
          settings: const RouteSettings(name: '/search-results'),
        ),
      );
    }
  }

  void _openAdvancedSearch() {
    Navigator.push(
      context,
      MD3PageTransitions.sharedAxis(
        page: const AdvancedSearchScreen(),
        settings: const RouteSettings(name: '/advanced-search'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Discover'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _loadTrendingContent,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Search bar section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Keyword search field
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search Internet Archive...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _performSearch,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    // Advanced search button
                    OutlinedButton.icon(
                      onPressed: _openAdvancedSearch,
                      icon: const Icon(Icons.tune),
                      label: const Text('Advanced Search'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Popular categories section (responsive grid)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Popular Categories',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Responsive category grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Determine columns based on width
                        int columns;
                        if (constraints.maxWidth < 600) {
                          columns = 2; // Phone: 2 columns
                        } else if (constraints.maxWidth < 900) {
                          columns = 3; // Tablet: 3 columns
                        } else {
                          columns = 4; // Desktop: 4 columns
                        }

                        final categories = [
                          ('Books & Texts', Icons.menu_book, 'texts'),
                          ('Movies & Videos', Icons.movie, 'movies'),
                          ('Audio & Music', Icons.music_note, 'audio'),
                          ('Software', Icons.apps, 'software'),
                          ('Images', Icons.image, 'image'),
                          ('Web Archives', Icons.public, 'web'),
                        ];

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final (label, icon, category) = categories[index];
                            return _CategoryChip(
                              label: label,
                              icon: icon,
                              onTap: () => _searchCategory(category),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Quick Favorites section (subtle, collapsible)
            if (_recentFavorites.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showFavorites = !_showFavorites;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Quick Favorites',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${_recentFavorites.length})',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                _showFavorites
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showFavorites) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _recentFavorites.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final favorite = _recentFavorites[index];
                              return ActionChip(
                                avatar: Icon(
                                  _getMediaIcon(favorite.mediatype),
                                  size: 16,
                                ),
                                label: Text(
                                  favorite.displayTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onPressed: () {
                                  // Navigate to archive detail
                                  SnackBarHelper.showInfo(
                                    context,
                                    'Opening ${favorite.displayTitle}...',
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Trending content section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trending Now',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isLoadingTrending)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),

            // Trending items grid
            if (_trendingResults.isEmpty && !_isLoadingTrending)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.explore_outlined,
                        size: 64,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No trending content available',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadTrendingContent,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Responsive trending items grid
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    // Determine columns based on width
                    int columns;
                    if (constraints.crossAxisExtent < 600) {
                      columns = 2; // Phone: 2 columns
                    } else if (constraints.crossAxisExtent < 900) {
                      columns = 3; // Tablet: 3 columns
                    } else if (constraints.crossAxisExtent < 1200) {
                      columns = 4; // Desktop: 4 columns
                    } else {
                      columns = 5; // Large: 5 columns
                    }

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final result = _trendingResults[index];
                          return _TrendingCard(result: result);
                        },
                        childCount: _trendingResults.length,
                      ),
                    );
                  },
                ),
              ),

            // Loading more indicator
            if (_isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading more...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // End message when no more results
            if (!_isLoadingMore && !_hasMoreResults && _trendingResults.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Text(
                      'No more results',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _searchCategory(String mediatype) {
    final query = SearchQuery.mediatype(mediatype);

    Navigator.push(
      context,
      MD3PageTransitions.sharedAxis(
        page: SearchResultsScreen(query: query),
        settings: const RouteSettings(name: '/search-results'),
      ),
    );
  }

  IconData _getMediaIcon(String? mediaType) {
    switch (mediaType?.toLowerCase()) {
      case 'texts':
        return Icons.menu_book;
      case 'movies':
        return Icons.movie;
      case 'audio':
        return Icons.music_note;
      case 'software':
        return Icons.apps;
      case 'image':
        return Icons.image;
      case 'web':
        return Icons.public;
      default:
        return Icons.inventory_2;
    }
  }
}

/// Category chip widget for quick category access
class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: colorScheme.surfaceContainerHighest,
      side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
    );
  }
}

/// Trending content card widget
class _TrendingCard extends StatelessWidget {
  final SearchResult result;

  const _TrendingCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final archiveService = context.read<ArchiveService>();

          try {
            // Show loading indicator
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Loading ${result.title}...'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }

            // Fetch metadata for the archive
            await archiveService.fetchMetadata(result.identifier);

            if (!context.mounted) return;

            // Navigate to detail screen with MD3 fadeThrough transition
            await Navigator.push(
              context,
              MD3PageTransitions.fadeThrough(
                page: const ArchiveDetailScreen(),
                settings: const RouteSettings(name: '/archive-detail'),
              ),
            );
          } on FormatException catch (e) {
            if (!context.mounted) return;
            SnackBarHelper.showError(
              context,
              'Invalid archive: ${e.message}',
            );
          } catch (e) {
            if (!context.mounted) return;
            
            // Provide more specific error messages
            String errorMessage = 'Could not open archive';
            if (e.toString().contains('404') ||
                e.toString().contains('not found')) {
              errorMessage = 'Archive "${result.identifier}" not found';
            } else if (e.toString().contains('timeout')) {
              errorMessage = 'Request timed out. Please try again.';
            } else if (e.toString().contains('network')) {
              errorMessage = 'Network error. Check your connection.';
            }
            
            SnackBarHelper.showError(context, errorMessage);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail image with fallback
            Expanded(
              child: result.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: result.thumbnailUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.inventory_2,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.inventory_2,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                    ),
            ),
            // Title and description
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      result.description,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
