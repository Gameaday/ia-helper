import 'package:flutter/material.dart';
import 'package:internet_archive_helper/models/favorite.dart';
import 'package:internet_archive_helper/screens/archive_detail_screen.dart';
import 'package:internet_archive_helper/services/archive_service.dart';
import 'package:internet_archive_helper/services/favorites_service.dart';
import 'package:internet_archive_helper/utils/animation_constants.dart';
import 'package:internet_archive_helper/widgets/favorite_button.dart';
import 'package:provider/provider.dart';

/// Material Design 3 compliant favorites screen
///
/// Features:
/// - Grid/list view toggle with segmented button
/// - Filter by mediatype with filter chips
/// - Search favorites
/// - Sort options (recent, title, mediatype)
/// - Pull-to-refresh
/// - Empty state with MD3 illustration
/// - Navigate to archive detail on tap
/// - MD3 transitions (fadeThrough for navigation)
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favoritesService = FavoritesService.instance;
  final _searchController = TextEditingController();

  List<Favorite> _favorites = [];
  List<Favorite> _filteredFavorites = [];
  bool _isLoading = true;
  String? _error;

  // UI state
  ViewMode _viewMode = ViewMode.grid;
  String? _selectedMediaType;
  SortOption _sortOption = SortOption.recent;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final favorites = await _favoritesService.getAllFavorites();
      setState(() {
        _favorites = favorites;
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    var filtered = List<Favorite>.from(_favorites);

    // Apply mediatype filter
    if (_selectedMediaType != null) {
      filtered = filtered
          .where((f) => f.mediatype == _selectedMediaType)
          .toList();
    }

    // Apply search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((f) {
        return f.displayTitle.toLowerCase().contains(query) ||
            f.identifier.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sort
    switch (_sortOption) {
      case SortOption.recent:
        filtered.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case SortOption.title:
        filtered.sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
        break;
      case SortOption.mediatype:
        filtered.sort(
          (a, b) => (a.mediatype ?? '').compareTo(b.mediatype ?? ''),
        );
        break;
    }

    setState(() {
      _filteredFavorites = filtered;
    });
  }

  void _onFavoriteRemoved(String identifier) {
    setState(() {
      _favorites.removeWhere((f) => f.identifier == identifier);
      _applyFiltersAndSort();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSearching ? _buildSearchAppBar() : _buildAppBar(),
      body: RefreshIndicator(onRefresh: _loadFavorites, child: _buildBody()),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Favorites'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _isSearching = true),
          tooltip: 'Search favorites',
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: _showSortOptions,
          tooltip: 'Sort options',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _isSearching = false;
            _searchController.clear();
            _applyFiltersAndSort();
          });
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search favorites...',
          border: InputBorder.none,
        ),
        onChanged: (_) => _applyFiltersAndSort(),
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _applyFiltersAndSort();
            },
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
              'Error loading favorites',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadFavorites,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_favorites.isEmpty) {
      return _buildEmptyState();
    }

    if (_filteredFavorites.isEmpty) {
      return _buildNoResultsState();
    }

    return Column(
      children: [
        _buildControls(),
        Expanded(
          child: _viewMode == ViewMode.grid
              ? _buildGridView()
              : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // View mode toggle
          Row(
            children: [
              Expanded(
                child: SegmentedButton<ViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: ViewMode.grid,
                      icon: Icon(Icons.grid_view),
                      label: Text('Grid'),
                    ),
                    ButtonSegment(
                      value: ViewMode.list,
                      icon: Icon(Icons.view_list),
                      label: Text('List'),
                    ),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (Set<ViewMode> selected) {
                    setState(() => _viewMode = selected.first);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mediatype filter chips
          _buildMediaTypeFilters(),
        ],
      ),
    );
  }

  Widget _buildMediaTypeFilters() {
    // Get unique mediatypes from favorites
    final mediatypes =
        _favorites
            .map((f) => f.mediatype)
            .where((mt) => mt != null && mt.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    if (mediatypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedMediaType == null,
            onSelected: (_) {
              setState(() {
                _selectedMediaType = null;
                _applyFiltersAndSort();
              });
            },
          ),
          const SizedBox(width: 8),
          ...mediatypes.map((mediatype) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(mediatype!),
                selected: _selectedMediaType == mediatype,
                onSelected: (_) {
                  setState(() {
                    _selectedMediaType = mediatype;
                    _applyFiltersAndSort();
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: _filteredFavorites.length,
      itemBuilder: (context, index) {
        return _buildGridItem(_filteredFavorites[index]);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredFavorites.length,
      itemBuilder: (context, index) {
        return _buildListItem(_filteredFavorites[index]);
      },
    );
  }

  Widget _buildGridItem(Favorite favorite) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToDetail(favorite),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail placeholder
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  _getIconForMediaType(favorite.mediatype),
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      favorite.displayTitle,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (favorite.mediatype != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        favorite.mediatype!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            favorite.formattedAddedDate,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Favorite button overlay
            Positioned(
              top: 8,
              right: 8,
              child: FavoriteIconButton(
                identifier: favorite.identifier,
                onFavoriteChanged: (_) =>
                    _onFavoriteRemoved(favorite.identifier),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(Favorite favorite) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconForMediaType(favorite.mediatype),
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          favorite.displayTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (favorite.mediatype != null) ...[
              const SizedBox(height: 4),
              Text(favorite.mediatype!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 4),
            Text(
              favorite.formattedAddedDate,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: FavoriteIconButton(
          identifier: favorite.identifier,
          onFavoriteChanged: (_) => _onFavoriteRemoved(favorite.identifier),
        ),
        onTap: () => _navigateToDetail(favorite),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 96,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No favorites yet',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start adding your favorite archives by tapping the heart icon',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 96,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No results found',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your filters or search query',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _selectedMediaType = null;
                  _searchController.clear();
                  _applyFiltersAndSort();
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Sort by'),
                    titleTextStyle: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(height: 1),
                  RadioGroup<SortOption>(
                    groupValue: _sortOption,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortOption = value;
                          _applyFiltersAndSort();
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: const Column(
                      children: [
                        RadioListTile<SortOption>(
                          title: Text('Most recent'),
                          value: SortOption.recent,
                        ),
                        RadioListTile<SortOption>(
                          title: Text('Title (A-Z)'),
                          value: SortOption.title,
                        ),
                        RadioListTile<SortOption>(
                          title: Text('Media type'),
                          value: SortOption.mediatype,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToDetail(Favorite favorite) async {
    // Load the metadata into the archive service
    final archiveService = Provider.of<ArchiveService>(context, listen: false);

    // Show loading indicator while fetching metadata
    if (!mounted) return;

    try {
      // Fetch the metadata for this identifier
      await archiveService.fetchMetadata(favorite.identifier);

      if (!mounted) return;

      // Navigate to detail screen with MD3 fadeThrough transition
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ArchiveDetailScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // MD3 fadeThrough transition
            return FadeTransition(
              opacity: CurveTween(
                curve: MD3Curves.emphasized,
              ).animate(animation),
              child: child,
            );
          },
          transitionDuration: MD3Durations.medium,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading archive: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  IconData _getIconForMediaType(String? mediatype) {
    switch (mediatype?.toLowerCase()) {
      case 'texts':
        return Icons.article;
      case 'movies':
        return Icons.movie;
      case 'audio':
        return Icons.audiotrack;
      case 'image':
        return Icons.image;
      case 'software':
        return Icons.computer;
      case 'data':
        return Icons.dataset;
      case 'web':
        return Icons.public;
      default:
        return Icons.archive;
    }
  }
}

enum ViewMode { grid, list }

enum SortOption { recent, title, mediatype }
