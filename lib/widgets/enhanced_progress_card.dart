import 'package:flutter/material.dart';
import '../models/download_progress_info.dart';
import '../utils/file_utils.dart';

/// Enhanced progress display for a single download
///
/// Shows speed, ETA, and detailed file progress in a compact mobile layout.
/// Expandable to show more details.
class EnhancedProgressCard extends StatelessWidget {
  final DownloadProgressInfo progressInfo;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const EnhancedProgressCard({
    super.key,
    required this.progressInfo,
    this.isExpanded = false,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompactInfo(context),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          _buildDetailedInfo(context),
        ],
      ],
    );
  }

  /// Build compact info row (always visible)
  Widget _buildCompactInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        // Speed indicator
        if (progressInfo.hasSpeedData) ...[
          Icon(
            progressInfo.isThrottled ? Icons.speed : Icons.bolt,
            size: 16,
            color: progressInfo.isThrottled
                ? colorScheme.error
                : colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            progressInfo.formattedCurrentSpeed,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
        ],

        // ETA
        if (progressInfo.hasEta) ...[
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            progressInfo.formattedEta,
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
        ],

        // File count
        Icon(
          Icons.insert_drive_file_outlined,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          progressInfo.formattedFileProgress,
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),

        const Spacer(),

        // Expand/collapse button
        if (onToggleExpanded != null)
          IconButton(
            icon: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onToggleExpanded,
          ),
      ],
    );
  }

  /// Build detailed info section (shown when expanded)
  Widget _buildDetailedInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            context,
            icon: Icons.speed,
            label: 'Current Speed',
            value: progressInfo.formattedCurrentSpeed,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            context,
            icon: Icons.show_chart,
            label: 'Average Speed',
            value: progressInfo.formattedAverageSpeed,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            context,
            icon: Icons.access_time,
            label: 'Elapsed',
            value: progressInfo.formattedElapsed,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            context,
            icon: Icons.data_usage,
            label: 'Downloaded',
            value:
                '${FileUtils.formatSize(progressInfo.bytesDownloaded)} / ${FileUtils.formatSize(progressInfo.totalBytes)}',
          ),
          if (progressInfo.isThrottled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  'Bandwidth throttling active',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.error,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build a detail row with icon, label, and value
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
