import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bandwidth_manager_provider.dart';
import '../models/bandwidth_preset.dart';

/// Widget for controlling bandwidth limits with preset selection
class BandwidthControlsWidget extends StatelessWidget {
  const BandwidthControlsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BandwidthManagerProvider>(
      builder: (context, bandwidthManager, child) {
        final usage = bandwidthManager.usage;
        final currentPreset = bandwidthManager.currentPreset;

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildPresetSelector(context, bandwidthManager, currentPreset),
                if (bandwidthManager.isLimitEnabled) ...[
                  const SizedBox(height: 16),
                  _buildUsageDisplay(context, usage),
                  const SizedBox(height: 12),
                  _buildStatistics(context, usage),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.speed_rounded, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          'Bandwidth Limit',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Tooltip(
          message: 'Control download speed to be a good citizen',
          child: Icon(
            Icons.info_outline,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetSelector(
    BuildContext context,
    BandwidthManagerProvider manager,
    BandwidthPreset currentPreset,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Speed:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BandwidthPreset.values.map((preset) {
            final isSelected = preset == currentPreset;
            return _buildPresetChip(context, manager, preset, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPresetChip(
    BuildContext context,
    BandwidthManagerProvider manager,
    BandwidthPreset preset,
    bool isSelected,
  ) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(preset.icon),
          const SizedBox(width: 4),
          Text(preset.displayName),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          manager.changePreset(preset);
        }
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
      tooltip: preset.description,
    );
  }

  Widget _buildUsageDisplay(BuildContext context, BandwidthUsage usage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current Usage:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${usage.currentSpeedDisplay} / ${usage.maxSpeedDisplay}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: usage.isNearLimit
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: usage.usagePercentage,
            minHeight: 8,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              usage.isNearLimit
                  ? Theme.of(context).colorScheme.error
                  : usage.isThrottled
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(BuildContext context, BandwidthUsage usage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildStatRow(
            context,
            icon: Icons.download_rounded,
            label: 'Active Downloads',
            value: '${usage.activeDownloads}',
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            context,
            icon: Icons.speed,
            label: 'Per Download',
            value: _formatBytesPerSecond(usage.perDownloadBytesPerSecond),
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            context,
            icon: Icons.access_time,
            label: 'Session Time',
            value: _formatDuration(usage.sessionDuration),
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            context,
            icon: Icons.trending_up,
            label: 'Avg Speed',
            value: usage.averageSpeedDisplay,
          ),
          if (usage.isThrottled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Throttling active - downloads may be slowed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
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
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _formatBytesPerSecond(double bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
