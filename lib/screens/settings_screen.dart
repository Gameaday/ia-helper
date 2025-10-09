import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bandwidth_preset.dart';
import '../providers/bandwidth_manager_provider.dart';
import '../services/metadata_cache.dart';
import '../services/archive_service.dart';
import '../utils/semantic_colors.dart';
import '../utils/responsive_utils.dart';
import '../widgets/cache_statistics_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();

  /// Get current download path preference
  static Future<String> getDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('download_path') ??
        '/storage/emulated/0/Download/ia-get';
  }

  /// Get concurrent downloads preference
  static Future<int> getConcurrentDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('concurrent_downloads') ?? 3;
  }

  /// Get auto-decompress preference
  static Future<bool> getAutoDecompress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_decompress') ?? false;
  }

  /// Get verify checksums preference
  static Future<bool> getVerifyChecksums() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('verify_checksums') ?? true;
  }

  /// Get show hidden files preference
  static Future<bool> getShowHiddenFiles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('show_hidden_files') ?? false;
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences _prefs;
  bool _isLoading = true;

  // Settings values
  String _downloadPath = '/storage/emulated/0/Download/ia-get';
  int _concurrentDownloads = 3;
  bool _autoDecompress = false;
  bool _verifyChecksums = true;
  bool _showHiddenFiles = false;

  // Cache settings values
  int _cacheRetentionDays = 7;
  int _cacheSyncFrequencyDays = 30;
  int _cacheMaxSizeMB = 0;
  bool _cacheAutoSync = true;
  CacheStats? _cacheStats;

  // Settings keys
  static const String _keyDownloadPath = 'download_path';
  static const String _keyConcurrentDownloads = 'concurrent_downloads';
  static const String _keyAutoDecompress = 'auto_decompress';
  static const String _keyVerifyChecksums = 'verify_checksums';
  static const String _keyShowHiddenFiles = 'show_hidden_files';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    // Load cache settings
    final cache = MetadataCache();
    final retentionDays = await cache.getRetentionPeriod();
    final syncFrequency = await cache.getSyncFrequency();
    final maxSizeMB = await cache.getMaxCacheSizeMB();
    final autoSync = await cache.isAutoSyncEnabled();
    final stats = await cache.getCacheStats();

    setState(() {
      _downloadPath = _prefs.getString(_keyDownloadPath) ?? _downloadPath;
      _concurrentDownloads =
          _prefs.getInt(_keyConcurrentDownloads) ?? _concurrentDownloads;
      _autoDecompress = _prefs.getBool(_keyAutoDecompress) ?? _autoDecompress;
      _verifyChecksums =
          _prefs.getBool(_keyVerifyChecksums) ?? _verifyChecksums;
      _showHiddenFiles =
          _prefs.getBool(_keyShowHiddenFiles) ?? _showHiddenFiles;

      // Cache settings
      _cacheRetentionDays = retentionDays.inDays;
      _cacheSyncFrequencyDays = syncFrequency.inDays;
      _cacheMaxSizeMB = maxSizeMB;
      _cacheAutoSync = autoSync;
      _cacheStats = stats;

      _isLoading = false;
    });
  }

  Future<void> _saveDownloadPath(String value) async {
    await _prefs.setString(_keyDownloadPath, value);
    setState(() {
      _downloadPath = value;
    });
  }

  Future<void> _saveConcurrentDownloads(int value) async {
    await _prefs.setInt(_keyConcurrentDownloads, value);
    setState(() {
      _concurrentDownloads = value;
    });
  }

  Future<void> _saveAutoDecompress(bool value) async {
    await _prefs.setBool(_keyAutoDecompress, value);
    setState(() {
      _autoDecompress = value;
    });
  }

  Future<void> _saveVerifyChecksums(bool value) async {
    await _prefs.setBool(_keyVerifyChecksums, value);
    setState(() {
      _verifyChecksums = value;
    });
  }

  Future<void> _saveShowHiddenFiles(bool value) async {
    await _prefs.setBool(_keyShowHiddenFiles, value);
    setState(() {
      _showHiddenFiles = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    // For tablets, constrain content width for better readability
    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            children: [
              // Download Settings Section
              _buildSectionHeader('Download Settings'),

              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Download Location'),
                subtitle: Text(_downloadPath),
                trailing: const Icon(Icons.edit),
                onTap: _showDownloadPathDialog,
              ),

              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Concurrent Downloads'),
                subtitle: Text('$_concurrentDownloads files at a time'),
                trailing: SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        tooltip: 'Decrease concurrent downloads',
                        onPressed: _concurrentDownloads > 1
                            ? () => _saveConcurrentDownloads(
                                _concurrentDownloads - 1,
                              )
                            : null,
                      ),
                      Text('$_concurrentDownloads'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Increase concurrent downloads',
                        onPressed: _concurrentDownloads < 10
                            ? () => _saveConcurrentDownloads(
                                _concurrentDownloads + 1,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              SwitchListTile(
                secondary: const Icon(Icons.archive),
                title: const Text('Auto-decompress Archives'),
                subtitle: const Text(
                  'Automatically extract ZIP, TAR, and other archives',
                ),
                value: _autoDecompress,
                onChanged: _saveAutoDecompress,
              ),

              SwitchListTile(
                secondary: const Icon(Icons.verified),
                title: const Text('Verify Checksums'),
                subtitle: const Text(
                  'Verify MD5/SHA1 checksums after download',
                ),
                value: _verifyChecksums,
                onChanged: _saveVerifyChecksums,
              ),

              const Divider(),

              // Bandwidth Settings Section
              _buildSectionHeader('Bandwidth & Speed'),

              ListTile(
                leading: const Icon(Icons.speed),
                title: Row(
                  children: [
                    const Text('Bandwidth Limit'),
                    const SizedBox(width: 8),
                    Tooltip(
                      message:
                          'Control download speed to save data and be a good citizen',
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                subtitle: const Text(
                  'Tap to configure speed limits',
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  _showBandwidthDialog(context);
                },
              ),

              const Divider(),

              // File Browser Settings Section
              _buildSectionHeader('File Browser'),

              SwitchListTile(
                secondary: const Icon(Icons.visibility),
                title: const Text('Show Hidden Files'),
                subtitle: const Text('Show files starting with . or _'),
                value: _showHiddenFiles,
                onChanged: _saveShowHiddenFiles,
              ),

              const Divider(),

              // Cache Settings Section
              _buildSectionHeader('Offline Cache'),

              // Cache Statistics Card with enhanced widget
              if (_cacheStats != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: CacheStatisticsWidget(
                    stats: _cacheStats!,
                    onClearCache: _showClearAllCacheDialog,
                    onPurgeStale: _purgeStaleCaches,
                  ),
                ),

              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Cache Retention Period'),
                subtitle: Text('$_cacheRetentionDays days'),
                trailing: const Icon(Icons.edit),
                onTap: _showRetentionPeriodDialog,
              ),

              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Sync Frequency'),
                subtitle: Text(_getSyncFrequencyLabel(_cacheSyncFrequencyDays)),
                trailing: const Icon(Icons.edit),
                onTap: _showSyncFrequencyDialog,
              ),

              ListTile(
                leading: const Icon(Icons.data_usage),
                title: const Text('Max Cache Size'),
                subtitle: Text(
                  _cacheMaxSizeMB == 0 ? 'Unlimited' : '$_cacheMaxSizeMB MB',
                ),
                trailing: const Icon(Icons.edit),
                onTap: _showMaxCacheSizeDialog,
              ),

              SwitchListTile(
                secondary: const Icon(Icons.cloud_sync),
                title: const Text('Auto-Sync'),
                subtitle: const Text('Automatically sync stale metadata'),
                value: _cacheAutoSync,
                onChanged: _saveCacheAutoSync,
              ),

              const SizedBox(height: 8),

              // Cache Management Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _refreshCacheStats,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Stats'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _purgeStaleCaches,
                            icon: const Icon(Icons.cleaning_services),
                            label: const Text('Purge Stale'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearUnpinnedCache,
                            icon: const Icon(Icons.delete_sweep),
                            label: const Text('Clear Unpinned'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _vacuumDatabase,
                            icon: const Icon(Icons.compress),
                            label: const Text('Vacuum DB'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showClearAllCacheDialog,
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Clear All Cache'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onError,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Reset Settings
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: _showResetDialog,
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset to Defaults'),
                ),
              ),

              const SizedBox(height: 32),
            ],
          );

    // Wrap content with responsive constraints for tablets
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ResponsiveUtils.isTabletOrLarger(context)
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: content,
              ),
            )
          : content,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: Theme.of(context).primaryColor),
      ),
    );
  }

  void _showDownloadPathDialog() {
    final controller = TextEditingController(text: _downloadPath);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Path',
                hintText: '/storage/emulated/0/Download/ia-get',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Downloads will be saved to this directory',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: SemanticColors.hint(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final path = controller.text.trim();
              if (path.isNotEmpty) {
                _saveDownloadPath(path);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Capture context-dependent objects before async operations
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              // Clear all preferences
              await _prefs.clear();

              // Reset to default values immediately
              setState(() {
                _downloadPath = '/storage/emulated/0/Download/ia-get';
                _concurrentDownloads = 3;
                _autoDecompress = false;
                _verifyChecksums = true;
                _showHiddenFiles = false;
              });

              if (!mounted) return;

              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showBandwidthDialog(BuildContext context) {
    // Try to get the BandwidthManagerProvider if it exists
    BandwidthManagerProvider? bandwidthProvider;
    try {
      bandwidthProvider = Provider.of<BandwidthManagerProvider>(
        context,
        listen: false,
      );
    } catch (e) {
      // Provider not available, use local state
    }

    BandwidthPreset selectedPreset = bandwidthProvider?.currentPreset ?? BandwidthPreset.unlimited;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Bandwidth Limit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Control download speed to save data and be a good Internet Archive citizen',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                // Custom radio selection to avoid deprecated API
                ...BandwidthPreset.values.map((preset) {
                  final isSelected = selectedPreset == preset;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedPreset = preset;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      margin: const EdgeInsets.only(bottom: 8.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Custom radio indicator
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(preset.icon),
                                    const SizedBox(width: 8),
                                    Text(
                                      preset.displayName,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  preset.description,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                // Save the selected preset
                if (bandwidthProvider != null) {
                  bandwidthProvider.changePreset(selectedPreset);
                }
                
                // Also save to SharedPreferences for persistence
                _prefs.setInt('bandwidth_preset', selectedPreset.bytesPerSecond);
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Bandwidth limit set to ${selectedPreset.displayName}',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  // Cache Settings Methods

  String _getSyncFrequencyLabel(int days) {
    if (days == 1) return 'Daily';
    if (days == 7) return 'Weekly';
    if (days == 30) return 'Monthly';
    if (days == 0) return 'Manual only';
    return '$days days';
  }

  Future<void> _saveCacheAutoSync(bool value) async {
    final cache = MetadataCache();
    await cache.setAutoSyncEnabled(value);
    setState(() {
      _cacheAutoSync = value;
    });
  }

  Future<void> _refreshCacheStats() async {
    final cache = MetadataCache();
    final stats = await cache.getCacheStats();
    setState(() {
      _cacheStats = stats;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cache: ${stats.totalArchives} archives, ${stats.formattedDataSize}',
          ),
        ),
      );
    }
  }

  Future<void> _purgeStaleCaches() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Purging stale caches...'),
          ],
        ),
      ),
    );

    try {
      final archiveService = Provider.of<ArchiveService>(
        context,
        listen: false,
      );
      final purgedCount = await archiveService.purgeStaleCaches();

      // Refresh stats
      await _refreshCacheStats();

      if (!mounted) return;
      navigator.pop(); // Close progress dialog

      messenger.showSnackBar(
        SnackBar(content: Text('Purged $purgedCount stale cache entries')),
      );
    } catch (e) {
      if (!mounted) return;
      navigator.pop(); // Close progress dialog

      messenger.showSnackBar(
        SnackBar(
          content: Text('Error purging cache: $e'),
          backgroundColor: SemanticColors.error(context),
        ),
      );
    }
  }

  Future<void> _clearUnpinnedCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Unpinned Cache'),
        content: const Text(
          'Remove all unpinned cache entries. Pinned and downloaded archives will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final errorColor = SemanticColors.error(context);

              navigator.pop(); // Close dialog

              // Show progress
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Clearing unpinned cache...'),
                    ],
                  ),
                ),
              );

              try {
                final cache = MetadataCache();
                final count = await cache.clearUnpinnedCache();

                // Refresh stats
                await _refreshCacheStats();

                if (!mounted) return;
                navigator.pop(); // Close progress dialog

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Cleared $count unpinned cache entries'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                navigator.pop(); // Close progress dialog

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error clearing cache: $e'),
                    backgroundColor: errorColor,
                  ),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _vacuumDatabase() async {
    final messenger = ScaffoldMessenger.of(context);

    // Show progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Vacuuming database...'),
          ],
        ),
      ),
    );

    try {
      final cache = MetadataCache();
      await cache.vacuum();

      // Refresh stats
      await _refreshCacheStats();

      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress dialog

      messenger.showSnackBar(
        const SnackBar(content: Text('Database vacuumed successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress dialog

      messenger.showSnackBar(
        SnackBar(
          content: Text('Error vacuuming database: $e'),
          backgroundColor: SemanticColors.error(context),
        ),
      );
    }
  }

  void _showClearAllCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Cache'),
        content: const Text(
          'This will remove ALL cached metadata including pinned archives. '
          'Downloaded files will NOT be affected.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final errorColor = SemanticColors.error(context);

              navigator.pop(); // Close dialog

              // Show progress
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Clearing all cache...'),
                    ],
                  ),
                ),
              );

              try {
                final archiveService = Provider.of<ArchiveService>(
                  context,
                  listen: false,
                );
                await archiveService.clearAllCache();

                // Refresh stats
                await _refreshCacheStats();

                if (!mounted) return;
                navigator.pop(); // Close progress dialog

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('All cache cleared successfully'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                navigator.pop(); // Close progress dialog

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error clearing cache: $e'),
                    backgroundColor: errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showRetentionPeriodDialog() {
    int selectedDays = _cacheRetentionDays;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cache Retention Period'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Unpinned and non-downloaded archives will be purged after $selectedDays days of inactivity.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: SemanticColors.subtitle(context),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: selectedDays.toDouble(),
                      min: 1,
                      max: 90,
                      divisions: 89,
                      label: '$selectedDays days',
                      onChanged: (value) {
                        setDialogState(() {
                          selectedDays = value.toInt();
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '$selectedDays days',
                      style: Theme.of(context).textTheme.labelLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('1 day'),
                    selected: selectedDays == 1,
                    onSelected: (selected) {
                      setDialogState(() {
                        selectedDays = 1;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('7 days'),
                    selected: selectedDays == 7,
                    onSelected: (selected) {
                      setDialogState(() {
                        selectedDays = 7;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('30 days'),
                    selected: selectedDays == 30,
                    onSelected: (selected) {
                      setDialogState(() {
                        selectedDays = 30;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('90 days'),
                    selected: selectedDays == 90,
                    onSelected: (selected) {
                      setDialogState(() {
                        selectedDays = 90;
                      });
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
            ElevatedButton(
              onPressed: () async {
                final cache = MetadataCache();
                await cache.setRetentionPeriod(selectedDays);
                setState(() {
                  _cacheRetentionDays = selectedDays;
                });
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncFrequencyDialog() {
    int selectedDays = _cacheSyncFrequencyDays;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sync Frequency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cached metadata will be synced from the Internet Archive after $selectedDays days.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: SemanticColors.subtitle(context),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Manual only'),
                    selected: selectedDays == 0,
                    onSelected: (selected) {
                      setDialogState(() {
                        selectedDays = 0;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Daily'),
                    selected: selectedDays == 1,
                    onSelected: (selected) {
                      setDialogState(() {
                        selectedDays = 1;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Weekly'),
                    selected: selectedDays == 7,
                    onSelected: (selected) {
                      setDialogState(() {
                        selectedDays = 7;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Monthly'),
                    selected: selectedDays == 30,
                    onSelected: (selected) {
                      setDialogState(() {
                        selectedDays = 30;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Quarterly'),
                    selected: selectedDays == 90,
                    onSelected: (selected) {
                      setDialogState(() {
                        selectedDays = 90;
                      });
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
            ElevatedButton(
              onPressed: () async {
                final cache = MetadataCache();
                await cache.setSyncFrequency(selectedDays);
                setState(() {
                  _cacheSyncFrequencyDays = selectedDays;
                });
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMaxCacheSizeDialog() {
    final controller = TextEditingController(
      text: _cacheMaxSizeMB == 0 ? '' : _cacheMaxSizeMB.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Max Cache Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Size in MB (0 = unlimited)',
                hintText: '0',
                border: OutlineInputBorder(),
                suffixText: 'MB',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Set to 0 for unlimited cache size. When limit is reached, '
              'oldest unpinned entries will be purged.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: SemanticColors.hint(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              final sizeMB = int.tryParse(text) ?? 0;
              if (sizeMB >= 0) {
                final cache = MetadataCache();
                await cache.setMaxCacheSizeMB(sizeMB);
                setState(() {
                  _cacheMaxSizeMB = sizeMB;
                });
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
