import 'package:flutter/material.dart';
import '../services/metadata_cache.dart';
import '../services/local_archive_storage.dart';
import '../widgets/cache_statistics_widget.dart';
import '../utils/responsive_utils.dart';
import '../core/navigation/navigation_state.dart';
import 'package:provider/provider.dart';
import '../utils/snackbar_helper.dart';

/// Data & Storage management screen
///
/// Provides comprehensive storage management including:
/// - Cache statistics and controls
/// - Downloaded archives management
/// - Storage usage breakdown
/// - Clear cache and data options
class DataStorageScreen extends StatefulWidget {
  const DataStorageScreen({super.key});

  static const String routeName = '/data-storage';

  @override
  State<DataStorageScreen> createState() => _DataStorageScreenState();
}

class _DataStorageScreenState extends State<DataStorageScreen> {
  bool _isLoading = true;
  CacheStats? _cacheStats;
  int _downloadedArchivesCount = 0;
  int _cacheRetentionDays = 7;
  int _cacheSyncFrequencyDays = 30;
  int _cacheMaxSizeMB = 0;
  bool _cacheAutoSync = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final cache = MetadataCache();
    final storage = context.read<LocalArchiveStorage>();

    final stats = await cache.getCacheStats();
    final archives = storage.archives;
    final retentionDays = await cache.getRetentionPeriod();
    final syncFrequency = await cache.getSyncFrequency();
    final maxSizeMB = await cache.getMaxCacheSizeMB();
    final autoSync = await cache.isAutoSyncEnabled();

    setState(() {
      _cacheStats = stats;
      _downloadedArchivesCount = archives.length;
      _cacheRetentionDays = retentionDays.inDays;
      _cacheSyncFrequencyDays = syncFrequency.inDays;
      _cacheMaxSizeMB = maxSizeMB;
      _cacheAutoSync = autoSync;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Storage Overview
              _buildStorageOverview(context),
              const SizedBox(height: 24),

              // Cache Management
              _buildSectionHeader('Cache Management'),
              const SizedBox(height: 12),
              if (_cacheStats != null)
                CacheStatisticsWidget(
                  stats: _cacheStats!,
                  onClearCache: _showClearCacheDialog,
                  onPurgeStale: _showPurgeStaleDialog,
                ),
              const SizedBox(height: 24),

              // Cache Settings
              _buildSectionHeader('Cache Settings'),
              const SizedBox(height: 12),
              _buildCacheSettings(context),
              const SizedBox(height: 24),

              // Downloaded Archives
              _buildSectionHeader('Downloaded Archives'),
              const SizedBox(height: 12),
              _buildDownloadedArchives(context),
              const SizedBox(height: 24),

              // Danger Zone
              _buildSectionHeader('Danger Zone'),
              const SizedBox(height: 12),
              _buildDangerZone(context),
            ],
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Data & Storage')),
      body: ResponsiveUtils.isTabletOrLarger(context)
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: content,
              ),
            )
          : content,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildStorageOverview(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalSize =
        (_cacheStats?.totalDataSize ?? 0) + (_cacheStats?.databaseSize ?? 0);
    final totalCacheSizeMB = totalSize / (1024 * 1024);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.storage,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Storage Usage',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalCacheSizeMB.toStringAsFixed(1)} MB used',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              icon: Icons.description,
              label: 'Cached Metadata',
              value: '${_cacheStats?.totalArchives ?? 0} items',
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              context,
              icon: Icons.push_pin,
              label: 'Pinned Archives',
              value: '${_cacheStats?.pinnedArchives ?? 0} items',
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              context,
              icon: Icons.download_done,
              label: 'Downloaded Archives',
              value: '$_downloadedArchivesCount items',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCacheSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.timelapse),
            title: const Text('Cache Retention'),
            subtitle: Text('$_cacheRetentionDays days'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRetentionDialog(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Auto-Sync Frequency'),
            subtitle: Text('Every $_cacheSyncFrequencyDays days'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSyncFrequencyDialog(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.disc_full),
            title: const Text('Max Cache Size'),
            subtitle: Text(
              _cacheMaxSizeMB == 0 ? 'Unlimited' : '$_cacheMaxSizeMB MB',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMaxSizeDialog(),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.cloud_sync),
            title: const Text('Auto-Sync Enabled'),
            subtitle: const Text('Automatically sync cache in background'),
            value: _cacheAutoSync,
            onChanged: (value) async {
              final cache = MetadataCache();
              await cache.setAutoSyncEnabled(value);
              setState(() => _cacheAutoSync = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadedArchives(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.folder),
        title: const Text('Manage Downloaded Files'),
        subtitle: Text('$_downloadedArchivesCount archives downloaded'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to Library tab (tab index 1)
          if (context.mounted) {
            // Pop back to main navigation
            Navigator.of(context).popUntil((route) => route.isFirst);
            // Switch to Library tab
            context.read<NavigationState>().changeTab(1);
          }
        },
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Card(
      color: Theme.of(
        context,
      ).colorScheme.errorContainer.withValues(alpha: 0.1),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.delete_sweep,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Clear All Cache',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text('Remove all cached metadata and previews'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showClearAllDialog,
          ),
        ],
      ),
    );
  }

  Future<void> _showClearCacheDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all unpinned cached metadata. '
          'Pinned archives will be kept. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final cache = MetadataCache();
      await cache.clearUnpinnedCache();
      _loadData();
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Cache cleared successfully');
    }
  }

  Future<void> _showPurgeStaleDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purge Stale Entries'),
        content: const Text(
          'This will remove cached entries older than the retention period. '
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Purge'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final cache = MetadataCache();
      final removed = await cache.purgeStaleCaches();
      _loadData();
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Removed $removed stale entries');
    }
  }

  Future<void> _showClearAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: const Text('Clear All Data'),
        content: const Text(
          'This will remove ALL cached data including pinned archives. '
          'This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final cache = MetadataCache();
      await cache.clearAllCache();
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All cache cleared')));
      }
    }
  }

  Future<void> _showRetentionDialog() async {
    final days = await showDialog<int>(
      context: context,
      builder: (context) => _NumberPickerDialog(
        title: 'Cache Retention Period',
        label: 'Days to keep cached data',
        initialValue: _cacheRetentionDays,
        minValue: 1,
        maxValue: 365,
      ),
    );

    if (days != null && mounted) {
      final cache = MetadataCache();
      await cache.setRetentionPeriod(days);
      setState(() => _cacheRetentionDays = days);
    }
  }

  Future<void> _showSyncFrequencyDialog() async {
    final days = await showDialog<int>(
      context: context,
      builder: (context) => _NumberPickerDialog(
        title: 'Auto-Sync Frequency',
        label: 'Days between automatic syncs',
        initialValue: _cacheSyncFrequencyDays,
        minValue: 1,
        maxValue: 90,
      ),
    );

    if (days != null && mounted) {
      final cache = MetadataCache();
      await cache.setSyncFrequency(days);
      setState(() => _cacheSyncFrequencyDays = days);
    }
  }

  Future<void> _showMaxSizeDialog() async {
    final sizeMB = await showDialog<int>(
      context: context,
      builder: (context) => _NumberPickerDialog(
        title: 'Maximum Cache Size',
        label: 'Max size in MB (0 for unlimited)',
        initialValue: _cacheMaxSizeMB,
        minValue: 0,
        maxValue: 10000,
        step: 100,
      ),
    );

    if (sizeMB != null && mounted) {
      final cache = MetadataCache();
      await cache.setMaxCacheSizeMB(sizeMB);
      setState(() => _cacheMaxSizeMB = sizeMB);
    }
  }
}

/// Simple number picker dialog
class _NumberPickerDialog extends StatefulWidget {
  final String title;
  final String label;
  final int initialValue;
  final int minValue;
  final int maxValue;
  final int step;

  const _NumberPickerDialog({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    this.step = 1,
  });

  @override
  State<_NumberPickerDialog> createState() => _NumberPickerDialogState();
}

class _NumberPickerDialogState extends State<_NumberPickerDialog> {
  late TextEditingController _controller;
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _controller = TextEditingController(text: _value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null &&
                  parsed >= widget.minValue &&
                  parsed <= widget.maxValue) {
                _value = parsed;
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (_value > widget.minValue) {
                    setState(() {
                      _value -= widget.step;
                      _controller.text = _value.toString();
                    });
                  }
                },
              ),
              Expanded(
                child: Slider(
                  value: _value.toDouble(),
                  min: widget.minValue.toDouble(),
                  max: widget.maxValue.toDouble(),
                  divisions: ((widget.maxValue - widget.minValue) / widget.step)
                      .round(),
                  label: _value.toString(),
                  onChanged: (value) {
                    setState(() {
                      _value = (value / widget.step).round() * widget.step;
                      _controller.text = _value.toString();
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (_value < widget.maxValue) {
                    setState(() {
                      _value += widget.step;
                      _controller.text = _value.toString();
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _value),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
