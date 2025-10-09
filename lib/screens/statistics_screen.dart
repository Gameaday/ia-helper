import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/local_archive_storage.dart';
import '../utils/file_utils.dart';

/// Screen displaying comprehensive app usage statistics
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;

  // Download statistics
  int _totalDownloads = 0;
  int _totalBytes = 0;
  int _successfulDownloads = 0;
  int _failedDownloads = 0;
  int _inProgressDownloads = 0;

  // Search statistics
  int _totalSearches = 0;
  List<String> _topSearchTerms = [];

  // Library statistics
  int _totalFavorites = 0;
  int _totalCollections = 0;
  int _savedSearches = 0;

  // Storage statistics
  int _downloadedArchives = 0;
  int _downloadedBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;

      // Load download statistics
      final downloads = await db.query('download_history');
      _totalDownloads = downloads.length;

      int totalBytes = 0;
      int successful = 0;
      int failed = 0;
      int inProgress = 0;

      for (final download in downloads) {
        final status = download['status'] as String?;
        final fileSize = download['total_bytes'] as int? ?? 0;

        totalBytes += fileSize;

        if (status == 'completed') {
          successful++;
        } else if (status == 'failed' || status == 'error') {
          failed++;
        } else if (status == 'downloading' ||
            status == 'queued' ||
            status == 'paused') {
          inProgress++;
        }
      }

      _totalBytes = totalBytes;
      _successfulDownloads = successful;
      _failedDownloads = failed;
      _inProgressDownloads = inProgress;

      // Load search statistics
      final searches = await db.query(
        'search_history',
        orderBy: 'timestamp DESC',
      );
      _totalSearches = searches.length;

      // Get top search terms (count frequency)
      final termCounts = <String, int>{};
      for (final search in searches) {
        final query = search['query'] as String? ?? '';
        if (query.isNotEmpty) {
          termCounts[query] = (termCounts[query] ?? 0) + 1;
        }
      }

      final sortedTerms = termCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _topSearchTerms = sortedTerms
          .take(5)
          .map((e) => '${e.key} (${e.value})')
          .toList();

      // Load library statistics
      final favorites = await db.query('favorites');
      _totalFavorites = favorites.length;

      final collections = await db.query('collections');
      _totalCollections = collections.length;

      final savedSearches = await db.query('saved_searches');
      _savedSearches = savedSearches.length;

      // Load downloaded archives statistics
      final storage = LocalArchiveStorage();
      _downloadedArchives = storage.archives.length;

      int downloadedBytes = 0;
      for (final archive in storage.archives.values) {
        downloadedBytes += archive.totalBytes;
      }
      _downloadedBytes = downloadedBytes;
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildDownloadStatistics(context),
                  const SizedBox(height: 16),
                  _buildSearchStatistics(context),
                  const SizedBox(height: 16),
                  _buildLibraryStatistics(context),
                  const SizedBox(height: 16),
                  _buildStorageStatistics(context),
                  const SizedBox(height: 16),
                  _buildLastUpdated(context),
                ],
              ),
            ),
    );
  }

  Widget _buildDownloadStatistics(BuildContext context) {
    final successRate = _totalDownloads > 0
        ? (_successfulDownloads / _totalDownloads * 100).toStringAsFixed(1)
        : '0.0';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.download_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Downloads',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              'Total Downloads',
              _totalDownloads.toString(),
              Icons.download_done_rounded,
            ),
            const Divider(height: 24),
            _buildStatRow(
              context,
              'Successful',
              _successfulDownloads.toString(),
              Icons.check_circle_outline_rounded,
              color: Colors.green,
            ),
            const Divider(height: 24),
            _buildStatRow(
              context,
              'Failed',
              _failedDownloads.toString(),
              Icons.error_outline_rounded,
              color: Colors.red,
            ),
            const Divider(height: 24),
            _buildStatRow(
              context,
              'In Progress',
              _inProgressDownloads.toString(),
              Icons.hourglass_empty_rounded,
              color: Colors.orange,
            ),
            const Divider(height: 24),
            _buildStatRow(
              context,
              'Success Rate',
              '$successRate%',
              Icons.percent_rounded,
            ),
            const Divider(height: 24),
            _buildStatRow(
              context,
              'Total Data Downloaded',
              FileUtils.formatBytes(_totalBytes),
              Icons.storage_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchStatistics(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Search Activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              'Total Searches',
              _totalSearches.toString(),
              Icons.search_rounded,
            ),
            if (_topSearchTerms.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Top Search Terms',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._topSearchTerms.map(
                (term) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Icon(
                        Icons.trending_up_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          term,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryStatistics(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.library_books_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('Library', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              'Favorites',
              _totalFavorites.toString(),
              Icons.favorite_rounded,
            ),
            const Divider(height: 24),
            _buildStatRow(
              context,
              'Collections',
              _totalCollections.toString(),
              Icons.collections_bookmark_rounded,
            ),
            const Divider(height: 24),
            _buildStatRow(
              context,
              'Saved Searches',
              _savedSearches.toString(),
              Icons.bookmark_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageStatistics(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('Storage', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              'Downloaded Archives',
              _downloadedArchives.toString(),
              Icons.archive_rounded,
            ),
            const Divider(height: 24),
            _buildStatRow(
              context,
              'Storage Used',
              FileUtils.formatBytes(_downloadedBytes),
              Icons.folder_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLastUpdated(BuildContext context) {
    return Center(
      child: Text(
        'Pull down to refresh statistics',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
