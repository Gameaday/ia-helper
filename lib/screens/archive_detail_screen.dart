import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/archive_service.dart';
import '../widgets/archive_info_widget.dart';
import '../widgets/file_list_widget.dart';
import '../widgets/download_controls_widget.dart';
import '../widgets/download_manager_widget.dart';
import '../widgets/favorite_button.dart';
import '../widgets/collection_picker.dart';

/// Screen showing archive details with files and download options
class ArchiveDetailScreen extends StatefulWidget {
  const ArchiveDetailScreen({super.key});

  /// Route name for navigation tracking and state restoration
  static const routeName = '/archive-detail';

  @override
  State<ArchiveDetailScreen> createState() => _ArchiveDetailScreenState();
}

class _ArchiveDetailScreenState extends State<ArchiveDetailScreen> {
  bool _isPopping = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Clear metadata when going back to search
          // Use Provider.of with listen: false for safer context access in callbacks
          final service = Provider.of<ArchiveService>(context, listen: false);
          service.clearMetadata();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<ArchiveService>(
            builder: (context, service, child) {
              return Text(
                service.currentMetadata?.identifier ?? 'Archive Details',
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
          actions: [
            Consumer<ArchiveService>(
              builder: (context, service, child) {
                final identifier = service.currentMetadata?.identifier;
                if (identifier == null) return const SizedBox.shrink();

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Favorite button
                    FavoriteButton(
                      identifier: identifier,
                      title: service.currentMetadata?.title,
                      iconSize: 24,
                    ),
                    // Collections menu
                    IconButton(
                      icon: const Icon(Icons.collections_bookmark),
                      tooltip: 'Add to collection',
                      onPressed: () => CollectionPicker.show(
                        context: context,
                        identifier: identifier,
                        title: service.currentMetadata?.title,
                        archiveOrgCollections: service.currentMetadata?.archiveOrgCollections ?? [],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Consumer<ArchiveService>(
          builder: (context, service, child) {
            // Show error state if there's an error
            if (service.error != null) {
              return _buildErrorState(context, service);
            }

            // If no metadata and not already popping, go back to search
            if (service.currentMetadata == null && !_isPopping) {
              _isPopping = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
              return const Center(child: CircularProgressIndicator());
            }

            // If we have metadata again, reset the popping flag
            if (service.currentMetadata != null && _isPopping) {
              _isPopping = false;
            }

            // Show loading if we're in the popping state but still have metadata
            if (_isPopping) {
              return const Center(child: CircularProgressIndicator());
            }

            // Adaptive layout: side-by-side on large screens, stacked on phones
            return LayoutBuilder(
              builder: (context, constraints) {
                final isLargeScreen = constraints.maxWidth >= 900;

                if (isLargeScreen) {
                  return _buildTabletLayout(service);
                } else {
                  return _buildPhoneLayout(service);
                }
              },
            );
          },
        ),
      ),
    );
  }

  /// Phone layout: Vertical stack (metadata → files → controls)
  Widget _buildPhoneLayout(ArchiveService service) {
    return Column(
      children: [
        // Archive information
        ArchiveInfoWidget(metadata: service.currentMetadata!),

        // File list (with integrated filter controls)
        Expanded(child: FileListWidget(files: service.filteredFiles)),

        // Download controls
        const DownloadControlsWidget(),

        // Active downloads manager
        const DownloadManagerWidget(),
      ],
    );
  }

  /// Tablet/Desktop layout: Side-by-side (metadata | files/controls)
  Widget _buildTabletLayout(ArchiveService service) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left sidebar: Archive metadata (30% width, scrollable)
        SizedBox(
          width: 360, // Fixed width for consistency (roughly 30% of 1200dp)
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ArchiveInfoWidget(metadata: service.currentMetadata!),
          ),
        ),

        // Vertical divider
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),

        // Right content: Files, controls, and downloads (70% width)
        Expanded(
          child: Column(
            children: [
              // File list (with integrated filter controls)
              Expanded(child: FileListWidget(files: service.filteredFiles)),

              // Download controls
              const DownloadControlsWidget(),

              // Active downloads manager
              const DownloadManagerWidget(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, ArchiveService service) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: colorScheme.error),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Archive',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              service.error ?? 'An unknown error occurred',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                final identifier = service.currentMetadata?.identifier;
                if (identifier != null) {
                  service.fetchMetadata(identifier);
                } else {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
