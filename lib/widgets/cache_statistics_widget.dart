import 'package:flutter/material.dart';
import '../services/metadata_cache.dart';

/// Widget displaying cache statistics and management controls
///
/// Shows cache health metrics:
/// - Total cached archives
/// - Cache size (data + database)
/// - Pinned vs unpinned archives
///
/// Provides cache management actions:
/// - Clear all cache
/// - Purge stale entries
class CacheStatisticsWidget extends StatelessWidget {
  final CacheStats stats;
  final VoidCallback? onClearCache;
  final VoidCallback? onPurgeStale;

  const CacheStatisticsWidget({
    super.key,
    required this.stats,
    this.onClearCache,
    this.onPurgeStale,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildStatsGrid(context),
            const SizedBox(height: 16),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.storage, size: 20),
        const SizedBox(width: 8),
        const Text(
          'Cache Statistics',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        _buildHealthIndicator(),
      ],
    );
  }

  Widget _buildHealthIndicator() {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        // Simple health indicator based on cache size
        final isHealthy = stats.totalArchives < 100; // Arbitrary threshold
        final color = isHealthy ? colorScheme.tertiary : colorScheme.error;
        final icon = isHealthy ? Icons.check_circle : Icons.warning;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                isHealthy ? 'Healthy' : 'Check',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.folder,
                label: 'Cached',
                value: '${stats.totalArchives}',
                subtitle: '${stats.pinnedArchives} pinned',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.data_usage,
                label: 'Data Size',
                value: stats.formattedDataSize,
                subtitle: '${stats.formattedDbSize} DB',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPurgeStale,
            icon: const Icon(Icons.cleaning_services, size: 16),
            label: const Text('Purge Stale'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Builder(
            builder: (context) {
              final colorScheme = Theme.of(context).colorScheme;
              return OutlinedButton.icon(
                onPressed: onClearCache,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Clear All'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Compact cache status badge
class CacheStatusBadge extends StatelessWidget {
  final CacheStats stats;

  const CacheStatusBadge({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storage, size: 12, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            '${stats.totalArchives} cached',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
