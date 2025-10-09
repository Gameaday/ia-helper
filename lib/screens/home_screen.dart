import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/search_query.dart';
import '../models/search_history_entry.dart';
import '../services/archive_service.dart';
import '../services/history_service.dart';
import '../services/search_history_service.dart';
import '../utils/semantic_colors.dart';
import '../utils/responsive_utils.dart';
import '../utils/animation_constants.dart';
import '../widgets/intelligent_search_bar.dart';
import '../widgets/search_suggestion_card.dart';
import '../widgets/download_manager_widget.dart';
import '../widgets/archive_info_widget.dart';
import '../widgets/file_list_widget.dart';
import '../widgets/download_controls_widget.dart';
import 'advanced_search_screen.dart';
import 'archive_detail_screen.dart';
import 'search_results_screen.dart';
import 'help_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Initialize the services
      context.read<ArchiveService>().initialize();
      context.read<HistoryService>().loadHistory();

      // Listen for metadata changes to navigate to detail screen
      context.read<ArchiveService>().addListener(_onServiceChanged);
    });
  }

  @override
  void dispose() {
    // Safe removal - only if context is still valid
    try {
      context.read<ArchiveService>().removeListener(_onServiceChanged);
    } catch (e) {
      // Context may already be invalid during disposal
      debugPrint('Warning: Could not remove listener during dispose: $e');
    }
    super.dispose();
  }

  void _onServiceChanged() {
    final service = context.read<ArchiveService>();

    // On tablets, we show detail inline - no navigation needed
    if (ResponsiveUtils.isTabletOrLarger(context)) {
      // Just update state to show detail panel
      if (mounted) {
        setState(() {});
      }
      return;
    }

    // On phones, navigate to detail screen only when metadata is successfully loaded
    // Check that we have metadata AND no error AND not currently loading
    if (service.currentMetadata != null &&
        service.error == null &&
        !service.isLoading &&
        mounted &&
        !_hasNavigated) {
      _hasNavigated = true;

      Navigator.of(context)
          .push(
            MD3PageTransitions.fadeThrough(
              page: const ArchiveDetailScreen(),
              settings: const RouteSettings(
                name: ArchiveDetailScreen.routeName,
              ),
            ),
          )
          .then((_) {
            // Reset flag when returning from detail screen
            _hasNavigated = false;
          });
    } else if (service.currentMetadata == null) {
      // Reset flag when metadata is cleared
      _hasNavigated = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internet Archive Helper'),
        actions: [
          // Help screen
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(
                context,
                MD3PageTransitions.sharedAxis(
                  page: const HelpScreen(),
                  settings: const RouteSettings(name: '/help'),
                ),
              );
            },
            tooltip: 'Help',
          ),
          // Overflow menu for less-used actions
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'history':
                  _navigateToHistory();
                  break;
                case 'advanced':
                  _navigateToAdvancedSearch();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 12),
                    Text('Search History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'advanced',
                child: Row(
                  children: [
                    Icon(Icons.tune),
                    SizedBox(width: 12),
                    Text('Advanced Search'),
                  ],
                ),
              ),
            ],
            tooltip: 'More',
          ),
        ],
      ),
      body: Consumer<ArchiveService>(
        builder: (context, service, child) {
          if (!service.isInitialized) {
            // Show error if initialization failed
            if (service.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: SemanticColors.error(context),
                        size: 64,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Initialization Failed',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        service.error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // Try to re-initialize
                          service.initialize();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Show loading if still initializing
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing Internet Archive Helper...'),
                ],
              ),
            );
          }

          // Build master-detail layout for tablets, standard layout for phones
          final masterPanel = _buildMasterPanel(context, service);
          final hasDetail =
              service.currentMetadata != null && service.error == null;

          if (ResponsiveUtils.isTabletOrLarger(context) && hasDetail) {
            // Master-detail layout for tablets when we have archive data
            return Row(
              children: [
                // Master panel (search & suggestions) - left side
                Expanded(
                  flex: (ResponsiveUtils.getMasterDetailRatio(context) * 100)
                      .round(),
                  child: masterPanel,
                ),
                // Divider
                Container(width: 1, color: Theme.of(context).dividerColor),
                // Detail panel (archive details) - right side
                Expanded(
                  flex:
                      ((1.0 - ResponsiveUtils.getMasterDetailRatio(context)) *
                              100)
                          .round(),
                  child: _buildDetailPanel(context, service),
                ),
              ],
            );
          }

          // Standard single-panel layout for phones or when no detail
          return masterPanel;
        },
      ),
    );
  }

  /// Build the master panel (search and suggestions)
  Widget _buildMasterPanel(BuildContext context, ArchiveService service) {
    // Safety check: if we're on home screen, metadata should be cleared (phones only)
    if (!ResponsiveUtils.isTabletOrLarger(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && service.currentMetadata != null && !_hasNavigated) {
          // We have metadata but haven't navigated - this shouldn't happen normally
          // Clear it to ensure consistent state
          service.clearMetadata();
        }
      });
    }

    return Column(
      children: [
        // Intelligent search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: IntelligentSearchBar(
            onSearch: _handleSearch,
            hintText: 'Search Internet Archive',
          ),
        ),

        // Recent searches chips (from history)
        Consumer<HistoryService>(
          builder: (context, historyService, child) {
            final recentSearches = historyService.history.take(5).toList();
            
            if (recentSearches.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Searches',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: recentSearches.map((entry) {
                      return ActionChip(
                        label: Text(
                          entry.identifier,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => _handleSearch(entry.identifier, SearchType.identifier),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),

        // Quick action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to Discover tab (index 2)
                    // This would require NavigationState from main.dart
                    // For now, show a message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Navigate to Discover tab')),
                    );
                  },
                  icon: const Icon(Icons.explore),
                  label: const Text('Discover'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _navigateToAdvancedSearch,
                  icon: const Icon(Icons.tune),
                  label: const Text('Advanced'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Error display
        if (service.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.error),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        service.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Search suggestions
        if (service.suggestions.isNotEmpty)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Suggestions:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ...service.suggestions.map((suggestion) {
                  return SearchSuggestionCard(
                    suggestion: suggestion,
                    onTap: () {
                      // Clear error and suggestions before fetching
                      service.clearMetadata();
                      // Fetch metadata for the suggested archive
                      service.fetchMetadata(suggestion.identifier);
                    },
                  );
                }),
              ],
            ),
          ),

        // Loading indicator
        if (service.isLoading) const LinearProgressIndicator(),

        // Empty state when not loading and no metadata
        if (!service.isLoading &&
            service.currentMetadata == null &&
            service.suggestions.isEmpty &&
            service.error == null)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 64,
                      color: SemanticColors.disabled(context),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Search Internet Archive',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: SemanticColors.subtitle(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Search Tips',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTipRow(context, Icons.tag, 'Enter an archive identifier:', 'nasa_images'),
                            const SizedBox(height: 8),
                            _buildTipRow(context, Icons.search, 'Search by keywords:', 'classic books'),
                            const SizedBox(height: 8),
                            _buildTipRow(context, Icons.filter_alt, 'Use advanced search:', 'title:space AND mediatype:movies'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Active downloads manager at bottom
        const DownloadManagerWidget(),
      ],
    );
  }

  /// Build the detail panel (archive details for tablets)
  Widget _buildDetailPanel(BuildContext context, ArchiveService service) {
    if (service.currentMetadata == null) {
      return const Center(child: Text('No archive selected'));
    }

    return Column(
      children: [
        // App bar for detail panel
        Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).appBarTheme.backgroundColor ??
                Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Clear selection',
                    onPressed: () {
                      service.clearMetadata();
                    },
                  ),
                  Expanded(
                    child: Text(
                      service.currentMetadata!.identifier,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Detail content
        Expanded(
          child: ListView(
            padding: ResponsiveUtils.getScreenPadding(context),
            children: [
              ArchiveInfoWidget(metadata: service.currentMetadata!),
              const SizedBox(height: 16),
              FileListWidget(files: service.currentMetadata!.files),
              const SizedBox(height: 16),
              const DownloadControlsWidget(),
            ],
          ),
        ),
      ],
    );
  }

  /// Handle search from IntelligentSearchBar
  void _handleSearch(String query, SearchType type) {
    if (query.trim().isEmpty) return;

    final archiveService = context.read<ArchiveService>();

    // Save search to history
    _saveSearchToHistory(query);

    switch (type) {
      case SearchType.identifier:
        // Direct identifier search - fetch metadata
        archiveService.clearMetadata();
        archiveService.fetchMetadata(query);
        break;

      case SearchType.keyword:
      case SearchType.advanced:
        // Navigate to search results screen
        Navigator.push(
          context,
          MD3PageTransitions.sharedAxis(
            page: SearchResultsScreen(query: SearchQuery.simple(query)),
            settings: const RouteSettings(name: '/search-results'),
          ),
        );
        break;

      case SearchType.empty:
        // Do nothing for empty search
        break;
    }
  }

  /// Save search query to SearchHistoryService
  Future<void> _saveSearchToHistory(String query) async {
    try {
      final entry = SearchHistoryEntry.create(query: query);
      await SearchHistoryService.instance.addEntry(entry);
      
      if (kDebugMode) {
        debugPrint('[HomeScreen] Saved search to history: $query');
      }
    } catch (e) {
      // Don't fail the search if history save fails
      if (kDebugMode) {
        debugPrint('[HomeScreen] Failed to save search to history: $e');
      }
    }
  }

  /// Build a tip row for the empty state
  Widget _buildTipRow(BuildContext context, IconData icon, String label, String example) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: SemanticColors.subtitle(context),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: SemanticColors.subtitle(context),
              ),
              children: [
                TextSpan(text: label),
                const TextSpan(text: ' '),
                TextSpan(
                  text: example,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Navigate to History screen
  void _navigateToHistory() {
    // Navigate to History tab (index 1 in bottom nav)
    // This would require NavigationState from main.dart
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to History tab')),
    );
  }

  /// Navigate to Advanced Search screen
  void _navigateToAdvancedSearch() {
    Navigator.push(
      context,
      MD3PageTransitions.sharedAxis(
        page: const AdvancedSearchScreen(),
        settings: const RouteSettings(name: AdvancedSearchScreen.routeName),
      ),
    );
  }
}
