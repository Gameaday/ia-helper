import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:open_file/open_file.dart';
import '../providers/download_provider.dart';
import '../services/background_download_service.dart';
import '../services/archive_service.dart';
import '../models/download_progress.dart' as progress_model;
import '../utils/file_utils.dart';
import '../utils/permission_utils.dart';
import '../utils/semantic_colors.dart';
import '../utils/responsive_utils.dart';
import '../widgets/bandwidth_controls_widget.dart';
import '../widgets/priority_selector.dart';
import '../widgets/enhanced_progress_card.dart';
import '../widgets/rate_limit_indicator.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key, this.useBackground = false});

  /// When true, show downloads from BackgroundDownloadService instead of DownloadProvider
  final bool useBackground;

  /// Route name for navigation tracking
  static const routeName = '/downloads';

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  // Track expanded state for each download
  final Map<String, bool> _expandedDownloads = {};

  @override
  Widget build(BuildContext context) {
    // Show background service downloads or provider downloads based on flag
    if (widget.useBackground) {
      return _buildBackgroundView();
    }
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, child) {
        final downloads = downloadProvider.downloads;
        final activeDownloads = downloads.values
            .where((d) => d.downloadStatus.isActive)
            .toList();
        final completedDownloads = downloads.values
            .where((d) => d.downloadStatus == DownloadStatus.complete)
            .toList();

        return PopScope(
          canPop: true,
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  const Text('Downloads'),
                  if (downloadProvider.activeDownloadCount > 0 ||
                      downloadProvider.queuedDownloadCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '(${downloadProvider.activeDownloadCount} active'
                        '${downloadProvider.queuedDownloadCount > 0 ? ', ${downloadProvider.queuedDownloadCount} queued' : ''})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: SemanticColors.subtitle(context),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                if (downloads.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'Clear all downloads',
                    onPressed: () => _clearAllDownloads(downloadProvider),
                  ),
              ],
            ),
            body: downloads.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.download_outlined,
                            size: 80,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No downloads yet',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: SemanticColors.subtitle(context),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Start exploring and downloading files\nfrom the Internet Archive',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: SemanticColors.hint(context)),
                          ),
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                            },
                            icon: const Icon(Icons.search),
                            label: const Text('Start Exploring'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ResponsiveUtils.isTabletOrLarger(context)
                ? _buildTwoColumnLayout(
                    activeDownloads,
                    completedDownloads,
                    downloadProvider,
                  )
                : _buildSingleColumnLayout(
                    activeDownloads,
                    completedDownloads,
                    downloadProvider,
                  ),
          ),
        );
      },
    );
  }

  /// Build single column layout for phones (original layout)
  Widget _buildSingleColumnLayout(
    List<DownloadState> activeDownloads,
    List<DownloadState> completedDownloads,
    DownloadProvider downloadProvider,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Bandwidth controls at the top
        const BandwidthControlsWidget(),
        const SizedBox(height: 12),

        // Rate limit indicator (shows when rate limiting is active)
        Consumer<ArchiveService>(
          builder: (context, archiveService, _) {
            final rateLimitStatus = archiveService.getRateLimitStatus();
            return RateLimitIndicator(
              status: rateLimitStatus,
              showDetails: false,
            );
          },
        ),
        const SizedBox(height: 24),

        if (activeDownloads.isNotEmpty) ...[
          Text(
            'Active Downloads',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...activeDownloads.map(
            (state) => _buildActiveDownloadCard(state, downloadProvider),
          ),
          const SizedBox(height: 24),
        ],
        if (completedDownloads.isNotEmpty) ...[
          Text(
            'Completed Downloads',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...completedDownloads.map(
            (state) => _buildCompletedDownloadCard(state, downloadProvider),
          ),
        ],
      ],
    );
  }

  /// Build two-column layout for tablets (active left, completed right)
  Widget _buildTwoColumnLayout(
    List<DownloadState> activeDownloads,
    List<DownloadState> completedDownloads,
    DownloadProvider downloadProvider,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: Active downloads
        Expanded(
          child: ListView(
            padding: ResponsiveUtils.getScreenPadding(context),
            children: [
              // Bandwidth controls at the top
              const BandwidthControlsWidget(),
              const SizedBox(height: 12),

              // Rate limit indicator
              Consumer<ArchiveService>(
                builder: (context, archiveService, _) {
                  final rateLimitStatus = archiveService.getRateLimitStatus();
                  return RateLimitIndicator(
                    status: rateLimitStatus,
                    showDetails: false,
                  );
                },
              ),
              const SizedBox(height: 24),

              Text(
                'Active Downloads',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (activeDownloads.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.download_done,
                          size: 48,
                          color: SemanticColors.disabled(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No active downloads',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: SemanticColors.subtitle(context),
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...activeDownloads.map(
                  (state) => _buildActiveDownloadCard(state, downloadProvider),
                ),
            ],
          ),
        ),

        // Divider
        Container(width: 1, color: Theme.of(context).dividerColor),

        // Right column: Completed downloads
        Expanded(
          child: ListView(
            padding: ResponsiveUtils.getScreenPadding(context),
            children: [
              Text(
                'Completed Downloads',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (completedDownloads.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 48,
                          color: SemanticColors.disabled(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No completed downloads',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: SemanticColors.subtitle(context),
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...completedDownloads.map(
                  (state) =>
                      _buildCompletedDownloadCard(state, downloadProvider),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundView() {
    return Consumer<BackgroundDownloadService>(
      builder: (context, bgService, child) {
        final active = bgService.activeDownloads.values
            .where(
              (d) =>
                  d.status == progress_model.DownloadStatus.downloading ||
                  d.status == progress_model.DownloadStatus.queued ||
                  d.status == progress_model.DownloadStatus.paused,
            )
            .toList();
        final completed = bgService.completedDownloads.values.toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Downloads'),
            actions: [
              if (completed.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: () => bgService.clearCompletedDownloads(),
                ),
            ],
          ),
          body: bgService.totalDownloadCount == 0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download_done,
                        size: 64,
                        color: SemanticColors.disabled(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No downloads yet',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: SemanticColors.subtitle(context)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start downloading files from the main screen',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SemanticColors.hint(context),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (active.isNotEmpty) ...[
                      Text(
                        'Active Downloads',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ...active.map(
                        (p) =>
                            _buildActiveDownloadCardForProgress(p, bgService),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (completed.isNotEmpty) ...[
                      Text(
                        'Completed Downloads',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ...completed.map(
                        (p) => _buildCompletedDownloadCardForProgress(
                          p,
                          bgService,
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildActiveDownloadCardForProgress(
    progress_model.DownloadProgress p,
    BackgroundDownloadService svc,
  ) {
    final prog = (p.progress ?? 0.0).clamp(0.0, 1.0);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.identifier,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  tooltip: 'Cancel download',
                  onPressed: () => svc.cancelDownload(p.downloadId),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Downloading ${p.completedFiles ?? 0}/${p.totalFiles} files',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: SemanticColors.subtitle(context),
              ),
            ),
            const SizedBox(height: 12),
            LinearPercentIndicator(
              percent: prog,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              progressColor: Theme.of(context).primaryColor,
              lineHeight: 8,
              barRadius: const Radius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '${(prog * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedDownloadCardForProgress(
    progress_model.DownloadProgress p,
    BackgroundDownloadService svc,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ignore: prefer_const_constructors
            Icon(Icons.check_circle, color: SemanticColors.success, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.identifier,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${p.totalFiles} files • ${FileUtils.formatBytes(p.totalBytes ?? 0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SemanticColors.subtitle(context),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.folder_open),
              tooltip: 'Open download folder',
              onPressed: () => _openDownloadFolderForProgress(p.identifier),
            ),
          ],
        ),
      ),
    );
  }

  void _openDownloadFolderForProgress(String identifier) async {
    // Check if we have permission to access folders
    final hasPermission = await PermissionUtils.hasManageStoragePermission();

    if (!hasPermission) {
      if (!mounted) return;

      // Request permission with explanation
      final granted = await PermissionUtils.requestManageStoragePermission(
        context,
      );

      if (!granted) {
        // User denied permission
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Storage access permission is required to open folders',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    final downloadPath = '/storage/emulated/0/Download/ia-get/$identifier';
    try {
      final result = await OpenFile.open(downloadPath);
      if (mounted && result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open folder: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening folder: $e')));
      }
    }
  }

  Widget _buildActiveDownloadCard(
    DownloadState downloadState,
    DownloadProvider provider,
  ) {
    final identifier = downloadState.identifier;
    final overallProgress =
        downloadState.overallProgress / 100.0; // Convert to 0-1 range

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    identifier,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Compact priority selector
                PrioritySelector(
                  priority: downloadState.priority,
                  onChanged: (newPriority) {
                    provider.changePriority(identifier, newPriority);
                  },
                  compact: true,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.stop),
                  tooltip: 'Cancel download',
                  onPressed: () => _cancelDownload(identifier, provider),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              downloadState.downloadStatus == DownloadStatus.fetchingMetadata
                  ? 'Fetching metadata...'
                  : 'Downloading ${downloadState.fileProgress.length} files',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: SemanticColors.subtitle(context),
              ),
            ),
            const SizedBox(height: 12),
            LinearPercentIndicator(
              percent: overallProgress,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              progressColor: Theme.of(context).primaryColor,
              lineHeight: 8,
              barRadius: const Radius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(overallProgress * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  '${FileUtils.formatSize(downloadState.totalDownloaded)} / ${FileUtils.formatSize(downloadState.totalSize)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SemanticColors.subtitle(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Enhanced progress info
            EnhancedProgressCard(
              progressInfo: downloadState.getProgressInfo(),
              isExpanded: _expandedDownloads[identifier] ?? false,
              onToggleExpanded: () {
                setState(() {
                  _expandedDownloads[identifier] =
                      !(_expandedDownloads[identifier] ?? false);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedDownloadCard(
    DownloadState downloadState,
    DownloadProvider provider,
  ) {
    final identifier = downloadState.identifier;
    final fileCount = downloadState.metadata?.files.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: SemanticColors.success,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    identifier,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$fileCount files • ${FileUtils.formatSize(downloadState.totalSize)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SemanticColors.subtitle(context),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.folder_open),
              tooltip: 'Open download folder',
              onPressed: () => _openDownloadFolder(identifier),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Clear from list',
              onPressed: () => provider.clearDownload(identifier),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelDownload(String identifier, DownloadProvider provider) async {
    try {
      await provider.cancelDownload(identifier);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download cancelled')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
      }
    }
  }

  void _clearAllDownloads(DownloadProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Downloads'),
        content: const Text('Are you sure you want to clear all downloads?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearCompletedDownloads();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _openDownloadFolder(String identifier) async {
    // Check if we have permission to access folders
    final hasPermission = await PermissionUtils.hasManageStoragePermission();

    if (!hasPermission) {
      if (!mounted) return;

      // Request permission with explanation
      final granted = await PermissionUtils.requestManageStoragePermission(
        context,
      );

      if (!granted) {
        // User denied permission
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Storage access permission is required to open folders',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    // Try to open the download folder
    final downloadPath = '/storage/emulated/0/Download/ia-get/$identifier';

    try {
      final result = await OpenFile.open(downloadPath);
      if (mounted && result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open folder: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening folder: $e')));
      }
    }
  }
}
