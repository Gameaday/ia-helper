import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/favorite.dart';
import '../models/search_query.dart';
import '../models/search_result.dart';
import '../models/sort_option.dart';
import '../services/advanced_search_service.dart';
import '../services/archive_service.dart';
import '../services/favorites_service.dart';
import '../utils/animation_constants.dart';
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
  final AdvancedSearchService _searchService = AdvancedSearchService();
  final FavoritesService _favoritesService = FavoritesService.instance;
  List<SearchResult> _trendingResults = [];
  List<Favorite> _recentFavorites = [];
  bool _isLoadingTrending = false;
  bool _showFavorites = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTrendingContent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingContent() async {
    setState(() {
      _isLoadingTrending = true;
    });

    try {
      // Search for popular items sorted by downloads
      const query = SearchQuery(
        query: 'mediatype:(texts OR movies OR audio OR software)',
        sortBy: SortOption.downloads,
        rows: 20,
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
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTrending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load trending content: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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

            // Popular categories section
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _CategoryChip(
                          label: 'Books & Texts',
                          icon: Icons.menu_book,
                          onTap: () => _searchCategory('texts'),
                        ),
                        _CategoryChip(
                          label: 'Movies & Videos',
                          icon: Icons.movie,
                          onTap: () => _searchCategory('movies'),
                        ),
                        _CategoryChip(
                          label: 'Audio & Music',
                          icon: Icons.music_note,
                          onTap: () => _searchCategory('audio'),
                        ),
                        _CategoryChip(
                          label: 'Software',
                          icon: Icons.apps,
                          onTap: () => _searchCategory('software'),
                        ),
                        _CategoryChip(
                          label: 'Images',
                          icon: Icons.image,
                          onTap: () => _searchCategory('image'),
                        ),
                        _CategoryChip(
                          label: 'Web Archives',
                          icon: Icons.public,
                          onTap: () => _searchCategory('web'),
                        ),
                      ],
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Opening ${favorite.displayTitle}...',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
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
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final result = _trendingResults[index];
                    return _TrendingCard(result: result);
                  }, childCount: _trendingResults.length),
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
          } catch (e) {
            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading archive: $e'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail placeholder
            Expanded(
              child: Container(
                width: double.infinity,
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.inventory_2,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                result.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
