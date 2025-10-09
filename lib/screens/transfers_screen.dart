import 'package:flutter/material.dart';
import 'dart:async';
import 'package:internet_archive_helper/models/download_task.dart';
import 'package:internet_archive_helper/models/download_progress.dart';
import 'package:internet_archive_helper/services/download_scheduler.dart';
import 'package:internet_archive_helper/database/database_helper.dart';
import 'package:internet_archive_helper/core/utils/formatting_utils.dart';
import 'package:internet_archive_helper/utils/snackbar_helper.dart';

/// Material Design 3 Transfers screen for managing downloads (and future uploads)
///
/// Features:
/// - Status filters: Active, Completed, Failed, Cancelled
/// - Per-item controls: Pause, Resume, Cancel, Retry
/// - Real-time progress tracking with speed and ETA
/// - Reorderable queue (drag-and-drop)
/// - Bulk actions: Pause all, Resume all, Clear completed
/// - Transfer statistics dashboard
/// - Empty states with CTAs
/// - MD3 transitions and animations
class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  DownloadStatus _selectedFilter = DownloadStatus.downloading;
  final Map<String, DownloadProgress> _progressMap = {};
  final DownloadScheduler _scheduler = DownloadScheduler();
  StreamSubscription<DownloadSchedulerState>? _stateSubscription;
  StreamSubscription<Map<String, DownloadProgress>>? _progressSubscription;

  bool _isLoading = true;
  List<DownloadTask> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _subscribeToScheduler();
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _progressSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToScheduler() {
    // Listen to scheduler state changes
    _stateSubscription = _scheduler.stateStream.listen((state) {
      if (mounted) {
        _loadTasks();
      }
    });

    // Listen to progress updates
    _progressSubscription = _scheduler.progressStream.listen((progressMap) {
      if (mounted) {
        setState(() {
          _progressMap.addAll(progressMap);
        });
      }
    });
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await DatabaseHelper.instance.getDownloadTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarHelper.showError(context, e);
      }
    }
  }

  List<DownloadTask> get _filteredTasks {
    return _tasks.where((task) {
      if (_selectedFilter == DownloadStatus.downloading) {
        // Show queued, downloading, and paused in "Active" filter
        return task.status == DownloadStatus.queued ||
            task.status == DownloadStatus.downloading ||
            task.status == DownloadStatus.paused;
      }
      return task.status == _selectedFilter;
    }).toList();
  }

  Future<void> _pauseDownload(DownloadTask task) async {
    try {
      await _scheduler.pauseTask(task.id);
      await _loadTasks();
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Paused: ${task.fileName}');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e);
    }
  }

  Future<void> _resumeDownload(DownloadTask task) async {
    try {
      await _scheduler.resumeTask(task.id);
      await _loadTasks();
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Resumed: ${task.fileName}');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e);
    }
  }

  Future<void> _cancelDownload(DownloadTask task) async {
    final confirmed = await _showCancelDialog(task.fileName);
    if (!confirmed) return;

    try {
      await _scheduler.removeTask(task.id);
      await DatabaseHelper.instance.deleteDownloadTask(task.id);
      await _loadTasks();
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Cancelled: ${task.fileName}');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e);
    }
  }

  Future<void> _retryDownload(DownloadTask task) async {
    try {
      // Reset error state and resume
      final updatedTask = task.copyWith(
        status: DownloadStatus.queued,
        errorMessage: null,
        retryCount: 0,
      );
      await DatabaseHelper.instance.updateDownloadTask(updatedTask);
      await _scheduler.enqueueTask(updatedTask);
      await _loadTasks();
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Retrying: ${task.fileName}');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e);
    }
  }

  Future<bool> _showCancelDialog(String fileName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Transfer'),
          content: Text(
            'Are you sure you want to cancel "$fileName"? Partial data will be kept for resume.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _clearCompleted() async {
    try {
      // Delete tasks completed more than 24 hours ago
      await DatabaseHelper.instance.deleteOldCompletedTasks(1);
      await _loadTasks();
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Cleared completed transfers');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e);
    }
  }

  Future<void> _pauseAll() async {
    try {
      await _scheduler.pauseAll();
      await _loadTasks();
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Paused all active transfers');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e);
    }
  }

  Future<void> _resumeAll() async {
    try {
      await _scheduler.resumeAll();
      await _loadTasks();
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Resumed all paused transfers');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfers'),
        actions: [
          if (_selectedFilter == DownloadStatus.downloading &&
              _filteredTasks.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'pause_all':
                    _pauseAll();
                    break;
                  case 'resume_all':
                    _resumeAll();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'pause_all',
                  child: Row(
                    children: [
                      Icon(Icons.pause),
                      SizedBox(width: 12),
                      Text('Pause All'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'resume_all',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow),
                      SizedBox(width: 12),
                      Text('Resume All'),
                    ],
                  ),
                ),
              ],
            ),
          if (_selectedFilter == DownloadStatus.completed &&
              _filteredTasks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear completed',
              onPressed: _clearCompleted,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),

          // Transfer statistics
          if (_filteredTasks.isNotEmpty) _buildStats(theme),

          const SizedBox(height: 8),

          // Transfer list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTransferList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Active',
              isSelected: _selectedFilter == DownloadStatus.downloading,
              onSelected: () =>
                  setState(() => _selectedFilter = DownloadStatus.downloading),
              icon: Icons.downloading,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Completed',
              isSelected: _selectedFilter == DownloadStatus.completed,
              onSelected: () =>
                  setState(() => _selectedFilter = DownloadStatus.completed),
              icon: Icons.check_circle,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Failed',
              isSelected: _selectedFilter == DownloadStatus.error,
              onSelected: () =>
                  setState(() => _selectedFilter = DownloadStatus.error),
              icon: Icons.error,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Cancelled',
              isSelected: _selectedFilter == DownloadStatus.cancelled,
              onSelected: () =>
                  setState(() => _selectedFilter = DownloadStatus.cancelled),
              icon: Icons.cancel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(ThemeData theme) {
    final activeTasks = _tasks
        .where(
          (t) =>
              t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.queued,
        )
        .toList();

    if (activeTasks.isEmpty && _selectedFilter == DownloadStatus.downloading) {
      return const SizedBox.shrink();
    }

    final totalBytes = _filteredTasks.fold<int>(
      0,
      (sum, task) => sum + task.totalBytes,
    );

    final completedBytes = _filteredTasks.fold<int>(
      0,
      (sum, task) => sum + task.partialBytes,
    );

    final avgSpeed =
        _progressMap.values.fold<double>(
          0.0,
          (sum, progress) => sum + (progress.transferSpeed ?? 0),
        ) /
        (_progressMap.values.isEmpty ? 1 : _progressMap.values.length) /
        1024 /
        1024; // Convert bytes/sec to MB/sec

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.file_download,
              label: 'Transfers',
              value: '${_filteredTasks.length}',
              theme: theme,
            ),
            _StatItem(
              icon: Icons.data_usage,
              label: 'Progress',
              value: FormattingUtils.formatBytes(completedBytes),
              subtitle: 'of ${FormattingUtils.formatBytes(totalBytes)}',
              theme: theme,
            ),
            if (avgSpeed > 0)
              _StatItem(
                icon: Icons.speed,
                label: 'Speed',
                value: '${avgSpeed.toStringAsFixed(1)} MB/s',
                theme: theme,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferList(ThemeData theme) {
    if (_filteredTasks.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _filteredTasks.length,
      onReorder: _handleReorder,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        final progress = _progressMap[task.id];

        return _TransferCard(
          key: ValueKey(task.id),
          task: task,
          progress: progress,
          onPause: () => _pauseDownload(task),
          onResume: () => _resumeDownload(task),
          onCancel: () => _cancelDownload(task),
          onRetry: () => _retryDownload(task),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final (icon, title, subtitle) = _getEmptyStateContent();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 96, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  (IconData, String, String) _getEmptyStateContent() {
    switch (_selectedFilter) {
      case DownloadStatus.downloading:
        return (
          Icons.download_done,
          'No active transfers',
          'Downloads you start will appear here',
        );
      case DownloadStatus.completed:
        return (
          Icons.check_circle_outline,
          'No completed transfers',
          'Completed downloads will appear here',
        );
      case DownloadStatus.error:
        return (
          Icons.error_outline,
          'No failed transfers',
          'Downloads with errors will appear here',
        );
      case DownloadStatus.cancelled:
        return (
          Icons.cancel_outlined,
          'No cancelled transfers',
          'Cancelled downloads will appear here',
        );
      default:
        return (
          Icons.swap_vert,
          'No transfers',
          'Start a download to see it here',
        );
    }
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final task = _filteredTasks.removeAt(oldIndex);
      _filteredTasks.insert(newIndex, task);
    });

    // Update priorities in database
    try {
      for (int i = 0; i < _filteredTasks.length; i++) {
        final task = _filteredTasks[i];
        final newPriority = _filteredTasks.length - i;

        await DatabaseHelper.instance.updateDownloadTask(
          task.copyWith(priority: _mapToPriority(newPriority)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e);
    }
  }

  DownloadPriority _mapToPriority(int value) {
    if (value > 66) return DownloadPriority.high;
    if (value > 33) return DownloadPriority.normal;
    return DownloadPriority.low;
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final IconData icon;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}

/// Statistics item widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final ThemeData theme;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Transfer card widget
class _TransferCard extends StatelessWidget {
  final DownloadTask task;
  final DownloadProgress? progress;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  const _TransferCard({
    super.key,
    required this.task,
    this.progress,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File name and actions
            Row(
              children: [
                _buildStatusIcon(colorScheme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.fileName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.identifier,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildActionButton(context),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            if (task.status == DownloadStatus.downloading ||
                task.status == DownloadStatus.paused)
              _buildProgressBar(theme),

            const SizedBox(height: 8),

            // Status and details
            _buildStatusRow(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ColorScheme colorScheme) {
    final (icon, color) = _getStatusIconAndColor(colorScheme);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  (IconData, Color) _getStatusIconAndColor(ColorScheme colorScheme) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return (Icons.downloading, colorScheme.primary);
      case DownloadStatus.paused:
        return (Icons.pause_circle, colorScheme.tertiary);
      case DownloadStatus.completed:
        return (Icons.check_circle, colorScheme.primary);
      case DownloadStatus.error:
        return (Icons.error, colorScheme.error);
      case DownloadStatus.cancelled:
        return (Icons.cancel, colorScheme.onSurface.withValues(alpha: 0.6));
      default:
        return (Icons.hourglass_empty, colorScheme.secondary);
    }
  }

  Widget _buildActionButton(BuildContext context) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return IconButton(
          icon: const Icon(Icons.pause),
          tooltip: 'Pause',
          onPressed: onPause,
        );
      case DownloadStatus.paused:
      case DownloadStatus.queued:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Resume',
              onPressed: onResume,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: onCancel,
            ),
          ],
        );
      case DownloadStatus.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Retry',
              onPressed: onRetry,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Remove',
              onPressed: onCancel,
            ),
          ],
        );
      case DownloadStatus.completed:
      case DownloadStatus.cancelled:
        return IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Remove',
          onPressed: onCancel,
        );
    }
  }

  Widget _buildProgressBar(ThemeData theme) {
    final progressValue =
        progress?.progress ?? (task.partialBytes / task.totalBytes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: progressValue,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progressValue * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.labelSmall,
            ),
            Text(
              '${FormattingUtils.formatBytes(task.partialBytes)} / ${FormattingUtils.formatBytes(task.totalBytes)}',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusRow(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            _getStatusText(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getStatusColor(colorScheme),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (progress?.transferSpeed != null &&
            progress!.transferSpeed! > 0) ...[
          const SizedBox(width: 8),
          Text(
            '${(progress!.transferSpeed! / 1024 / 1024).toStringAsFixed(1)} MB/s',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ],
        if (progress?.etaSeconds != null) ...[
          const SizedBox(width: 8),
          Text(
            _formatDuration(Duration(seconds: progress!.etaSeconds!)),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  String _getStatusText() {
    switch (task.status) {
      case DownloadStatus.downloading:
        return 'Downloading...';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.error:
        return 'Error: ${task.errorMessage ?? "Unknown error"}';
      case DownloadStatus.cancelled:
        return 'Cancelled';
      case DownloadStatus.queued:
        return 'Queued';
    }
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return colorScheme.primary;
      case DownloadStatus.paused:
        return colorScheme.tertiary;
      case DownloadStatus.completed:
        return colorScheme.primary;
      case DownloadStatus.error:
        return colorScheme.error;
      case DownloadStatus.cancelled:
      case DownloadStatus.queued:
        return colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
