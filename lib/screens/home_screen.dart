import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/archive_service.dart';
import '../services/history_service.dart';
import '../utils/semantic_colors.dart';
import '../utils/responsive_utils.dart';
import '../utils/animation_constants.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/search_suggestion_card.dart';
import '../widgets/download_manager_widget.dart';
import '../widgets/archive_info_widget.dart';
import '../widgets/file_list_widget.dart';
import '../widgets/download_controls_widget.dart';
import 'archive_detail_screen.dart';
import 'download_screen.dart';
import 'help_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'collections_screen.dart';

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
        title: const Text('Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/download-queue');
            },
            tooltip: 'Download Queue',
          ),
          IconButton(
            icon: const Icon(Icons.manage_search),
            onPressed: () {
              Navigator.pushNamed(context, '/advanced-search');
            },
            tooltip: 'Advanced Search',
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MD3PageTransitions.sharedAxis(
                  page: const FavoritesScreen(),
                  settings: const RouteSettings(name: '/favorites'),
                ),
              );
            },
            tooltip: 'Favorites',
          ),
          IconButton(
            icon: const Icon(Icons.collections_bookmark),
            onPressed: () {
              Navigator.push(
                context,
                MD3PageTransitions.sharedAxis(
                  page: const CollectionsScreen(),
                  settings: const RouteSettings(name: '/collections'),
                ),
              );
            },
            tooltip: 'Collections',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MD3PageTransitions.sharedAxis(
                  page: const HistoryScreen(),
                  settings: const RouteSettings(name: HistoryScreen.routeName),
                ),
              );
            },
            tooltip: 'History',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MD3PageTransitions.sharedAxis(
                  page: const SettingsScreen(),
                  settings: const RouteSettings(name: '/settings'),
                ),
              );
            },
            tooltip: 'Settings',
          ),
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
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MD3PageTransitions.fadeThrough(
                  page: const DownloadScreen(useBackground: true),
                  settings: const RouteSettings(name: DownloadScreen.routeName),
                ),
              );
            },
            tooltip: 'Downloads',
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
        // Search bar
        const SearchBarWidget(),

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: SemanticColors.disabled(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Search for an Internet Archive identifier',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: SemanticColors.subtitle(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'e.g., "commute_test" or "nasa_images"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SemanticColors.hint(context),
                    ),
                  ),
                ],
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
}
