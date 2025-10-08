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
          },
        ),
      ),
    );
  }
}
