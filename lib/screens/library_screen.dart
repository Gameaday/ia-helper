import 'package:flutter/material.dart';
import 'package:internet_archive_helper/models/collection.dart';
import 'package:internet_archive_helper/models/downloaded_archive.dart';
import 'package:internet_archive_helper/models/favorite.dart';
import 'package:internet_archive_helper/models/search_query.dart';
import 'package:internet_archive_helper/screens/archive_detail_screen.dart';
import 'package:internet_archive_helper/screens/search_results_screen.dart';
import 'package:internet_archive_helper/services/archive_service.dart';
import 'package:internet_archive_helper/services/collections_service.dart';
import 'package:internet_archive_helper/services/favorites_service.dart';
import 'package:internet_archive_helper/services/local_archive_storage.dart';
import 'package:internet_archive_helper/utils/animation_constants.dart';
import 'package:internet_archive_helper/core/utils/formatting_utils.dart';
import 'package:internet_archive_helper/utils/snackbar_helper.dart';
import 'package:internet_archive_helper/widgets/error_card.dart';
import 'package:provider/provider.dart';

/// Material Design 3 Library screen consolidating downloads, collections, and favorites
///
/// Features:
/// - Four tabs: All Downloads, Collections, Favorites, Recent
/// - Filters: date, size, type
/// - Sort options: name, date, size
/// - Grid/list view toggle
/// - Search within library
/// - Empty states with CTAs
/// - MD3 transitions and animations
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;
  final _localArchiveStorage = LocalArchiveStorage();
  final _collectionsService = CollectionsService.instance;
  final _favoritesService = FavoritesService.instance;

  List<DownloadedArchive> _archives = [];
  List<Collection> _collections = [];
  List<Favorite> _favorites = [];
  Map<int, int> _collectionItemCounts = {};

  bool _isLoading = true;
  String? _error;
  bool _isGridView = false;
  String _searchQuery = '';
  _SortOption _sortOption = _SortOption.dateDesc;

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when screen becomes visible (e.g., after favoriting an item)
    // This ensures favorites, collections, and downloads are always up-to-date
    if (mounted) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _localArchiveStorage.initialize();
      final archives = _localArchiveStorage.archives.values.toList();
      final collections = await _collectionsService.getAllCollections();
      final favorites = await _favoritesService.getAllFavorites();

      // Load item counts for collections
      final counts = <int, int>{};
      for (final collection in collections) {
        final count = await _collectionsService.getCollectionItemCount(
          collection.id!,
        );
        counts[collection.id!] = count;
      }

      setState(() {
        _archives = archives;
        _collections = collections;
        _favorites = favorites;
        _collectionItemCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          if (_tabController.index == 0) ...[
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () => setState(() => _isGridView = !_isGridView),
              tooltip: _isGridView ? 'List view' : 'Grid view',
            ),
          ],
          if (_tabController.index == 1)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createCollection,
              tooltip: 'Create collection',
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 12),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 12),
                    Text('Search'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sort',
                child: Row(
                  children: [
                    Icon(Icons.sort),
                    SizedBox(width: 12),
                    Text('Sort'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Downloads'),
            Tab(text: 'Collections'),
            Tab(text: 'Favorites'),
            Tab(text: 'Recent'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorCard(
        error: Exception(_error!),
        onRetry: _loadData,
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllDownloadsTab(),
        _buildCollectionsTab(),
        _buildFavoritesTab(),
        _buildRecentTab(),
      ],
    );
  }

  // All Downloads Tab
  Widget _buildAllDownloadsTab() {
    final filtered = _getFilteredArchives();

    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: Icons.download_done,
        title: 'No downloads yet',
        subtitle: 'Downloaded archives will appear here',
        actionLabel: 'Explore Archives',
        onAction: () => _tabController.animateTo(2),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: _isGridView ? _buildGridView(filtered) : _buildListView(filtered),
    );
  }

  // Collections Tab
  Widget _buildCollectionsTab() {
    if (_collections.isEmpty) {
      return _buildEmptyState(
        icon: Icons.folder_open,
        title: 'No collections yet',
        subtitle: 'Create collections to organize your downloads',
        actionLabel: 'Create Collection',
        onAction: _createCollection,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          
          // Responsive layout decision:
          // - Phone (<600dp): Single column list (better for detailed cards)
          // - Tablet (600-900dp): 2 column grid
          // - Desktop (>900dp): 3-4 column grid
          
          if (width < 600) {
            // Phone: Single column list for detailed view
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _collections.length,
              itemBuilder: (context, index) {
                return _buildCollectionCard(_collections[index]);
              },
            );
          } else {
            // Tablet/Desktop: Responsive grid
            final crossAxisCount = width < 900 ? 2 : (width < 1200 ? 3 : 4);
            
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.2, // Slightly wider than tall
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _collections.length,
              itemBuilder: (context, index) {
                return _buildCollectionGridCard(_collections[index]);
              },
            );
          }
        },
      ),
    );
  }

  // Favorites Tab
  Widget _buildFavoritesTab() {
    if (_favorites.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_outline,
        title: 'No favorites yet',
        subtitle: 'Favorite archives will appear here for quick access',
        actionLabel: 'Discover Content',
        onAction: () {
          // Navigate to Discover tab (index 2 in bottom nav)
          // This would require access to the parent navigation state
          // For now, we'll just show a snackbar
          SnackBarHelper.showInfo(
            context,
            'Go to Discover tab to find content to favorite',
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          return _buildFavoriteCard(_favorites[index]);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(Favorite favorite) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconForMediaType(favorite.mediatype),
            color: colorScheme.primary,
          ),
        ),
        title: Text(
          favorite.displayTitle,
          style: theme.textTheme.titleMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              favorite.identifier,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Added ${_formatDate(favorite.addedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.favorite),
          color: colorScheme.primary,
          onPressed: () async {
            await _favoritesService.removeFavorite(favorite.identifier);
            await _loadData();
          },
        ),
        onTap: () => _openFavorite(favorite),
      ),
    );
  }

  Future<void> _openFavorite(Favorite favorite) async {
    final archiveService = context.read<ArchiveService>();

    try {
      // Fetch metadata for the archive
      await archiveService.fetchMetadata(favorite.identifier);

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
      if (!mounted) return;

      SnackBarHelper.showError(context, e);
    }
  }

  IconData _getIconForMediaType(String? mediaType) {
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

  IconData _parseCollectionIcon(String? iconString) {
    if (iconString == null) return Icons.folder;

    try {
      final codePoint = int.parse(iconString);
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    } catch (e) {
      // If parsing fails, use default folder icon
      return Icons.folder;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  // Recent Tab
  Widget _buildRecentTab() {
    final recent = _localArchiveStorage.recentArchives.take(20).toList();

    if (recent.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No recent activity',
        subtitle: 'Recently accessed downloads will appear here',
        actionLabel: 'Browse Library',
        onAction: () => _tabController.animateTo(0),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recent.length,
        itemBuilder: (context, index) {
          return _buildArchiveListTile(recent[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 96, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<DownloadedArchive> archives) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        // Responsive grid columns based on width
        // Phone: 2 columns, Tablet: 3 columns, Desktop: 4 columns
        final crossAxisCount = width < 600 
            ? 2 
            : (width < 900 ? 3 : (width < 1200 ? 4 : 5));
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: archives.length,
          itemBuilder: (context, index) {
            return _buildArchiveGridCard(archives[index]);
          },
        );
      },
    );
  }

  Widget _buildListView(List<DownloadedArchive> archives) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        // Responsive list layout:
        // Phone (<600dp): Single column
        // Tablet/Desktop (≥600dp): Two columns for better space utilization
        
        if (width < 600) {
          // Single column list for phones
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: archives.length,
            itemBuilder: (context, index) {
              return _buildArchiveListTile(archives[index]);
            },
          );
        } else {
          // Two-column grid for tablets and desktops
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.5, // Wide cards for list-style layout
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
            ),
            itemCount: archives.length,
            itemBuilder: (context, index) {
              return _buildArchiveListTile(archives[index]);
            },
          );
        }
      },
    );
  }

  Widget _buildArchiveGridCard(DownloadedArchive archive) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openArchive(archive),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail placeholder
            Container(
              height: 120,
              color: colorScheme.surfaceContainerHighest,
              child: Center(
                child: Icon(
                  Icons.archive,
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
                      archive.metadata.title ?? archive.identifier,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.description,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${archive.downloadedFiles} files',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FormattingUtils.formatBytes(archive.downloadedBytes),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchiveListTile(DownloadedArchive archive) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.archive, color: colorScheme.onSurfaceVariant),
        ),
        title: Text(
          archive.metadata.title ?? archive.identifier,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${archive.downloadedFiles} files • ${FormattingUtils.formatBytes(archive.downloadedBytes)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleArchiveAction(value, archive),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(Icons.folder_open),
                  SizedBox(width: 12),
                  Text('Open'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'add_to_collection',
              child: Row(
                children: [
                  Icon(Icons.add_to_photos),
                  SizedBox(width: 12),
                  Text('Add to Collection'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 12),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _openArchive(archive),
      ),
    );
  }

  /// Build collection card for list view (detailed, horizontal layout)
  Widget _buildCollectionCard(Collection collection) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final itemCount = _collectionItemCounts[collection.id] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openCollection(collection),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Collection icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: collection.color ?? colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  collection.iconData,
                  color: collection.color != null
                      ? _getContrastColor(collection.color!)
                      : colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Collection info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (collection.description != null &&
                        collection.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        collection.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  /// Build collection card for grid view (compact, vertical layout)
  Widget _buildCollectionGridCard(Collection collection) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final itemCount = _collectionItemCounts[collection.id] ?? 0;

    return Card(
      child: InkWell(
        onTap: () => _openCollection(collection),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Collection icon (larger for grid)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: collection.color ?? colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  collection.iconData,
                  color: collection.color != null
                      ? _getContrastColor(collection.color!)
                      : colorScheme.onPrimaryContainer,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              // Collection name
              Text(
                collection.name,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Item count
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DownloadedArchive> _getFilteredArchives() {
    var filtered = _archives;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((archive) {
        return archive.identifier.toLowerCase().contains(query) ||
            (archive.metadata.title?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply sort
    filtered = List.from(filtered);
    switch (_sortOption) {
      case _SortOption.nameAsc:
        filtered.sort((a, b) {
          final aTitle = a.metadata.title ?? a.identifier;
          final bTitle = b.metadata.title ?? b.identifier;
          return aTitle.compareTo(bTitle);
        });
        break;
      case _SortOption.nameDesc:
        filtered.sort((a, b) {
          final aTitle = a.metadata.title ?? a.identifier;
          final bTitle = b.metadata.title ?? b.identifier;
          return bTitle.compareTo(aTitle);
        });
        break;
      case _SortOption.dateAsc:
        filtered.sort((a, b) => a.downloadedAt.compareTo(b.downloadedAt));
        break;
      case _SortOption.dateDesc:
        filtered.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
        break;
      case _SortOption.sizeAsc:
        filtered.sort((a, b) => a.downloadedBytes.compareTo(b.downloadedBytes));
        break;
      case _SortOption.sizeDesc:
        filtered.sort((a, b) => b.downloadedBytes.compareTo(a.downloadedBytes));
        break;
    }

    return filtered;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _loadData();
        break;
      case 'search':
        _showSearchDialog();
        break;
      case 'sort':
        _showSortOptions();
        break;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Library'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter search query',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Sort by',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._SortOption.values.map((option) {
                final isSelected = _sortOption == option;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    selected: isSelected,
                    selectedTileColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    title: Text(option.label),
                    onTap: () {
                      setState(() => _sortOption = option);
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _handleArchiveAction(String action, DownloadedArchive archive) {
    switch (action) {
      case 'open':
        _openArchive(archive);
        break;
      case 'add_to_collection':
        _addToCollection(archive);
        break;
      case 'delete':
        _deleteArchive(archive);
        break;
    }
  }

  void _openArchive(DownloadedArchive archive) {
    // Navigate to archive detail screen
    Navigator.pushNamed(
      context,
      ArchiveDetailScreen.routeName,
      arguments: archive.identifier,
    );
  }

  void _openCollection(Collection collection) {
    // Navigate to collection detail/search screen showing collection items
    // Use the collection name as a query to find related archives
    Navigator.pushNamed(
      context,
      SearchResultsScreen.routeName,
      arguments: {
        'query': SearchQuery(
          query: collection.name,
          collection: collection.name,
        ),
        'title': collection.name,
      },
    );
  }

  void _createCollection() {
    // Show collection creation dialog
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Collection'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Collection Name',
            hintText: 'Enter a name for your collection',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final collectionName = controller.text.trim();

                try {
                  await _collectionsService.createCollection(
                    name: collectionName,
                    description: null,
                  );
                  if (!context.mounted) return;
                  
                  Navigator.of(context).pop();
                  _loadData(); // Reload to show new collection
                  SnackBarHelper.showSuccess(
                    context,
                    'Created "$collectionName"',
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  SnackBarHelper.showError(context, e);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _addToCollection(DownloadedArchive archive) {
    // Show collection selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Collection'),
        content: SizedBox(
          width: double.maxFinite,
          child: _collections.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No collections yet. Create one first!'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _collections.length,
                  itemBuilder: (context, index) {
                    final collection = _collections[index];
                    // Pre-compute icon to avoid non-const IconData in web builds
                    final collectionIcon = _parseCollectionIcon(
                      collection.icon,
                    );

                    return ListTile(
                      leading: Icon(collectionIcon),
                      title: Text(collection.name),
                      subtitle: collection.description != null
                          ? Text(collection.description!)
                          : null,
                      onTap: () async {
                        final archiveId = archive.identifier;
                        final collName = collection.name;

                        try {
                          await _collectionsService.addItemToCollection(
                            collectionId: collection.id!,
                            identifier: archiveId,
                          );
                          if (!context.mounted) return;
                          
                          Navigator.of(context).pop();
                          SnackBarHelper.showSuccess(
                            context,
                            'Added "$archiveId" to $collName',
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          SnackBarHelper.showError(context, e);
                        }
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _deleteArchive(DownloadedArchive archive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Delete Archive?'),
        content: Text(
          'This will delete ${archive.identifier} from your library. Files on disk will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _localArchiveStorage.removeArchive(archive.identifier);
              await _loadData();
              if (!context.mounted) return;
              
              SnackBarHelper.showSuccess(
                context,
                'Archive deleted from library',
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getContrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

enum _SortOption {
  nameAsc('Name (A-Z)'),
  nameDesc('Name (Z-A)'),
  dateAsc('Date (Oldest)'),
  dateDesc('Date (Newest)'),
  sizeAsc('Size (Smallest)'),
  sizeDesc('Size (Largest)');

  final String label;
  const _SortOption(this.label);
}
